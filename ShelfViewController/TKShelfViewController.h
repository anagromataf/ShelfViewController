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

@end
