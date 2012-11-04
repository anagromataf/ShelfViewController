//
//  UIView+TKShelfViewController.m
//  ShelfViewController
//
//  Created by Tobias Kräntzer on 02.11.12.
//  Copyright (c) 2012 Tobias Kräntzer. All rights reserved.
//

#import "UIView+TKShelfViewController.h"

@implementation UIView (TKShelfViewController)

+ (void)animateWithDuration:(NSTimeInterval)duration
                 animations:(void (^)(void))animations
              skipAnimation:(BOOL)skipAnimation;
{
    if (skipAnimation) {
        animations();
    } else {
        [self animateWithDuration:duration animations:animations];
    }
}

@end
