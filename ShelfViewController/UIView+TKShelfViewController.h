//
//  UIView+TKShelfViewController.h
//  ShelfViewController
//
//  Created by Tobias Kräntzer on 02.11.12.
//  Copyright (c) 2012 Tobias Kräntzer. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIView (TKShelfViewController)

+ (void)animateWithDuration:(NSTimeInterval)duration
                 animations:(void (^)(void))animations
              skipAnimation:(BOOL)skipAnimation;

@end
