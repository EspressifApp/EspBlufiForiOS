//
//  AppDelegate.m
//  EspBlufi
//
//  Created by fanbaoying on 2020/6/9.
//  Copyright © 2020 espressif. All rights reserved.
//

#import "AppDelegate.h"
#import "ViewController.h"
#import "ESPDataConversion.h"

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    
    [ESPDataConversion fby_saveNSUserDefaults:@"" withKey:@"filterContent"];
    [[UINavigationBar appearance] setBarTintColor:navColor];
    [[UINavigationBar appearance] setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:
    [UIColor whiteColor], NSForegroundColorAttributeName,
    [UIFont boldSystemFontOfSize:20], NSFontAttributeName, nil]];
    [[UINavigationBar appearance] setTintColor:[UIColor whiteColor]];
    [[UINavigationBar appearance] setHidden:NO];
    if (@available(iOS 13.0, *)) {
            
    } else {
        UINavigationController *navigationController = [[UINavigationController alloc]initWithRootViewController:[ViewController new]];
        self.window.rootViewController = navigationController;
        [self.window makeKeyAndVisible];
    }
    return YES;
}


#pragma mark - UISceneSession lifecycle


- (UISceneConfiguration *)application:(UIApplication *)application configurationForConnectingSceneSession:(UISceneSession *)connectingSceneSession options:(UISceneConnectionOptions *)options  API_AVAILABLE(ios(13.0)){
    // Called when a new scene session is being created.
    // Use this method to select a configuration to create the new scene with.
    return [[UISceneConfiguration alloc] initWithName:@"Default Configuration" sessionRole:connectingSceneSession.role];
}


- (void)application:(UIApplication *)application didDiscardSceneSessions:(NSSet<UISceneSession *> *)sceneSessions  API_AVAILABLE(ios(13.0)){
    // Called when the user discards a scene session.
    // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
    // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
}


@end
