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
              skipAnimations:(BOOL)skipAnimations;
{
    if (skipAnimations) {
        animations();
    } else {
        [self animateWithDuration:duration animations:animations];
    }
}

+ (void)animateWithDuration:(NSTimeInterval)duration
                 animations:(void (^)(void))animations
                 completion:(void (^)(BOOL))completion
             skipAnimations:(BOOL)skipAnimations;
{
    if (skipAnimations) {
        animations();
        completion(YES);
    } else {
        [self animateWithDuration:duration animations:animations completion:completion];
    }
}

@end
