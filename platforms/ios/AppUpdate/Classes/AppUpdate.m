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
    NSLog(@" - %@", resourcepath);
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


/*===================
 * ApUpdate
 =====================*/

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
        [self copyFromBundleToDocuments:@"www"];
        NSURL *url = [NSURL URLWithString:urlString];
        [self downloadArchiveFromUrl:url];
    } else {
        CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR
                                                          messageAsString:@"URL argument was null"];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }
}

/*
 - (BOOL)shouldOverrideLoadWithRequest:(NSURLRequest*)request navigationType:(UIWebViewNavigationType)navigationType
 {
 NSURL* url = [request URL];
 NSString* scheme = [url scheme];
 
 // app relative urls don't contain scheme, rewrite only if scheme not specified
 if(!scheme.length == 0) {
 return NO;
 }
 
 NSLog(@"ORIGINAL URL: %@", url);
 NSString* urlString = [self getDocumentsPathFor:[NSString stringWithFormat:@"www/%@", url]];
 NSURL *newUrl = [NSURL fileURLWithPath:urlString];
 NSLog(@"OVERRIDE URL: %@", newUrl);
 
 if(![urlString isEqualToString:[url relativePath]]) {
 [self.webView loadRequest:[NSURLRequest requestWithURL:newUrl]];
 return YES;
 } else {
 return NO;
 }
 }
 */

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

- (BOOL)copyFromBundleToDocuments:(NSString*)folder
{
    NSError *error;
    NSString *destinationPath = [self getDocumentsPathFor:folder];
    
    // if folder already exists, we have already coped www, no need to overwrite it
    if (![[NSFileManager defaultManager] fileExistsAtPath:destinationPath]) {
        //[[NSFileManager defaultManager] createDirectoryAtPath:destinationPath withIntermediateDirectories:NO attributes:nil error:&error];
        
        if (error == nil) {
            //simplified method with more common and helpful method
            NSString *sourcePath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"www"];
            NSFileManager *fileManager = [NSFileManager defaultManager];
            [fileManager copyItemAtPath:sourcePath toPath:destinationPath
                                  error:&error];
            if (error != nil) {
                CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR
                                                                  messageAsString:error.localizedDescription];
                [self.commandDelegate sendPluginResult:pluginResult callbackId:self.latestCommand.callbackId];
            }
            return error == nil;
        } else {
            CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR
                                                              messageAsString:@"Error copying www folder from bundle."];
            [self.commandDelegate sendPluginResult:pluginResult callbackId:self.latestCommand.callbackId];
            
            return NO;
        }
    }
    
    return NO;
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
    
    NSString *filePath = [self getDocumentsPathFor:@"AppUpdate.zip"];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    [self.receivedData writeToFile:filePath atomically:YES];
    
    NSError *error;
    NSString *destinationPath = [self getDocumentsPathFor:@"/www"];
    if (![[NSFileManager defaultManager] fileExistsAtPath:destinationPath])
        [[NSFileManager defaultManager] createDirectoryAtPath:destinationPath withIntermediateDirectories:NO attributes:nil error:&error];
    
    if(error == nil) {
        [self unzipArchive:filePath];
        [self reloadWebView];
        
        CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK
                                                          messageAsString:@"c"];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:self.latestCommand.callbackId];
    } else {
        CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR
                                                          messageAsString:@"Error extracting archive."];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:self.latestCommand.callbackId];
    }
}

- (NSString*)getDocumentsPathFor:(NSString*)path
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    return [documentsDirectory stringByAppendingPathComponent:path];
}

@end
