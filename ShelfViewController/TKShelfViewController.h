//
//  TKShelfViewController.h
//  ShelfViewController
//
//  Created by Tobias Kräntzer on 30.10.12.
//  Copyright (c) 2012 Tobias Kräntzer. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "TKShelfViewControllerDelegate.h"

@interface TKShelfViewController : UIViewController

@property (nonatomic, weak) id<TKShelfViewControllerDelegate> delegate;

#pragma mark ViewController Containment

@property (nonatomic, readonly) NSArray *viewControllers;

- (void)addViewController:(UIViewController *)aViewController;
- (void)addViewController:(UIViewController *)aViewController animated:(BOOL)animated;

- (void)removeViewController:(UIViewController *)aViewController;
- (void)removeViewController:(UIViewController *)aViewController animated:(BOOL)animated;

@end
