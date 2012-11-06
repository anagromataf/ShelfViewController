//
//  TKShelfViewControllerDelegate.h
//  ShelfViewController
//
//  Created by Tobias Kräntzer on 05.11.12.
//  Copyright (c) 2012 Tobias Kräntzer. All rights reserved.
//

#import <UIKit/UIKit.h>

@class TKShelfViewController;

@protocol TKShelfViewControllerDelegate <NSObject>

#pragma mark TKShelfViewControllerDelegate

- (NSUInteger)numberOfViewControllerInShelfController:(TKShelfViewController *)shelfController;
- (UIViewController *)shelfController:(TKShelfViewController *)shelfController viewControllerAtIndex:(NSUInteger)index;

@optional

- (void)shelfController:(TKShelfViewController *)shelfController willSelectViewController:(UIViewController *)viewController atIndex:(NSUInteger)index;
- (void)shelfController:(TKShelfViewController *)shelfController didSelectViewController:(UIViewController *)viewController atIndex:(NSUInteger)index;

- (void)shelfControllerWillPresentShelf:(TKShelfViewController *)shelfController;
- (void)shelfControllerDidPresentShelf:(TKShelfViewController *)shelfController;

- (BOOL)shelfController:(TKShelfViewController *)shelfController shouldAddViewControllerAtIndex:(NSUInteger)index;
- (void)shelfController:(TKShelfViewController *)shelfController didAddViewController:(UIViewController *)viewController atIndex:(NSUInteger)index;

- (BOOL)shelfController:(TKShelfViewController *)shelfController shouldRemoveViewController:(UIViewController *)viewController atIndex:(NSUInteger)index;
- (void)shelfController:(TKShelfViewController *)shelfController didRemoveViewController:(UIViewController *)viewController atIndex:(NSUInteger)index;

@end
