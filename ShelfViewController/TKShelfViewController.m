//
//  TKShelfViewController.m
//  ShelfViewController
//
//  Created by Tobias Kräntzer on 30.10.12.
//  Copyright (c) 2012 Tobias Kräntzer. All rights reserved.
//


#import <QuartzCore/QuartzCore.h>

#import "UIView+TKShelfViewController.h"

#import "TKShelfViewControllerDelegate.h"

#import "TKShelfViewController.h"

#define kTKShelfViewControllerPagePadding 20.0
#define kTKShelfViewControllerPageControlHeight 44.0

@interface TKShelfViewController () <UIScrollViewDelegate, UIGestureRecognizerDelegate>
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIPageControl *pageControl;
@property (nonatomic, strong) UIView *placeholderView;

#pragma mark Rotation
@property (nonatomic, assign) BOOL isBeeingRotating;
@property (nonatomic, assign) NSUInteger indexOfPreviousViewController;

#pragma mark ViewController Containment
@property (nonatomic, readwrite) NSMutableOrderedSet *viewControllers;

#pragma mark Shelf Management
@property (nonatomic, readonly) NSUInteger numberOfViewControllers;
@property (nonatomic, readonly) NSUInteger indexOfCurrentViewController;
@property (nonatomic, readonly) UIViewController *currentViewController;
@property (nonatomic, strong) NSMutableDictionary *visibleViewControllers;
- (UIViewController *)visibleViewControllerAtIndex:(NSUInteger)index;
- (void)removeVisibleViewController:(UIViewController *)viewController;
- (void)configureView:(UIView *)subview forIndex:(NSUInteger)index;
- (void)updateShelf;
- (void)showViewControllerForIndex:(NSUInteger)index animated:(BOOL)animated;

#pragma mark Adding View Controller
@property (nonatomic, assign) BOOL canAddViewController;


#pragma mark Removing View Controller
@property (nonatomic, assign) BOOL canRemoveViewController;

#pragma mark Showing & Hiding Shelf

@property (nonatomic, strong) UIPinchGestureRecognizer *pinchGestureRecognizer;
@property (nonatomic, strong) UITapGestureRecognizer *tapGestureRecognizer;
@property (nonatomic, strong) UIPanGestureRecognizer *panGestureRecognizer;

@property (nonatomic, assign, getter=isShelfHidden) BOOL shelfHidden;
@property (nonatomic, assign, getter=isShelfAnimating) BOOL animatingShelf;

- (void)hideShelf:(BOOL)animated;
- (void)showShelf:(BOOL)animated;

- (void)prepareHidingShelf;
- (void)finalizeHidingShelf;
- (void)prepareShowingShelf;
- (void)finalizeShowingShelf;

#pragma mark Paging
- (void)pageControlDidChangeValue:(id)sender;


#pragma mark Handle Gestures
- (void)handlePinchGesture:(UIPinchGestureRecognizer *)pinchGestureRecognizer;
- (void)handleTapGesture:(UITapGestureRecognizer *)tapGestureRecognizer;
- (void)handlePanGesture:(UIPanGestureRecognizer *)panGestureRecognizer;

@end

#pragma mark -

@implementation TKShelfViewController

#pragma mark Life-cycle

@synthesize visibleViewControllers = _visibleViewControllers;
@synthesize placeholderView = _placeholderView;

