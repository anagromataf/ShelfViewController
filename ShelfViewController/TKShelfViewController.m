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

@interface TKShelfViewController () <UIScrollViewDelegate>
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIPageControl *pageControl;

#pragma mark Shelf Management
@property (nonatomic, assign) NSUInteger numberOfViewControllers;
@property (nonatomic, readonly) NSUInteger indexOfCurrentViewController;
@property (nonatomic, readonly) UIViewController *currentViewController;
@property (nonatomic, readonly) NSMutableDictionary *visibleViewControllers;
- (void)updateShelf;
- (void)configureView:(UIView *)subview forIndex:(NSUInteger)index;

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
- (void)showViewControllerForIndex:(NSUInteger)index animated:(BOOL)animated;

#pragma mark Handle Gestures
- (void)handlePinchGesture:(UIPinchGestureRecognizer *)pinchGestureRecognizer;
- (void)handleTapGesture:(UITapGestureRecognizer *)tapGestureRecognizer;

@end

#pragma mark -

@implementation TKShelfViewController

#pragma mark Life-cycle

@synthesize visibleViewControllers = _visibleViewControllers;

#pragma mark Simple Accessors

- (NSMutableDictionary *)visibleViewControllers;
{
    if (_visibleViewControllers == nil) {
        _visibleViewControllers = [[NSMutableDictionary alloc] init];
    }
    return _visibleViewControllers;
}

#pragma mark UIViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
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
    
    
    // Get number of ViewControllers
    // -----------------------------
    
    self.numberOfViewControllers = [self.delegate numberOfViewControllerInShelfController:self];
    
    
    // Update the Shelf
    // ----------------
    
    [self updateShelf];
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration;
{
    NSUInteger currentViewController = self.indexOfCurrentViewController;
    
    [UIView animateWithDuration:duration animations:^{
        CGRect scrollViewFrame = CGRectInset(self.view.bounds, -kTKShelfViewControllerPagePadding, 0);
        self.scrollView.frame = scrollViewFrame;
    }];
    
    self.scrollView.contentOffset = CGPointMake(CGRectGetWidth(self.scrollView.bounds) * currentViewController, 0);
    
    [self.visibleViewControllers enumerateKeysAndObjectsUsingBlock:^(NSNumber *indexObj, UIViewController *viewController, BOOL *stop) {
        NSUInteger index = [indexObj unsignedIntegerValue];
        [self configureView:viewController.view forIndex:index];
    }];
}

#pragma mark Shelf Management

- (NSUInteger)indexOfCurrentViewController;
{
    CGRect scrollViewBounds = self.scrollView.bounds;
    CGRect convertedViewBounds = [self.scrollView convertRect:self.view.bounds fromView:self.view];
    return floor(CGRectGetMidX(convertedViewBounds) / CGRectGetWidth(scrollViewBounds));
}

- (UIViewController *)currentViewController;
{
    NSUInteger index = self.indexOfCurrentViewController;
    return [self.visibleViewControllers objectForKey:[NSNumber numberWithUnsignedInteger:index]];
}

- (void)updateShelf;
{
    if (self.scrollView == nil) {
        return;
    }
    
    CGRect scrollViewBounds = self.scrollView.bounds;
    CGRect convertedViewBounds = [self.scrollView convertRect:self.view.bounds fromView:self.view];
    
    self.scrollView.contentSize = CGSizeMake(CGRectGetWidth(scrollViewBounds) * self.numberOfViewControllers,
                                             CGRectGetHeight(scrollViewBounds));
    
    self.pageControl.numberOfPages = self.numberOfViewControllers;
    int currentPageIndex = floor(CGRectGetMidX(convertedViewBounds) / CGRectGetWidth(scrollViewBounds));
    self.pageControl.currentPage = MIN(MAX(0, currentPageIndex), self.numberOfViewControllers);
    
    int indexOfFirstNeededViewController = floor((CGRectGetMinX(convertedViewBounds)) / CGRectGetWidth(scrollViewBounds));
    int indexOfLastNeededViewController = floor((CGRectGetMaxX(convertedViewBounds)) / CGRectGetWidth(scrollViewBounds));
    
    
    // Remove not needed view controllers
    // ----------------------------------
    
    NSMutableArray *removedViewControllers = [[NSMutableArray alloc] init];
    [self.visibleViewControllers enumerateKeysAndObjectsUsingBlock:^(NSNumber *indexObj, UIViewController *viewController, BOOL *stop) {
        NSUInteger index = [indexObj unsignedIntegerValue];
        if (index < indexOfFirstNeededViewController || index > indexOfLastNeededViewController) {
            
            [viewController beginAppearanceTransition:NO animated:NO];
            [viewController.view removeFromSuperview];
            [viewController endAppearanceTransition];
            
            [viewController willMoveToParentViewController:nil];
            [viewController removeFromParentViewController];
            [viewController didMoveToParentViewController:nil];
            
            [removedViewControllers addObject:indexObj];
        }
    }];
    [self.visibleViewControllers removeObjectsForKeys:removedViewControllers];
    
    
    // Add missing view controllers
    // ----------------------------
    
    for (int index = indexOfFirstNeededViewController; index <= indexOfLastNeededViewController; index++) {
        
        if (index < 0 || index >= self.numberOfViewControllers) {
            continue;
        }
        
        UIViewController *viewController = [self.visibleViewControllers objectForKey:[NSNumber numberWithUnsignedInteger:index]];
        if (!viewController) {
            viewController = [self.delegate shelfController:self viewControllerAtIndex:index];
            NSAssert(viewController, @"Expecting a view controller at index: %d", index);
            
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
    }
}

- (void)configureView:(UIView *)subview forIndex:(NSUInteger)index;
{
    CGRect frame = self.scrollView.bounds;
    frame.origin.x = index * CGRectGetWidth(self.scrollView.bounds);
    subview.frame = CGRectInset(frame, kTKShelfViewControllerPagePadding, 0);
}

#pragma mark Hiding Shelf

- (void)prepareHidingShelf;
{
    UIViewController *viewController = self.currentViewController;
    NSUInteger index = self.indexOfCurrentViewController;
    
    if ([self.delegate respondsToSelector:@selector(shelfController:willSelectViewController:atIndex:)]) {
        [self.delegate shelfController:self willSelectViewController:viewController atIndex:index];
    }
    
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

- (void)showViewControllerForIndex:(NSUInteger)index animated:(BOOL)animated;
{
    [self.scrollView setContentOffset:CGPointMake(CGRectGetWidth(self.scrollView.bounds) * index, 0) animated:animated];
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

#pragma mark UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView;
{
    [self updateShelf];
}

@end
