//
//  TKAppDelegate.m
//  ShelfViewController
//
//  Created by Tobias Kräntzer on 30.10.12.
//  Copyright (c) 2012 Tobias Kräntzer. All rights reserved.
//

#import "TKShelfViewController.h"

#import "TKAppDelegate.h"

@interface TableViewController : UITableViewController
@end
@implementation TableViewController
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section; {return 3;}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath;{return [[UITableViewCell alloc] init];}
@end



@implementation TKAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    
    TKShelfViewController *shelf = [[TKShelfViewController alloc] init];
    
    for (int i = 0; i < 5; i++) {
        TableViewController *viewController = [[TableViewController alloc] initWithStyle:UITableViewStyleGrouped];
        [shelf addSubViewController:viewController];
    }
    
    self.window.rootViewController = shelf;
    [self.window makeKeyAndVisible];
    return YES;
}

@end
