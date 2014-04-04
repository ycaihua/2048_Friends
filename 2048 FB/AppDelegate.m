//
//  AppDelegate.m
//  2048 FB
//
//  Created by Shuyang Sun on 3/31/14.
//  Copyright (c) 2014 Shuyang Sun. All rights reserved.
//

#import "AppDelegate.h"
#import <FacebookSDK/FacebookSDK.h>

#import "Theme.h"

NSString *const kUserDefaultKeyAppFirstTimeLaunch  = @"UserDefault_ApplicationFirstTimeLaunch";
NSString *const kCurrentThemeUUIDKey = @"UserDefault_CurrentThemeUUIDKey";

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.
	[FBLoginView class];
	[UIApplication sharedApplication].statusBarHidden = YES;
	// Set the theme:
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	NSUbiquitousKeyValueStore *ubiquitousStore = [NSUbiquitousKeyValueStore defaultStore];
	NSString *themeUUID = kThemeUUID_Default;
	themeUUID = ([userDefaults objectForKey:kCurrentThemeUUIDKey] ? [userDefaults objectForKey:kCurrentThemeUUIDKey]:themeUUID);
	themeUUID = ([ubiquitousStore objectForKey:kCurrentThemeUUIDKey] ? [ubiquitousStore objectForKey:kCurrentThemeUUIDKey]:themeUUID);
	[userDefaults setObject:themeUUID forKey: kCurrentThemeUUIDKey];
	[userDefaults synchronize];
	[ubiquitousStore setObject:themeUUID forKey:kCurrentThemeUUIDKey];
	[ubiquitousStore synchronize];
    return YES;
}
							
- (void)applicationWillResignActive:(UIApplication *)application
{
	// Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
	// Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
	// Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
	// If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
	// Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
	// Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
	// Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
	// After the app gets terminate once, set the "First time launching app" to NO.
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	[userDefaults setObject:@(NO) forKey:kUserDefaultKeyAppFirstTimeLaunch];
	[userDefaults synchronize];
}

@end
