//
//  TKShelfViewController.h
//  ShelfViewController
//
//  Created by Tobias Kräntzer on 30.10.12.
//  Copyright (c) 2012 Tobias Kräntzer. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TKShelfViewController : UIViewController

#pragma mark ViewController Containment

@property (nonatomic, readonly) NSArray *subViewControllers;

- (void)addSubViewController:(UIViewController *)aViewController;
- (void)removeSubViewController:(UIViewController *)aViewController;

@end
