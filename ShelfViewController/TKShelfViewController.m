//
//  TKShelfViewController.m
//  ShelfViewController
//
//  Created by Tobias Kräntzer on 30.10.12.
//  Copyright (c) 2012 Tobias Kräntzer. All rights reserved.
//

#import "TKShelfViewController.h"

#define kTKShelfViewControllerHorizontalInset 40.0
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
@end

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
    
    CGRect scrollViewFrame = CGRectInset(self.view.bounds, kTKShelfViewControllerHorizontalInset, 0);
    
    self.scrollView = [[UIScrollView alloc] initWithFrame:scrollViewFrame];
    self.scrollView.clipsToBounds = NO;
    self.scrollView.pagingEnabled = YES;
    self.scrollView.showsHorizontalScrollIndicator = NO;
    self.scrollView.showsVerticalScrollIndicator = NO;
    self.scrollView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
    self.scrollView.backgroundColor = [UIColor clearColor];
    self.scrollView.delegate = self;
    
    [self.view addSubview:self.scrollView];
    
    
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
    
    [self.view addSubview:self.pageControl];
    
    
    // Update the Shelf
    // ----------------
    
    [self updateShelf];
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
}

- (void)removeSubViewController:(UIViewController *)aViewController;
{
    NSMutableArray *subViewControllers = [self.subViewControllers mutableCopy];
    if (!subViewControllers) {
        subViewControllers = [[NSMutableArray alloc] init];
    }
    [subViewControllers removeObject:aViewController];
    self.subViewControllers = subViewControllers;
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
    CGRect visibleBounds = self.scrollView.bounds;
    
    self.scrollView.contentSize = CGSizeMake(CGRectGetWidth(visibleBounds) * self.numberOfPages,
                                             CGRectGetHeight(visibleBounds));
    
    self.pageControl.numberOfPages = self.numberOfPages;
    int currentPageIndex = floor(CGRectGetMidX(visibleBounds) / CGRectGetWidth(visibleBounds));
    self.pageControl.currentPage = MIN(MAX(0, currentPageIndex), self.numberOfPages);
    
    int firstNeededPageIndex = floor((CGRectGetMinX(visibleBounds)-kTKShelfViewControllerHorizontalInset) / CGRectGetWidth(visibleBounds));
    int lastNeededPageIndex = floor((CGRectGetMaxX(visibleBounds)+kTKShelfViewControllerHorizontalInset-1) / CGRectGetWidth(visibleBounds));
    
    
    // Remove not needed view controllers
    // ----------------------------------
    
    NSMutableSet *removedViewControllers = [[NSMutableSet alloc] init];
    for (UIViewController *viewController in self.visibleSubViewControllers) {
        NSUInteger index = [self.subViewControllers indexOfObject:viewController];
        if (index < firstNeededPageIndex || index > lastNeededPageIndex) {
            [viewController beginAppearanceTransition:NO animated:NO];
            [viewController.view removeFromSuperview];
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
            [self configureSubview:viewController.view forIndex:index];
            [self.scrollView addSubview:viewController.view];
            [viewController beginAppearanceTransition:YES animated:NO];
        }
    }
}

- (void)configureSubview:(UIView *)subview forIndex:(NSUInteger)index;
{
    CGRect frame = self.scrollView.bounds;
    frame.origin.x = index * CGRectGetWidth(self.scrollView.frame);
    CGPoint center = CGPointMake(CGRectGetMidX(frame), CGRectGetMidY(frame));
    subview.bounds = self.view.bounds;
    subview.transform = CGAffineTransformMakeScale(0.65, 0.65);
    subview.center = center;
//    frame = subview.frame;
//    frame.origin.y = 0;
//    frame.size.height = CGRectGetHeight(self.view.bounds);
//    subview.frame = frame;
}

#pragma mark UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView;
{
    [self updateShelf];
}

@end
