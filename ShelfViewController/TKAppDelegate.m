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
    
    self.window.rootViewController = shelf;
    [self.window makeKeyAndVisible];
    return YES;
}

#pragma mark TKShelfViewControllerDelegate

- (NSUInteger)numberOfViewControllerInShelfController:(TKShelfViewController *)shelfController;
{
    return 1;
}

- (UIViewController *)shelfController:(TKShelfViewController *)shelfController viewControllerAtIndex:(NSUInteger)index;
{
    return [[TableViewController alloc] initWithStyle:UITableViewStyleGrouped];
}

- (void)shelfController:(TKShelfViewController *)shelfController willSelectViewController:(UIViewController *)viewController atIndex:(NSUInteger)index;
{
    NSLog(@"%s %@ %d", __FUNCTION__, viewController, index);
}

- (void)shelfController:(TKShelfViewController *)shelfController didSelectViewController:(UIViewController *)viewController atIndex:(NSUInteger)index;
{
    NSLog(@"%s %@ %d", __FUNCTION__, viewController, index);
}

- (void)shelfControllerWillPresentShelf:(TKShelfViewController *)shelfController;
{
    NSLog(@"%s", __FUNCTION__);
}

- (void)shelfControllerDidPresentShelf:(TKShelfViewController *)shelfController;
{
    NSLog(@"%s", __FUNCTION__);
}

- (BOOL)shelfController:(TKShelfViewController *)shelfController canAddViewControllerAtIndex:(NSUInteger)index;
{
    NSLog(@"%s %d", __FUNCTION__, index);
    return YES;
}

- (void)shelfController:(TKShelfViewController *)shelfController didAddViewController:(UIViewController *)viewController atIndex:(NSUInteger)index;
{
    NSLog(@"%s %@ %d", __FUNCTION__, viewController, index);
}

- (BOOL)shelfController:(TKShelfViewController *)shelfController canRemoveViewController:(UIViewController *)viewController atIndex:(NSUInteger)index;
{
    NSLog(@"%s %@ %d", __FUNCTION__, viewController, index);
    return YES;
}

- (void)shelfController:(TKShelfViewController *)shelfController didRemoveViewController:(UIViewController *)viewController atIndex:(NSUInteger)index;
{
    NSLog(@"%s %@ %d", __FUNCTION__, viewController, index);
}

@end
