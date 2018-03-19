//
//  AppDelegate.m
//  益家人
//
//  Created by zhi weijian on 16/4/23.
//  Copyright © 2016年 zhi weijian. All rights reserved.
//
#import "Prefix.pch"

#import "AppDelegate.h"
//#import "LogInController.h"
#import "MenuViewController.h"
#import "BLEViewController.h"


@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    if ([[UIApplication sharedApplication] currentUserNotificationSettings].types==UIUserNotificationTypeNone) {
        //注册本地通知
        UIUserNotificationSettings *setings=[UIUserNotificationSettings settingsForTypes:UIUserNotificationTypeBadge|UIUserNotificationTypeSound|UIUserNotificationTypeAlert categories:nil];
        [[UIApplication sharedApplication] registerUserNotificationSettings:setings];
        
    }
    [UIApplication sharedApplication].applicationIconBadgeNumber=0;    
    
    BLEViewController *BleVC=[[BLEViewController alloc]init];
    UINavigationController *Nav=[[UINavigationController alloc]initWithRootViewController:BleVC];
    //抽屉栏
    MenuViewController *MenuVC=[MenuViewController instanceWithLeftViewController:nil centerViewController:Nav];
    //读取本地信息
    NSString *docPath=[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)lastObject];
    NSString *path=[docPath stringByAppendingPathComponent:@"Person.plist"];
    NSMutableArray *Array=[NSKeyedUnarchiver unarchiveObjectWithFile:path];
    if (!Array) {
        Array=[NSMutableArray array];
    }
    //设置传递参数
    [MenuViewController getMenuViewController].menuArray =Array;
    [MenuViewController getMenuViewController].PhoneNumber=@"TempSense";
    Array=nil;
    self.window=[[UIWindow alloc]initWithFrame:[UIScreen mainScreen].bounds];
    self.window.backgroundColor=[UIColor whiteColor];
    self.window.rootViewController=MenuVC;
    [self.window makeKeyAndVisible];
    

    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    [[NSNotificationCenter defaultCenter]postNotificationName:@"APP_background" object:nil userInfo:nil];
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    [[NSNotificationCenter defaultCenter]postNotificationName:@"APP_Enter" object:nil userInfo:nil];
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

//接收本地通知
-(void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification
{
   //判断本地通知
    NSDictionary *userinfor=notification.userInfo;
    if (!userinfor) {
        return;
    }
    NSString *str=[userinfor objectForKey:@"key"];
    if (str) {
        if ([str isEqualToString:@"HighTemp"]) {
            [self popAlertViewWithMessage:notification.alertBody WithNotification:notification];
        }
        else if ([str isEqualToString:@"LowTemp"])
        {
            [self popAlertViewWithMessage:notification.alertBody WithNotification:notification];
        }
        else if ([str isEqualToString:@"batterylow"])
        {
            [self popAlertViewWithMessage:NSLocalizedString(@"batterylow", nil) WithNotification:notification];
        }
        else if ([str isEqualToString:@"phonebatterylow"])
        {
            [self popAlertViewWithMessage:NSLocalizedString(@"phonebatterylow", nil) WithNotification:notification];
        }
        else if ([str isEqualToString:@"ReconnectTimeout"])
        {
            //Log(@"异常");
            
            [[NSNotificationCenter defaultCenter]postNotificationName:@"ReconnectTimeout" object:nil userInfo:nil];
        }
        else
        {
        }
    }
}

-(void)popAlertViewWithMessage:(NSString *)message WithNotification:(UILocalNotification *)notification
{
    //[self.window.rootViewController dismissViewControllerAnimated:YES completion:nil];
    UIAlertController *alertVC=[UIAlertController alertControllerWithTitle:NSLocalizedString(@"tips", nil) message:message preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *ok=[UIAlertAction actionWithTitle:NSLocalizedString(@"ignore", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        
    }];
    UIAlertAction *cancel=[UIAlertAction actionWithTitle:NSLocalizedString(@"Don'tshowagain", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [[UIApplication sharedApplication]cancelLocalNotification:notification];
        
        NSUserDefaults *defaults=[NSUserDefaults standardUserDefaults];
        NSString *key=[notification.userInfo objectForKey:@"key"];
        Log(@"appdelegate key=%@",key);
        if (key) {
            [defaults setObject:@"123" forKey:key];
        }
        [defaults synchronize];
        
    }];
    [alertVC addAction:ok];
    [alertVC addAction:cancel];
    [self.window.rootViewController presentViewController:alertVC animated:YES completion:^{
        
    }];
   
}

#pragma mark - Core Data stack

@synthesize managedObjectContext = _managedObjectContext;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;

- (NSURL *)applicationDocumentsDirectory {
    // The directory the application uses to store the Core Data store file. This code uses a directory named "com.joymed-tech.Coredata" in the application's documents directory.
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

- (NSManagedObjectModel *)managedObjectModel {
    // The managed object model for the application. It is a fatal error for the application not to be able to find and load its model.
    if (_managedObjectModel != nil) {
        return _managedObjectModel;
    }
    //NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"Coredata" withExtension:@"momd"];
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"Coredata" withExtension:@"mom"];

    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return _managedObjectModel;
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
    // The persistent store coordinator for the application. This implementation creates and returns a coordinator, having added the store for the application to it.
    if (_persistentStoreCoordinator != nil) {
        return _persistentStoreCoordinator;
    }
    
    // Create the coordinator and store
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"Coredata.sqlite"];
    NSError *error = nil;
    NSString *failureReason = @"There was an error creating or loading the application's saved data.";
    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error]) {
        // Report any error we got.
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        dict[NSLocalizedDescriptionKey] = @"Failed to initialize the application's saved data";
        dict[NSLocalizedFailureReasonErrorKey] = failureReason;
        dict[NSUnderlyingErrorKey] = error;
        error = [NSError errorWithDomain:@"YOUR_ERROR_DOMAIN" code:9999 userInfo:dict];
        // Replace this with code to handle the error appropriately.
        // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
        //Log(@"Unresolved error %@, %@", error, [error userInfo]);
        //abort();
    }
    
    return _persistentStoreCoordinator;
}


- (NSManagedObjectContext *)managedObjectContext {
    // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.)
    if (_managedObjectContext != nil) {
        return _managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (!coordinator) {
        return nil;
    }
    _managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
    [_managedObjectContext setPersistentStoreCoordinator:coordinator];
    return _managedObjectContext;
}

#pragma mark - Core Data Saving support

- (void)saveContext {
    NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
    if (managedObjectContext != nil) {
        NSError *error = nil;
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
            // Replace this implementation with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            //Log(@"Unresolved error %@, %@", error, [error userInfo]);
            //abort();
        }
    }
}


@end
