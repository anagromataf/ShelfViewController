//
//  TKShelfViewController.m
//  ShelfViewController
//
//  Created by Tobias Kräntzer on 30.10.12.
//  Copyright (c) 2012 Tobias Kräntzer. All rights reserved.
//

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
- (void)updateShelf;

@end

@implementation TKShelfViewController

#pragma mark Life-cycle

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
    self.scrollView.pagingEnabled = YES;
    self.scrollView.showsHorizontalScrollIndicator = NO;
    self.scrollView.showsVerticalScrollIndicator = NO;
    self.scrollView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
    self.scrollView.backgroundColor = [UIColor lightGrayColor];
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

- (void)updateShelf;
{
    CGRect visibleBounds = self.scrollView.bounds;
    
    self.scrollView.contentSize = CGSizeMake(CGRectGetWidth(visibleBounds) * self.numberOfPages,
                                             CGRectGetHeight(visibleBounds));
    
    self.pageControl.numberOfPages = self.numberOfPages;
    int currentPageIndex = floor(CGRectGetMidX(visibleBounds) / CGRectGetWidth(visibleBounds));
    self.pageControl.currentPage = MIN(MAX(0, currentPageIndex), self.numberOfPages);
    
    int firstNeededPageIndex = floor(CGRectGetMinX(visibleBounds) / CGRectGetWidth(visibleBounds));
    int lastNeededPageIndex = floor((CGRectGetMaxX(visibleBounds)-1) / CGRectGetWidth(visibleBounds));
    
}

#pragma mark UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView;
{
    [self updateShelf];
}

@end
