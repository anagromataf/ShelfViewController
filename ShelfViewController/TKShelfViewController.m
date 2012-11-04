//
//  TKShelfViewController.m
//  ShelfViewController
//
//  Created by Tobias Kräntzer on 30.10.12.
//  Copyright (c) 2012 Tobias Kräntzer. All rights reserved.
//


#import <QuartzCore/QuartzCore.h>

#import "UIView+TKShelfViewController.h"

#import "TKShelfViewController.h"

#define kTKShelfViewControllerHorizontalInset 20.0
#define kTKShelfViewControllerPageControlHeight 44.0

@interface TKShelfViewController () <UIScrollViewDelegate>
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIPageControl *pageControl;

#pragma mark ViewController Containment
@property (nonatomic, readwrite) NSArray *subViewControllers;

#pragma mark Shelf Management
@property (nonatomic, readonly) NSUInteger numberOfPages;
@property (nonatomic, readonly) NSMutableSet *visibleSubViewControllers;
- (void)updateShelf;
- (void)configureSubview:(UIView *)subview forIndex:(NSUInteger)index;

#pragma mark Paging
- (void)pageControlDidChangeValue:(id)sender;
- (void)showSubviewAtIndex:(NSUInteger)index animated:(BOOL)animated;

#pragma mark Focus
@property (nonatomic, assign) CGFloat focus;
- (void)setFocus:(CGFloat)focus animated:(BOOL)animated;

@end

#pragma mark -

@implementation TKShelfViewController

#pragma mark Life-cycle

@synthesize visibleSubViewControllers = _visibleSubViewControllers;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

#pragma mark UIViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Create Scroll View
    // ------------------
    
    CGRect scrollViewFrame = CGRectInset(self.view.bounds, -kTKShelfViewControllerHorizontalInset, 0);
    
    self.scrollView = [[UIScrollView alloc] initWithFrame:scrollViewFrame];
    self.scrollView.clipsToBounds = NO;
    self.scrollView.pagingEnabled = YES;
    self.scrollView.showsHorizontalScrollIndicator = NO;
    self.scrollView.showsVerticalScrollIndicator = NO;
    self.scrollView.backgroundColor = [UIColor clearColor];
    self.scrollView.delegate = self;
    
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
    
    
    // Update the Shelf
    // ----------------
    
    [self updateShelf];
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration;
{
    [UIView animateWithDuration:duration animations:^{
        NSUInteger oldIndex = floor(CGRectGetMinX(self.scrollView.bounds) / CGRectGetWidth(self.scrollView.bounds));
        
        CGRect scrollViewFrame = CGRectInset(self.view.bounds, -kTKShelfViewControllerHorizontalInset, 0);
        self.scrollView.frame = scrollViewFrame;
        self.scrollView.contentOffset = CGPointMake(CGRectGetWidth(self.scrollView.bounds) * oldIndex, 0);
    }];
    
    for (UIViewController *viewController in self.visibleSubViewControllers) {
        NSUInteger index = [self.subViewControllers indexOfObject:viewController];
        [self configureSubview:viewController.view forIndex:index];
    }
}

#pragma mark ViewController Containment

- (void)addSubViewController:(UIViewController *)aViewController;
{
    NSMutableArray *subViewControllers = [self.subViewControllers mutableCopy];
    if (!subViewControllers) {
        subViewControllers = [[NSMutableArray alloc] init];
    }
    [subViewControllers addObject:aViewController];
    self.subViewControllers = subViewControllers;
    
    [self updateShelf];
}

- (void)removeSubViewController:(UIViewController *)aViewController;
{
    NSMutableArray *subViewControllers = [self.subViewControllers mutableCopy];
    if (!subViewControllers) {
        subViewControllers = [[NSMutableArray alloc] init];
    }
    [subViewControllers removeObject:aViewController];
    self.subViewControllers = subViewControllers;
    
    [self updateShelf];
}

#pragma mark Shelf Management

- (NSUInteger)numberOfPages;
{
    return [self.subViewControllers count];
}

- (NSMutableSet *)visibleSubViewControllers;
{
    if (_visibleSubViewControllers == nil) {
        _visibleSubViewControllers = [[NSMutableSet alloc] init];
    }
    return _visibleSubViewControllers;
}

