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

#pragma mark ViewController Containment
@property (nonatomic, readwrite) NSArray *viewControllers;

#pragma mark Shelf Management
@property (nonatomic, readonly) NSUInteger numberOfViewControllers;
@property (nonatomic, readonly) NSUInteger indexOfCurrentViewController;
@property (nonatomic, readonly) UIViewController *currentViewController;
@property (nonatomic, readonly) NSMutableSet *visibleViewControllers;
@property (nonatomic, assign) BOOL currentlyAddingViewController;
@property (nonatomic, strong) UIViewController *nextViewController;
- (void)updateShelf;
- (void)configureView:(UIView *)subview forIndex:(NSUInteger)index;

#pragma mark Showing & Hiding Shelf

@property (nonatomic, strong) UIPinchGestureRecognizer *pinchGestureRecognizer;
@property (nonatomic, strong) UITapGestureRecognizer *tapGestureRecognizer;

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
    
    for (UIViewController *viewController in self.visibleViewControllers) {
        if (viewController.view.superview == self.scrollView) {
            NSUInteger index = [self.viewControllers indexOfObject:viewController];
            [self configureView:viewController.view forIndex:index];
        }
    }
}

#pragma mark ViewController Containment


- (void)addViewController:(UIViewController *)aViewController;
{
    [self addViewController:aViewController animated:NO];
}

- (void)addViewController:(UIViewController *)aViewController animated:(BOOL)animated;
{
    NSMutableArray *viewControllers = [self.viewControllers mutableCopy];
    if (!viewControllers) {
        viewControllers = [[NSMutableArray alloc] init];
    }
    [viewControllers addObject:aViewController];
    self.viewControllers = viewControllers;
    
    [self updateShelf];
}

- (void)removeViewController:(UIViewController *)aViewController;
{
    [self removeViewController:aViewController animated:NO];
}

- (void)removeViewController:(UIViewController *)aViewController animated:(BOOL)animated;
{
    NSMutableArray *viewControllers = [self.viewControllers mutableCopy];
    if (!viewControllers) {
        viewControllers = [[NSMutableArray alloc] init];
    }
    [viewControllers removeObject:aViewController];
    self.viewControllers = viewControllers;
    
    [self updateShelf];
}

#pragma mark Shelf Management

- (NSUInteger)numberOfViewControllers;
{
    return [self.viewControllers count];
}

- (NSUInteger)indexOfCurrentViewController;
{
    CGRect scrollViewBounds = self.scrollView.bounds;
    CGRect convertedViewBounds = [self.scrollView convertRect:self.view.bounds fromView:self.view];
    return floor(CGRectGetMidX(convertedViewBounds) / CGRectGetWidth(scrollViewBounds));
}

- (UIViewController *)currentViewController;
{
    NSUInteger index = self.indexOfCurrentViewController;
    return [self.viewControllers objectAtIndex:index];
}

