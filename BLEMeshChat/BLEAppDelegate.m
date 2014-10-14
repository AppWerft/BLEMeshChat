//
//  BLEAppDelegate.m
//  BLEMeshChat
//
//  Created by Christopher Ballinger on 10/10/14.
//  Copyright (c) 2014 Christopher Ballinger. All rights reserved.
//

#import "BLEAppDelegate.h"
#import "BLEBroadcastViewController.h"
#import "BLEScannerViewController.h"
#import "DDTTYLogger.h"
#import "DDASLLogger.h"

@interface BLEAppDelegate ()

@end

@implementation BLEAppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [DDLog addLogger:[DDTTYLogger sharedInstance]];
    [DDLog addLogger:[DDASLLogger sharedInstance]];
    NSArray *centralManagerIdentifiers = launchOptions[UIApplicationLaunchOptionsBluetoothCentralsKey];
    if (centralManagerIdentifiers) {
        DDLogInfo(@"didFinishLaunchingWithOptions with UIApplicationLaunchOptionsBluetoothCentralsKey");
    }
    NSArray *peripheralManagerIdentifiers = launchOptions[UIApplicationLaunchOptionsBluetoothPeripheralsKey];
    if (peripheralManagerIdentifiers) {
        DDLogInfo(@"didFinishLaunchingWithOptions with UIApplicationLaunchOptionsBluetoothPeripheralsKey");
    }
    if (centralManagerIdentifiers || peripheralManagerIdentifiers) {
        NSMutableString *body = [NSMutableString stringWithString:@"Launched with "];
        if (centralManagerIdentifiers) {
            [body appendString:@"central "];
        }
        if (peripheralManagerIdentifiers) {
            [body appendString:@"peripheral "];
        }
        UILocalNotification *localNotification = [[UILocalNotification alloc] init];
        localNotification.alertBody = body;
        [[UIApplication sharedApplication] presentLocalNotificationNow:localNotification];
    }
    
    if ([[UIApplication sharedApplication] respondsToSelector:@selector(registerUserNotificationSettings:)]) {
        UIUserNotificationSettings *notificationSettings = [UIUserNotificationSettings settingsForTypes:UIUserNotificationTypeAlert | UIUserNotificationTypeSound categories:nil];
        [[UIApplication sharedApplication] registerUserNotificationSettings:notificationSettings];
    } else {
        UIRemoteNotificationType myTypes = UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeSound;
        [[UIApplication sharedApplication] registerForRemoteNotificationTypes:myTypes];
    }
    
    
    self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    UITabBarController *tabBarController = [[UITabBarController alloc] init];
    BLEScannerViewController *scannerVC = [[BLEScannerViewController alloc] init];
    UINavigationController *scannerNav = [[UINavigationController alloc] initWithRootViewController:scannerVC];
    scannerNav.tabBarItem.image = [UIImage imageNamed:@"BLEScanIcon"];
    BLEBroadcastViewController *broadcastVC = [[BLEBroadcastViewController alloc] init];
    UINavigationController *broadcastNav = [[UINavigationController alloc] initWithRootViewController:broadcastVC];
    broadcastNav.tabBarItem.image = [UIImage imageNamed:@"BLEBroadcastIcon"];
    tabBarController.viewControllers = @[scannerNav, broadcastNav];
    self.window.rootViewController = tabBarController;
    [self.window makeKeyAndVisible];
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
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
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