- (void)updateShelf;
{
    if (self.scrollView == nil) {
        return;
    }
    
    CGRect scrollViewBounds = self.scrollView.bounds;
    CGRect convertedViewBounds = [self.scrollView convertRect:self.view.bounds fromView:self.view];
    
    self.scrollView.contentSize = CGSizeMake(CGRectGetWidth(scrollViewBounds) * self.numberOfPages,
                                             CGRectGetHeight(scrollViewBounds));
    
    self.pageControl.numberOfPages = self.numberOfPages;
    int currentPageIndex = floor(CGRectGetMidX(convertedViewBounds) / CGRectGetWidth(scrollViewBounds));
    self.pageControl.currentPage = MIN(MAX(0, currentPageIndex), self.numberOfPages);
    
    int firstNeededPageIndex = floor((CGRectGetMinX(convertedViewBounds)) / CGRectGetWidth(scrollViewBounds));
    int lastNeededPageIndex = floor((CGRectGetMaxX(convertedViewBounds)) / CGRectGetWidth(scrollViewBounds));
    
    
    // Remove not needed view controllers
    // ----------------------------------
    
    NSMutableSet *removedViewControllers = [[NSMutableSet alloc] init];
    for (UIViewController *viewController in self.visibleSubViewControllers) {
        NSUInteger index = [self.subViewControllers indexOfObject:viewController];
        if (index < firstNeededPageIndex || index > lastNeededPageIndex) {
            
            [viewController beginAppearanceTransition:NO animated:NO];
            
            [viewController.view removeFromSuperview];
            
            [viewController endAppearanceTransition];
            
            [viewController willMoveToParentViewController:nil];
            [viewController removeFromParentViewController];
            [viewController didMoveToParentViewController:nil];
            
            [removedViewControllers addObject:viewController];
        }
    }
    [self.visibleSubViewControllers minusSet:removedViewControllers];
    
    
    // Add missing view controllers
    // ----------------------------
    
    for (int index = firstNeededPageIndex; index <= lastNeededPageIndex; index++) {
        
        if (index < 0 || index >= self.numberOfPages) {
            continue;
        }
        
        UIViewController *viewController = [self.subViewControllers objectAtIndex:index];
        if (![self.visibleSubViewControllers containsObject:viewController]) {
            
            [viewController willMoveToParentViewController:self];
            [self addChildViewController:viewController];
            [viewController didMoveToParentViewController:self];
            
            [self.visibleSubViewControllers addObject:viewController];
            
            [viewController beginAppearanceTransition:YES animated:NO];
            
            [self configureSubview:viewController.view forIndex:index];
            [self.scrollView addSubview:viewController.view];
            
            [viewController endAppearanceTransition];
        }
    }
}

- (void)configureSubview:(UIView *)subview forIndex:(NSUInteger)index;
{
    CGRect frame = self.scrollView.bounds;
    frame.origin.x = index * CGRectGetWidth(self.scrollView.bounds);
    subview.frame = CGRectInset(frame, kTKShelfViewControllerHorizontalInset, 0);
}

#pragma mark Paging

- (void)pageControlDidChangeValue:(id)sender;
{
    if (self.pageControl == sender) {
        [self showSubviewAtIndex:self.pageControl.currentPage animated:YES];
    }
}

- (void)showSubviewAtIndex:(NSUInteger)index animated:(BOOL)animated;
{
    [self.scrollView setContentOffset:CGPointMake(CGRectGetWidth(self.scrollView.bounds) * index, 0) animated:animated];
}

#pragma mark Focus

- (void)setFocus:(CGFloat)focus;
{
    [self setFocus:focus animated:NO];
}

- (void)setFocus:(CGFloat)focus animated:(BOOL)animated;
{
    focus = MAX(0, MIN(1, focus));
    
    if (focus != 0) {
        self.scrollView.scrollEnabled = NO;
    } else {
        self.scrollView.scrollEnabled = YES;
    }
    
    [UIView animateWithDuration:0.2 animations:^{
        CATransform3D transformation = CATransform3DIdentity;
        transformation.m34 = -1.0/500.0;
        transformation = CATransform3DTranslate(transformation, 0, 0, (1 - focus) * -200);
        self.scrollView.layer.transform  = transformation;
    } skipAnimation:!animated];
}

#pragma mark UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView;
{
    [self updateShelf];
}

@end