- (NSMutableSet *)visibleViewControllers;
{
    if (_visibleViewControllers == nil) {
        _visibleViewControllers = [[NSMutableSet alloc] init];
    }
    return _visibleViewControllers;
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
    
    NSMutableSet *removedViewControllers = [[NSMutableSet alloc] init];
    for (UIViewController *viewController in self.visibleViewControllers) {
        NSUInteger index = [self.viewControllers indexOfObject:viewController];
        if (index < indexOfFirstNeededViewController || index > indexOfLastNeededViewController) {
            
            [viewController beginAppearanceTransition:NO animated:NO];
            [viewController.view removeFromSuperview];
            [viewController endAppearanceTransition];
            
            [viewController willMoveToParentViewController:nil];
            [viewController removeFromParentViewController];
            [viewController didMoveToParentViewController:nil];
            
            [removedViewControllers addObject:viewController];
        }
    }
    [self.visibleViewControllers minusSet:removedViewControllers];
    
    
    // Add missing view controllers
    // ----------------------------
    
    for (int index = indexOfFirstNeededViewController; index <= indexOfLastNeededViewController; index++) {
        
        if (index < 0 || index >= self.numberOfViewControllers) {
            continue;
        }
        
        UIViewController *viewController = [self.viewControllers objectAtIndex:index];
        if (![self.visibleViewControllers containsObject:viewController]) {
            
            [viewController willMoveToParentViewController:self];
            [self addChildViewController:viewController];
            [viewController didMoveToParentViewController:self];
            
            [self.visibleViewControllers addObject:viewController];
            
            [viewController beginAppearanceTransition:YES animated:NO];
            
            [self.scrollView addSubview:viewController.view];
            [self configureView:viewController.view forIndex:index];
            [viewController.view setUserInteractionEnabled:NO];
            
            [viewController endAppearanceTransition];
        }
    }
    
    
    // Add new ViewController
    // ----------------------
    
    if (indexOfLastNeededViewController == self.numberOfViewControllers) {
        CGFloat offset = (CGRectGetMaxX(convertedViewBounds) / CGRectGetWidth(scrollViewBounds)) - indexOfLastNeededViewController;        
        if (offset > 0.2) {
            if (self.currentlyAddingViewController == NO &&
                self.nextViewController == nil) {
                
                self.nextViewController = [self.delegate nextViewControllerForShelf:self];
                [self.scrollView addSubview:self.nextViewController.view];
            }
            
            if (self.nextViewController) {
                self.nextViewController.view.hidden = NO;
                self.nextViewController.view.alpha = (offset - 0.2) * 3;
                
                [self configureView:self.nextViewController.view forIndex:indexOfLastNeededViewController];
                
                CGFloat deltaX = MAX(0, (0.4 - offset)) * 300;
                CGFloat rotation = MAX(0, (0.4 - offset)) * -30 * M_PI / 180.0;
                
                CGRect frame = self.nextViewController.view.frame;
                frame.origin.x += deltaX;
                self.nextViewController.view.frame = frame;
                self.nextViewController.view.transform = CGAffineTransformMakeRotation(rotation);
            }
        } else {
            self.nextViewController.view.hidden = YES;
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
    self.scrollView.scrollEnabled = NO;
    self.pageControl.enabled = NO;
    
    UIViewController *viewController = self.currentViewController;
    
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
                         for (UIViewController *viewController in self.visibleViewControllers) {
                             if (viewController.view.superview == self.scrollView) {
                                 viewController.view.alpha = 0;
                             }
                         }
                     }
                     completion:^(BOOL completed) {
                         [self finalizeHidingShelf];
                     }
                 skipAnimations:!animated];
}

- (void)finalizeHidingShelf;
{
    self.pageControl.hidden = YES;
    
    UIViewController *viewController = self.currentViewController;
    [viewController.view setUserInteractionEnabled:YES];
    
    self.animatingShelf = NO;
    self.shelfHidden = YES;
}

#pragma mark Showing Shelf

- (void)prepareShowingShelf;
{
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
                         for (UIViewController *viewController in self.visibleViewControllers) {
                             if (viewController.view.superview == self.scrollView) {
                                 viewController.view.alpha = 1;
                             }
                         }
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

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView;
{
    self.currentlyAddingViewController = NO;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView;
{
    [self updateShelf];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate;
{
    CGRect scrollViewBounds = self.scrollView.bounds;
    CGRect convertedViewBounds = [self.scrollView convertRect:self.view.bounds fromView:self.view];
    
    int lastNeededPageIndex = floor((CGRectGetMaxX(convertedViewBounds)) / CGRectGetWidth(scrollViewBounds));
    
    if (lastNeededPageIndex == self.numberOfViewControllers) {
        CGFloat offset = (CGRectGetMaxX(convertedViewBounds) / CGRectGetWidth(scrollViewBounds)) - lastNeededPageIndex;
        
        if (self.nextViewController) {
            if (offset > 0.4) {
                UIViewController *nextViewController = self.nextViewController;
                [self.nextViewController.view removeFromSuperview];
                [UIView animateWithDuration:0.2 animations:^{
                   self.nextViewController.view.alpha = 1; 
                }];
                self.nextViewController = nil;
                [self addViewController:nextViewController];
                self.currentlyAddingViewController = YES;
            }
        }
    }
}

- (void)scrollViewWillBeginDecelerating:(UIScrollView *)scrollView;
{
    if (self.currentlyAddingViewController) {
        [self showViewControllerForIndex:self.numberOfViewControllers - 1 animated:YES];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView;
{
    if (self.nextViewController) {
        [self.nextViewController.view removeFromSuperview];
        self.nextViewController = nil;
    }
}

@end
