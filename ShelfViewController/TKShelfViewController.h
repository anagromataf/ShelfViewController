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

- (void)addViewController:(UIViewController *)viewController animated:(BOOL)animated;
- (void)removeViewController:(UIViewController *)viewController animated:(BOOL)animated;

@end
