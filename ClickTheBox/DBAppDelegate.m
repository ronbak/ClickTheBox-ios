//
//  DBAppDelegate.m
//  ClickTheBox
//
//  Created by Leah Culver on 2/9/14.
//  Copyright (c) 2014 Dropbox. All rights reserved.
//

#import "DBAppDelegate.h"

#import "DBViewController.h"

@implementation DBAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    DBAccountManager *accountManager = [[DBAccountManager alloc] initWithAppKey:@"8i3v3z06x98zza5" secret:@"7tbby4wvjfdwnwu"];
    [DBAccountManager setSharedManager:accountManager];

    return YES;
}

- (BOOL)application:(UIApplication *)app openURL:(NSURL *)url sourceApplication:(NSString *)source annotation:(id)annotation {
    DBAccount *account = [[DBAccountManager sharedManager] handleOpenURL:url];

    if (account) {
        DBViewController *viewController = (DBViewController *)self.window.rootViewController;
        [viewController userLoggedIn];

        return YES;
    }

    return NO;
}

@end