#pragma mark UIViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.visibleViewControllers = [[NSMutableDictionary alloc] init];
    
    // Create Scroll View
    // ------------------
    
    CGRect scrollViewFrame = CGRectInset(self.view.bounds, -kTKShelfViewControllerPagePadding, 0);
    
    self.scrollView = [[UIScrollView alloc] initWithFrame:scrollViewFrame];
    self.scrollView.clipsToBounds = NO;
    self.scrollView.pagingEnabled = YES;
    self.scrollView.showsHorizontalScrollIndicator = NO;
    self.scrollView.showsVerticalScrollIndicator = NO;
    self.scrollView.alwaysBounceHorizontal = YES;
    self.scrollView.backgroundColor = [UIColor clearColor];
    self.scrollView.delegate = self;
    
    CATransform3D transformation = CATransform3DIdentity;
    transformation.m34 = -1.0/500.0;
    transformation = CATransform3DTranslate(transformation, 0, 0, -200);
    self.scrollView.layer.transform  = transformation;
    
    [self.view addSubview:self.scrollView];
    [self.view addGestureRecognizer:self.scrollView.panGestureRecognizer];
    
    
    // Create Page Control
    // -------------------
    
    CGRect pageControlFrame = CGRectMake(0,
                                         CGRectGetHeight(self.view.bounds) - kTKShelfViewControllerPageControlHeight,
                                         CGRectGetWidth(self.view.bounds),
                                         kTKShelfViewControllerPageControlHeight);
    
    self.pageControl = [[UIPageControl alloc] initWithFrame:pageControlFrame];
    self.pageControl.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin);
    self.pageControl.hidesForSinglePage = NO;
    self.pageControl.defersCurrentPageDisplay = YES;
    self.pageControl.backgroundColor = [UIColor colorWithWhite:0.5 alpha:0.5];
    
    [self.pageControl addTarget:self action:@selector(pageControlDidChangeValue:) forControlEvents:UIControlEventValueChanged];
    
    [self.view addSubview:self.pageControl];
    
    
    // Create Gesture Recognizer
    // -------------------------
    
    self.pinchGestureRecognizer = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(handlePinchGesture:)];
    [self.view addGestureRecognizer:self.pinchGestureRecognizer];
    
    self.tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapGesture:)];
    [self.view addGestureRecognizer:self.tapGestureRecognizer];
    
    self.panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePanGesture:)];
    self.panGestureRecognizer.delegate = self;
    [self.view addGestureRecognizer:self.panGestureRecognizer];
    
    
    // Placeholder View
    // ----------------
    
    self.placeholderView = [[UIView alloc] initWithFrame:CGRectZero];
    self.placeholderView.backgroundColor = [UIColor clearColor];
    self.placeholderView.layer.borderColor = [[UIColor grayColor] CGColor];
    self.placeholderView.layer.borderWidth = 3.0;
    self.placeholderView.hidden = YES;
    [self.scrollView addSubview:self.placeholderView];
    
    
    // Update the Shelf
    // ----------------
    
    [self updateShelf];
}

