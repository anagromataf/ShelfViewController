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
@optional

#pragma mark TKShelfViewControllerDelegate

- (void)shelfController:(TKShelfViewController *)shelfController willSelectViewController:(UIViewController *)viewController atIndex:(NSUInteger)index;
- (void)shelfController:(TKShelfViewController *)shelfController didSelectViewController:(UIViewController *)viewController atIndex:(NSUInteger)index;

- (void)shelfControllerWillPresentShelf:(TKShelfViewController *)shelfController;
- (void)shelfControllerDidPresentShelf:(TKShelfViewController *)shelfController;

- (BOOL)shelfController:(TKShelfViewController *)shelfController canInsertViewControllerAtIndex:(NSUInteger)index;
- (UIViewController *)viewControllerToInsertAtIndex:(NSUInteger)index toShelfController:(TKShelfViewController *)shelfController;
- (void)shelfController:(TKShelfViewController *)shelfController didInsertViewController:(UIViewController *)viewController atIndex:(NSUInteger)index;

- (BOOL)shelfController:(TKShelfViewController *)shelfController canRemoveViewController:(UIViewController *)viewController atIndex:(NSUInteger)index;
- (void)shelfController:(TKShelfViewController *)shelfController didRemoveViewController:(UIViewController *)viewController atIndex:(NSUInteger)index;

@end
