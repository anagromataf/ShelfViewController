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

- (UIViewController *)nextViewControllerForShelf:(TKShelfViewController *)aShelfViewController;

@end