- (void)viewDidAppear:(BOOL)animated;
{
    self.scrollView.frame = CGRectInset(self.view.bounds, -kTKShelfViewControllerPagePadding, 0);
    
    [self.visibleViewControllers enumerateKeysAndObjectsUsingBlock:^(NSNumber *indexObj, UIViewController *viewController, BOOL *stop) {
        if (viewController.view.superview == self.scrollView) {
            NSUInteger index = [indexObj unsignedIntegerValue];
            [self configureView:viewController.view forIndex:index];
        }
    }];
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration;
{
    self.isBeeingRotating = YES;
    self.indexOfPreviousViewController = self.indexOfCurrentViewController;
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration;
{
    NSUInteger currentViewController = self.indexOfCurrentViewController;
    
    CGRect scrollViewFrame = CGRectInset(self.view.bounds, -kTKShelfViewControllerPagePadding, 0);
    self.scrollView.frame = scrollViewFrame;
    
    self.scrollView.contentOffset = CGPointMake(CGRectGetWidth(self.scrollView.bounds) * currentViewController, 0);
    
    [self.visibleViewControllers enumerateKeysAndObjectsUsingBlock:^(NSNumber *indexObj, UIViewController *viewController, BOOL *stop) {
        if (viewController.view.superview == self.scrollView) {
            NSUInteger index = [indexObj unsignedIntegerValue];
            [self configureView:viewController.view forIndex:index];
        }
    }];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation;
{
    self.isBeeingRotating = NO;
    self.scrollView.contentOffset = CGPointMake(CGRectGetWidth(self.scrollView.bounds) * self.indexOfPreviousViewController, 0);
    [self updateShelf];
}

#pragma mark Shelf Management

- (NSUInteger)numberOfViewControllers;
{
    return [self.viewControllers count];
}

- (NSUInteger)indexOfCurrentViewController;
{
    return floor(CGRectGetMinX(self.scrollView.bounds) / CGRectGetWidth(self.scrollView.bounds));
}

- (UIViewController *)currentViewController;
{
    NSUInteger index = self.indexOfCurrentViewController;
    return [self.visibleViewControllers objectForKey:[NSNumber numberWithUnsignedInteger:index]];
}

- (UIViewController *)visibleViewControllerAtIndex:(NSUInteger)index;
{
    UIViewController *viewController = [self.visibleViewControllers objectForKey:[NSNumber numberWithUnsignedInteger:index]];
    if (!viewController) {
        viewController = [self.viewControllers objectAtIndex:index];
        
        [viewController willMoveToParentViewController:self];
        [self addChildViewController:viewController];
        [viewController didMoveToParentViewController:self];
        
        [self.visibleViewControllers setObject:viewController forKey:[NSNumber numberWithUnsignedInteger:index]];
        
        [viewController beginAppearanceTransition:YES animated:NO];
        
        [self.scrollView addSubview:viewController.view];
        [self configureView:viewController.view forIndex:index];
        
        [viewController.view setUserInteractionEnabled:self.shelfHidden];
        
        [viewController endAppearanceTransition];
    }
    return viewController;
}

- (void)removeVisibleViewController:(UIViewController *)viewController;
{
    [viewController beginAppearanceTransition:NO animated:NO];
    [viewController.view removeFromSuperview];
    [viewController endAppearanceTransition];
    
    [viewController willMoveToParentViewController:nil];
    [viewController removeFromParentViewController];
    [viewController didMoveToParentViewController:nil];
}

- (void)configureView:(UIView *)subview forIndex:(NSUInteger)index;
{
    CGRect frame = self.scrollView.bounds;
    frame.origin.x = index * CGRectGetWidth(self.scrollView.bounds);
    subview.frame = CGRectInset(frame, kTKShelfViewControllerPagePadding, 0);
}

- (void)updateShelf;
{
    if (self.scrollView == nil) {
        return;
    }
    
    if (self.isBeeingRotating == YES) {
        return;
    }
    
    CGRect scrollViewBounds = self.scrollView.bounds;
    CGRect convertedViewBounds = [self.scrollView convertRect:self.view.bounds fromView:self.view];
    
    self.scrollView.contentSize = CGSizeMake(CGRectGetWidth(scrollViewBounds) * self.numberOfViewControllers,
                                             CGRectGetHeight(scrollViewBounds));
    
    self.pageControl.numberOfPages = self.numberOfViewControllers;
    NSUInteger currentPageIndex = floor(CGRectGetMidX(convertedViewBounds) / CGRectGetWidth(scrollViewBounds));

    self.pageControl.currentPage = MIN(MAX(0, currentPageIndex), self.numberOfViewControllers);
    
    int indexOfFirstNeededViewController = floor((CGRectGetMinX(convertedViewBounds)) / CGRectGetWidth(scrollViewBounds));
    int indexOfLastNeededViewController = floor((CGRectGetMaxX(convertedViewBounds)) / CGRectGetWidth(scrollViewBounds));
    
    
    // Remove not needed view controllers
    // ----------------------------------
    
    NSMutableArray *removedViewControllers = [[NSMutableArray alloc] init];
    [self.visibleViewControllers enumerateKeysAndObjectsUsingBlock:^(NSNumber *indexObj, UIViewController *viewController, BOOL *stop) {
        NSUInteger index = [indexObj unsignedIntegerValue];
        if (index < indexOfFirstNeededViewController || index > indexOfLastNeededViewController) {
            
            [self removeVisibleViewController:viewController];
            
            [removedViewControllers addObject:[NSNumber numberWithUnsignedInteger:index]];
        }
    }];
    [self.visibleViewControllers removeObjectsForKeys:removedViewControllers];
    
    
    // Add missing view controllers
    // ----------------------------
    
    for (int index = indexOfFirstNeededViewController; index <= indexOfLastNeededViewController; index++) {
        
        if (index < 0 || index >= self.numberOfViewControllers) {
            continue;
        }
        
        [self visibleViewControllerAtIndex:index];
    }
    
    
    // Additional ViewController
    // -------------------------
    
    if (indexOfLastNeededViewController == self.numberOfViewControllers && self.canAddViewController) {
        
        CGFloat offset = (CGRectGetMaxX(convertedViewBounds) / CGRectGetWidth(scrollViewBounds)) - indexOfLastNeededViewController;
        
        if (offset > 0.2) {
            self.placeholderView.hidden = NO;
            self.placeholderView.alpha = (offset - 0.2) * 4.0;
            [self configureView:self.placeholderView forIndex:indexOfLastNeededViewController];
        } else {
            self.placeholderView.hidden = YES;
        }
    }
}

- (void)showViewControllerForIndex:(NSUInteger)index animated:(BOOL)animated;
{
    [self.scrollView setContentOffset:CGPointMake(CGRectGetWidth(self.scrollView.bounds) * index, 0) animated:animated];
}

#pragma mark Add View Controller

- (void)addViewController:(UIViewController *)viewController animated:(BOOL)animated;
{
    if (self.viewControllers == nil) {
        self.viewControllers = [NSMutableOrderedSet orderedSetWithObject:viewController];
    } else {
        [self.viewControllers addObject:viewController];
    }
    [self updateShelf];
}

#pragma mark Remove View Controller

- (void)removeViewController:(UIViewController *)viewController animated:(BOOL)animated;
{
    [self removeVisibleViewController:viewController];
    [self.viewControllers removeObject:viewController];
    [self updateShelf];
}

#pragma mark Hiding Shelf

- (void)prepareHidingShelf;
{
    UIViewController *viewController = self.currentViewController;
    NSUInteger index = self.indexOfCurrentViewController;
    
    if ([self.delegate respondsToSelector:@selector(shelfController:willSelectViewController:atIndex:)]) {
        [self.delegate shelfController:self willSelectViewController:viewController atIndex:index];
    }
    
    self.panGestureRecognizer.enabled = NO;
    self.scrollView.scrollEnabled = NO;
    self.pageControl.enabled = NO;
    
    [viewController.view removeFromSuperview];
    [self.view insertSubview:viewController.view belowSubview:self.pageControl];
    
    viewController.view.layer.transform = self.scrollView.layer.transform;
    viewController.view.frame = self.view.bounds;
    
    self.animatingShelf = YES;
}

- (void)hideShelf:(BOOL)animated;
{
    if (self.isShelfAnimating || self.isShelfHidden) {
        return;
    }
    
    UIViewController *viewController = self.currentViewController;
    
    [self prepareHidingShelf];
    [UIView animateWithDuration:0.2
                     animations:^{
                         viewController.view.layer.transform = CATransform3DIdentity;
                         self.pageControl.alpha = 0;
                         [self.visibleViewControllers enumerateKeysAndObjectsUsingBlock:^(NSNumber *indexObj, UIViewController *viewController, BOOL *stop) {
                             if (viewController.view.superview == self.scrollView) {
                                 viewController.view.alpha = 0;
                             }
                         }];
                     }
                     completion:^(BOOL completed) {
                         [self finalizeHidingShelf];
                     }
                 skipAnimations:!animated];
}

- (void)finalizeHidingShelf;
{
    UIViewController *viewController = self.currentViewController;
    NSUInteger index = self.indexOfCurrentViewController;
    
    self.pageControl.hidden = YES;
    
    [viewController.view setUserInteractionEnabled:YES];
    
    self.animatingShelf = NO;
    self.shelfHidden = YES;
    
    if ([self.delegate respondsToSelector:@selector(shelfController:didSelectViewController:atIndex:)]) {
        [self.delegate shelfController:self didSelectViewController:viewController atIndex:index];
    }
}

#pragma mark Showing Shelf

- (void)prepareShowingShelf;
{
    if ([self.delegate respondsToSelector:@selector(shelfControllerWillPresentShelf:)]) {
        [self.delegate shelfControllerWillPresentShelf:self];
    }
    
    UIViewController *viewController = self.currentViewController;
    [viewController.view setUserInteractionEnabled:NO];
    
    self.pageControl.hidden = NO;
    self.animatingShelf = YES;
}

- (void)showShelf:(BOOL)animated;
{
    if (self.isShelfAnimating || !self.isShelfHidden) {
        return;
    }
    
    UIViewController *viewController = self.currentViewController;
    viewController.view.layer.transform = CATransform3DIdentity;
    [self prepareShowingShelf];
    [UIView animateWithDuration:0.2
                     animations:^{
                         self.pageControl.alpha = 1;
                         viewController.view.layer.transform = self.scrollView.layer.transform;
                         [self.visibleViewControllers enumerateKeysAndObjectsUsingBlock:^(NSNumber *indexObj, UIViewController *viewController, BOOL *stop) {
                             if (viewController.view.superview == self.scrollView) {
                                 viewController.view.alpha = 1;
                             }
                         }];
                     }
                     completion:^(BOOL completed) {
                         [self finalizeShowingShelf];
                     }
                 skipAnimations:!animated];
}

- (void)finalizeShowingShelf;
{
    UIViewController *viewController = self.currentViewController;
    [viewController.view removeFromSuperview];
    viewController.view.layer.transform = CATransform3DIdentity;
    [self.scrollView addSubview:viewController.view];
    [self configureView:viewController.view forIndex:self.indexOfCurrentViewController];
    
    self.pageControl.enabled = YES;
    self.scrollView.scrollEnabled = YES;
    self.panGestureRecognizer.enabled = YES;
    self.animatingShelf = NO;
    self.shelfHidden = NO;
    
    if ([self.delegate respondsToSelector:@selector(shelfControllerDidPresentShelf:)]) {
        [self.delegate shelfControllerDidPresentShelf:self];
    }
}

#pragma mark Paging

- (void)pageControlDidChangeValue:(id)sender;
{
    if (self.pageControl == sender) {
        [self showViewControllerForIndex:self.pageControl.currentPage animated:YES];
    }
}

#pragma mark Handle Gestures

- (void)handlePinchGesture:(UIPinchGestureRecognizer *)pinchGestureRecognizer;
{
    switch (pinchGestureRecognizer.state) {
        case UIGestureRecognizerStateBegan:
            if (self.shelfHidden) {
                if (pinchGestureRecognizer.scale >= 1) {
                    pinchGestureRecognizer.enabled = NO;
                    pinchGestureRecognizer.enabled = YES;
                } else {
                    [self showShelf:YES];
                }
            } else {
                if (pinchGestureRecognizer.scale > 1) {
                    [self hideShelf:YES];
                }
            }
            break;

        default:
            break;
    }
}

- (void)handleTapGesture:(UITapGestureRecognizer *)tapGestureRecognizer;
{
    [self hideShelf:YES];
}

- (void)handlePanGesture:(UIPanGestureRecognizer *)panGestureRecognizer;
{
    UIViewController *viewController = self.currentViewController;
    NSUInteger index = self.indexOfCurrentViewController;
    CGRect frame = viewController.view.frame;
    
    CGPoint translation = [panGestureRecognizer translationInView:viewController.view];
    
    switch (panGestureRecognizer.state) {
        case UIGestureRecognizerStateBegan:
            if ([self.delegate respondsToSelector:@selector(shelfController:canRemoveViewController:atIndex:)]) {
                self.canRemoveViewController = [self.delegate shelfController:self canRemoveViewController:viewController atIndex:index];
            }
            break;
            
        case UIGestureRecognizerStateChanged:
        {
            if (self.canRemoveViewController && translation.y > 2) {
                self.scrollView.scrollEnabled = NO;
                [self configureView:viewController.view forIndex:index];
                frame.origin.y = translation.y;
                viewController.view.frame = frame;
            }
            break;
        }
        
        case UIGestureRecognizerStateEnded:
        {
            if (self.canRemoveViewController && translation.y > CGRectGetHeight(frame) / 2) {
                NSLog(@"Remove ...");
            }
        }
        
        case UIGestureRecognizerStateCancelled:
        case UIGestureRecognizerStateFailed:
        {
            [UIView animateWithDuration:0.2 animations:^{
                [self configureView:viewController.view forIndex:index];
            } completion:^(BOOL finished) {
                self.scrollView.scrollEnabled = YES;
            }];
            break;
        }
        
        default:
            break;
    }
}

#pragma mark UIGestureRecognizerDelegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer;
{
    if (gestureRecognizer == self.panGestureRecognizer && otherGestureRecognizer == self.scrollView.panGestureRecognizer) {
        return YES;
    }
    
    return NO;
}

#pragma mark UIScrollViewDelegate

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView;
{
    self.panGestureRecognizer.enabled = NO;
    
    if ([self.delegate respondsToSelector:@selector(viewControllerToInsertAtIndex:toShelfController:)]) {
        if ([self.delegate respondsToSelector:@selector(shelfController:canInsertViewControllerAtIndex:)]) {
            self.canAddViewController = [self.delegate shelfController:self canInsertViewControllerAtIndex:self.numberOfViewControllers];
        } else {
            self.canAddViewController = YES;
        }
    }
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView;
{
    [self updateShelf];
}

- (void)scrollViewWillBeginDecelerating:(UIScrollView *)scrollView;
{
    self.placeholderView.hidden = YES;
    
    if (self.canAddViewController) {
        CGRect scrollViewBounds = self.scrollView.bounds;
        CGRect convertedViewBounds = [self.scrollView convertRect:self.view.bounds fromView:self.view];
        
        int lastNeededPageIndex = floor((CGRectGetMaxX(convertedViewBounds)) / CGRectGetWidth(scrollViewBounds));
        
        NSUInteger index = self.numberOfViewControllers;
        
        if (lastNeededPageIndex == index) {
            
            CGFloat offset = (CGRectGetMaxX(convertedViewBounds) / CGRectGetWidth(scrollViewBounds)) - lastNeededPageIndex;
            if (offset > 0.4) {
                UIViewController *viewController = [self.delegate viewControllerToInsertAtIndex:index toShelfController:self];
                [self.viewControllers addObject:viewController];
                if ([self.delegate respondsToSelector:@selector(shelfController:didInsertViewController:atIndex:)]) {
                    [self.delegate shelfController:self didInsertViewController:viewController atIndex:index];
                }
                [self updateShelf];
                [self showViewControllerForIndex:index animated:YES];
            }
        }
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView;
{
    self.canAddViewController = NO;
    self.panGestureRecognizer.enabled = YES;
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView;
{
    
}

@end
