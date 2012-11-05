//
//  TKAppDelegate.m
//  ShelfViewController
//
//  Created by Tobias Kräntzer on 30.10.12.
//  Copyright (c) 2012 Tobias Kräntzer. All rights reserved.
//

#import "TKShelfViewControllerDelegate.h"
#import "TKShelfViewController.h"

#import "TKAppDelegate.h"

@interface TableViewController : UITableViewController
@end
@implementation TableViewController
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section; {return 3;}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath;{return [[UITableViewCell alloc] init];}
@end

@interface TKAppDelegate () <TKShelfViewControllerDelegate>

@end


@implementation TKAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    
    TKShelfViewController *shelf = [[TKShelfViewController alloc] init];
    shelf.delegate = self;
    for (int i = 0; i < 1; i++) {
        TableViewController *viewController = [[TableViewController alloc] initWithStyle:UITableViewStyleGrouped];
        [shelf addSubViewController:viewController];
    }
    
    self.window.rootViewController = shelf;
    [self.window makeKeyAndVisible];
    return YES;
}

#pragma mark TKShelfViewControllerDelegate

- (UIViewController *)nextViewControllerForShelf:(TKShelfViewController *)aShelfViewController;
{
    return [[TableViewController alloc] initWithStyle:UITableViewStyleGrouped];
}

@end
