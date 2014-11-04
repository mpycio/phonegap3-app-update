//
//  AppUpdate.m
//  AppUpdate
//
//  Created by Marcin Pycio on 03/11/2014.
//
//

#import "AppUpdate.h"
#import <Cordova/CDVCommandDelegateImpl.h>
#import "SSZipArchive.h"


/*===================
 * Override for PhoneGap method loading a resource, we need to look in Documents/www directory first
=====================*/
@implementation CDVCommandDelegateImpl (AppUpdate)

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wobjc-protocol-method-implementation"
- (NSString*)pathForResource:(NSString*)resourcepath
{
    NSArray  *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString* directoryStr = _viewController.wwwFolderName;
    NSMutableArray* directoryParts = [NSMutableArray arrayWithArray:[resourcepath componentsSeparatedByString:@"/"]];
    NSString* filename = [directoryParts lastObject];
    
    NSString *path = [NSString stringWithFormat:@"%@/%@/%@", documentsDirectory, directoryStr, filename];
    
    if(![[NSFileManager defaultManager] fileExistsAtPath:path]) {
        NSBundle* mainBundle = [NSBundle mainBundle];
        [directoryParts removeLastObject];
        NSString* directoryPartsJoined = [directoryParts componentsJoinedByString:@"/"];
        
        if ([directoryPartsJoined length] > 0) {
            directoryStr = [NSString stringWithFormat:@"%@/%@", _viewController.wwwFolderName, [directoryParts componentsJoinedByString:@"/"]];
        }
        
        path = [mainBundle pathForResource:filename ofType:@"" inDirectory:directoryStr];
    }
    
    return path;
}
#pragma clang diagnostic pop

@end




@interface AppUpdate() <NSURLConnectionDataDelegate>

@property(strong) NSMutableData *receivedData;
@property(assign) NSInteger expectedBytes;

@end

@implementation AppUpdate

- (void)update:(CDVInvokedUrlCommand*)command
{
    // Save the CDVInvokedUrlCommand as a property.  We will need it later.
    self.latestCommand = command;
    
    NSString* urlString = [command.arguments objectAtIndex:0];
    
    if (urlString != nil) {
        NSURL *url = [NSURL URLWithString:urlString];
        [self downloadArchiveFromUrl:url];
    } else {
        CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR
                                                          messageAsString:@"URL argument was null"];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }
}

- (BOOL)unzipArchive:(NSString*)archivePath
{
    NSArray  *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *destinationPath = [documentsDirectory stringByAppendingPathComponent:@"/www"];
    
    return [SSZipArchive unzipFileAtPath:archivePath toDestination:destinationPath];
}

- (void)reloadWebView
{
    id<UIApplicationDelegate> delegate = [[UIApplication sharedApplication] delegate];
    CDVViewController *vc = (CDVViewController*)delegate.window.rootViewController;
    //            vc.wwwFolderName = @"AppData/Documents";
    [vc viewDidLoad];
}




-(void)downloadArchiveFromUrl:(NSURL*)url
{
    NSURLRequest *theRequest = [NSURLRequest requestWithURL:url
                                                cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
                                            timeoutInterval:60];
    self.receivedData = [[NSMutableData alloc] initWithLength:0];
    [NSURLConnection connectionWithRequest:theRequest delegate:self];
//    [[NSURLConnection alloc] initWithRequest:theRequest delegate:self startImmediately:YES];
}


- (void) connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    [self.receivedData setLength:0];
    self.expectedBytes = [response expectedContentLength];
}

- (void) connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [self.receivedData appendData:data];
    float progress = (float)[self.receivedData length] / (float)self.expectedBytes;
    NSLog(@"Progress: %f", progress);
    
    CDVPluginResult *progressResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDouble:progress];
    progressResult.keepCallback = [NSNumber numberWithBool:YES];
    [self.commandDelegate sendPluginResult:progressResult callbackId:self.latestCommand.callbackId];
}

- (void) connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR
                                                      messageAsString:@"Error downloading archive."];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:self.latestCommand.callbackId];
}

- (NSCachedURLResponse *) connection:(NSURLConnection *)connection willCacheResponse:(NSCachedURLResponse *)cachedResponse {
    return nil;
}

- (void) connectionDidFinishLoading:(NSURLConnection *)connection
{
    NSLog(@"Succeeded! Received %lu bytes of data",(unsigned long)[self.receivedData length]);
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *filePath = [documentsDirectory stringByAppendingPathComponent:@"AppUpdate.zip"];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    [self.receivedData writeToFile:filePath atomically:YES];
    
    NSError *error;
    NSString *destinationPath = [documentsDirectory stringByAppendingPathComponent:@"/www"];
    if (![[NSFileManager defaultManager] fileExistsAtPath:destinationPath])
        [[NSFileManager defaultManager] createDirectoryAtPath:destinationPath withIntermediateDirectories:NO attributes:nil error:&error];
    
    if(error == nil) {
        [self unzipArchive:filePath];
        [self reloadWebView];
        
        CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK
                                                          messageAsString:@"Update complete"];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:self.latestCommand.callbackId];
    } else {
        CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR
                                                          messageAsString:@"Error extracting archive."];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:self.latestCommand.callbackId];
    }
}

@end
