//
//  AppUpdate.h
//  AppUpdate
//
//  Created by Marcin Pycio on 03/11/2014.
//
//

#import <Cordova/CDV.h>

@interface AppUpdate : CDVPlugin

@property (strong, nonatomic) CDVInvokedUrlCommand* latestCommand;

- (void)update:(CDVInvokedUrlCommand*)command;

@end
