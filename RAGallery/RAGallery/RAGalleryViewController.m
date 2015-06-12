//
//  RAGalleryViewController.m
//  RAGallery
//
//  Created by Richard Adem on 12/06/2015.
//  Copyright (c) 2015 Richard Adem. All rights reserved.
//

#import "RAGalleryViewController.h"
#import "RAGalleryCell.h"
#import "RAGalleryFlowLayout.h"
#import "CGHelpers.h"

NSString static* GalleryCellIdentifer = @"galleryCell";

@interface RAGalleryViewController () <UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout
                                        , RAGalleryCellDelegate> {
    NSUInteger _startingPage;
    BOOL _toggleShowingControls;
    BOOL _shouldRotateToLandscape;
}

@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) UIButton *closeButton;
@property (nonatomic, strong) UIPageControl *pageControl;
@property (nonatomic, assign) CGSize viewSize;
@property (nonatomic, strong) UIView *backgroundCoveringView;

@property (nonatomic, strong) UIImage *backgroundImage;
@property (nonatomic, strong) UIImageView *backgroundImageView;

@property (nonatomic, weak) UIImageView *originalImageView;
@property (nonatomic, strong) UIImage *fromImage;
@property (nonatomic, assign) CGRect fromFrame;
@property (nonatomic, assign) CGRect fromHolderFrame;
@property (nonatomic, assign) CGRect fromHolderFrameExtended;

@end

@implementation RAGalleryViewController

- (id) initWithStartingPage:(NSUInteger) startingPage {
    return [self initWithStartingPage:startingPage withImageView:nil andApplicationWindow:nil];
}
- (id) initWithStartingPage:(NSUInteger) startingPage withImageView:(UIImageView*) imageView andApplicationWindow:(UIWindow*) window {
    self = [super init];
    if (self) {
        _startingPage = startingPage;
        _toggleShowingControls = YES;
        _shouldRotateToLandscape = NO;
        
        self.originalImageView = imageView;
        
        CGFloat deviceScale = [[UIScreen mainScreen] scale];
        
        if (imageView) {
            imageView.hidden = YES;
        }
        
        // Set up fake parent view controller screen
        if (window) {
            // This must be done before calls to self.view
            UIGraphicsBeginImageContextWithOptions(window.bounds.size, YES, deviceScale);
            [window.layer renderInContext:UIGraphicsGetCurrentContext()];
            UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();
            self.backgroundImage = image;
        }
        
        if (imageView) {
            imageView.hidden = NO;
            
            CGRect imageViewFrame = [[imageView superview] convertRect: imageView.frame toView: self.view];
            imageViewFrame.origin.x = imageViewFrame.origin.x / deviceScale;
            imageViewFrame.origin.y = imageViewFrame.origin.y / deviceScale;
            imageViewFrame.size.width = imageViewFrame.size.width / deviceScale;
            imageViewFrame.size.height = imageViewFrame.size.height / deviceScale;
            
            CGRect holderFrame = [[[imageView superview] superview] convertRect: [imageView superview].frame toView: self.view];
            holderFrame.origin.x = holderFrame.origin.x / deviceScale;
            holderFrame.origin.y = holderFrame.origin.y / deviceScale;
            holderFrame.size.width = holderFrame.size.width / deviceScale;
            holderFrame.size.height = holderFrame.size.height / deviceScale;
            
            // if part of imageViewFrame is outside the screen, don't fade it in
            CGRect fromHolderFrameExtended = holderFrame;
            if (imageViewFrame.origin.x < 0) {
                fromHolderFrameExtended.origin.x = imageViewFrame.origin.x;
                fromHolderFrameExtended.size.width += 0 - imageViewFrame.origin.x;
            }
            if (imageViewFrame.origin.x + CGRectGetWidth(imageViewFrame) > CGRectGetWidth(self.view.frame)) {
                // this only works because holderFrame.origin.x has already been updated
                fromHolderFrameExtended.size.width = imageViewFrame.size.width;
            }
            if (imageViewFrame.origin.y < 0) {
                fromHolderFrameExtended.origin.y = imageViewFrame.origin.y;
                fromHolderFrameExtended.size.height += 0 - imageViewFrame.origin.y;
            }
            if (imageViewFrame.origin.y + CGRectGetHeight(imageViewFrame) > CGRectGetHeight(self.view.frame)) {
                fromHolderFrameExtended.size.height = imageViewFrame.size.height;
            }
            
            
            self.fromHolderFrame = holderFrame;
            self.fromHolderFrameExtended = fromHolderFrameExtended;
            self.fromFrame = imageViewFrame;
            
            
            UIGraphicsBeginImageContextWithOptions(imageView.bounds.size, YES, [[UIScreen mainScreen] scale]);
            [imageView.layer renderInContext:UIGraphicsGetCurrentContext()];
            UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();
            
            self.fromImage = image;
        }
        
        self.hideCloseButton = NO;
        self.hidePageControl = NO;
        self.showDebugElements = NO;
    }
    return self;
}
- (void) updateTransitionFramesForImage:(UIImage*) image {
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.viewSize = self.view.bounds.size;
    self.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    
    RAGalleryFlowLayout *flowLayout = [[RAGalleryFlowLayout alloc] init];
    flowLayout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    flowLayout.currentPage = _startingPage;
    
    self.collectionView = [[UICollectionView alloc] initWithFrame:self.view.bounds collectionViewLayout:flowLayout];
    self.collectionView.dataSource = self;
    self.collectionView.delegate = self;
    self.collectionView.pagingEnabled = YES;
    self.collectionView.scrollEnabled = YES;
    self.collectionView.showsHorizontalScrollIndicator = NO;
    self.collectionView.showsVerticalScrollIndicator = NO;
    self.collectionView.translatesAutoresizingMaskIntoConstraints = NO;
    self.collectionView.backgroundColor = [UIColor clearColor];
    [self.collectionView registerClass:[RAGalleryCell class] forCellWithReuseIdentifier:GalleryCellIdentifer];
    [self.view addSubview:self.collectionView];
    
    
    
    NSDictionary *collectionViewMetrics = nil;
    NSDictionary *collectionViewViews = NSDictionaryOfVariableBindings(_collectionView);
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[_collectionView]|"
                                                                      options:0
                                                                      metrics:collectionViewMetrics
                                                                        views:collectionViewViews]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[_collectionView]|"
                                                                      options:0
                                                                      metrics:collectionViewMetrics
                                                                        views:collectionViewViews]];
    
    self.closeButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.closeButton setTitle:@"X" forState:UIControlStateNormal];
    [self.closeButton addTarget:self action:@selector(touchUpIn_closeButton:) forControlEvents:UIControlEventTouchUpInside];
    self.closeButton.translatesAutoresizingMaskIntoConstraints = NO;
    self.closeButton.hidden = self.hideCloseButton;
    [self.view addSubview:self.closeButton];
    
    id topLayoutGuide = self.topLayoutGuide;
    
    NSDictionary *closeButtonMetrics = @{@"width": @(44), @"height": @(44)};
    NSDictionary *closeButtonViews = NSDictionaryOfVariableBindings(_closeButton, topLayoutGuide);
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[_closeButton(width)]|"
                                                                      options:0
                                                                      metrics:closeButtonMetrics
                                                                        views:closeButtonViews]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[topLayoutGuide][_closeButton(height)]"
                                                                      options:0
                                                                      metrics:closeButtonMetrics
                                                                        views:closeButtonViews]];
    
    self.pageControl = [[UIPageControl alloc] init];
    self.pageControl.translatesAutoresizingMaskIntoConstraints = NO;
    [self.pageControl addTarget:self action:@selector(pageChanged:) forControlEvents:UIControlEventValueChanged];
    [self.view addSubview:self.pageControl];
    
    NSDictionary *pageControlMetrics = @{@"height": @(20), @"spacing": @(8)};
    NSDictionary *pageControlViews = NSDictionaryOfVariableBindings(_pageControl);
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[_pageControl]|"
                                                                      options:0
                                                                      metrics:pageControlMetrics
                                                                        views:pageControlViews]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[_pageControl(height)]-spacing-|"
                                                                      options:0
                                                                      metrics:pageControlMetrics
                                                                        views:pageControlViews]];
    
    self.backgroundCoveringView = [[UIView alloc] initWithFrame:self.view.bounds];
    self.backgroundCoveringView.translatesAutoresizingMaskIntoConstraints = NO;
    self.backgroundCoveringView.backgroundColor = [UIColor blackColor];
    self.backgroundCoveringView.alpha = 0.0;
    [self.view addSubview:self.backgroundCoveringView];
    [self.view sendSubviewToBack:self.backgroundCoveringView];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[_backgroundCoveringView]|"
                                                                      options:0
                                                                      metrics:nil
                                                                        views:NSDictionaryOfVariableBindings(_backgroundCoveringView)]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[_backgroundCoveringView]|"
                                                                      options:0
                                                                      metrics:nil
                                                                        views:NSDictionaryOfVariableBindings(_backgroundCoveringView)]];
    
    
    if (self.backgroundImage) {
        self.backgroundImageView = [[UIImageView alloc] initWithImage:self.backgroundImage];
        self.backgroundImageView.translatesAutoresizingMaskIntoConstraints = NO;
        [self.view addSubview:self.backgroundImageView];
        [self.view sendSubviewToBack:self.backgroundImageView];
        
        NSDictionary *metrics = nil;
        NSDictionary *views = NSDictionaryOfVariableBindings(_backgroundImageView);
        [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[_backgroundImageView]|"
                                                                          options:0
                                                                          metrics:metrics
                                                                            views:views]];
        [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[_backgroundImageView]|"
                                                                          options:0
                                                                          metrics:metrics
                                                                            views:views]];
    }
}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    NSTimeInterval moveInTime = 0.35;
    [UIView animateWithDuration:moveInTime animations:^{
        self.backgroundCoveringView.alpha = 1.0;
    }];
    
    NSUInteger pageCount = 0;
    if (self.delegate && [self.delegate respondsToSelector:@selector(numberOfImagesForGallery:)]) {
        pageCount = [self.delegate numberOfImagesForGallery:self];
    }
    self.pageControl.numberOfPages = pageCount;
    self.pageControl.currentPage = _startingPage;
    self.pageControl.hidden = self.hidePageControl || pageCount <= 1;
    
    if (self.fromImage) {
        
        // ----- Setup transition view -----
        
        // TransitionView
        UIView *transitionView = [[UIView alloc] initWithFrame:self.fromFrame];
        transitionView.userInteractionEnabled = NO;
        transitionView.tag = 100;
        transitionView.autoresizesSubviews = YES;
        [self.view addSubview:transitionView];
        
        // Full image view
        UIImageView *fullImageView = [[UIImageView alloc] initWithImage:self.fromImage];
        fullImageView.frame = CGRectMake(0, 0, CGRectGetWidth(self.fromFrame), CGRectGetHeight(self.fromFrame));
        fullImageView.alpha = 0;
        fullImageView.tag = 101;
        fullImageView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        
        [transitionView addSubview:fullImageView];
        
        // Cropping view
        UIView *croppingView = [[UIView alloc] initWithFrame:CGRectMake(self.fromHolderFrameExtended.origin.x - self.fromFrame.origin.x
                                                                        , self.fromHolderFrameExtended.origin.y - self.fromFrame.origin.y
                                                                        , CGRectGetWidth(self.fromHolderFrameExtended)
                                                                        , CGRectGetHeight(self.fromHolderFrameExtended))];
        croppingView.clipsToBounds = YES;
        croppingView.tag = 102;
        croppingView.autoresizesSubviews = YES;
        croppingView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        [transitionView addSubview:croppingView];
        
        UIImageView *croppedImageView = [[UIImageView alloc] initWithImage:self.fromImage];
        croppedImageView.frame = CGRectMake(-croppingView.frame.origin.x
                                            , -croppingView.frame.origin.y
                                            , CGRectGetWidth(self.fromFrame)
                                            , CGRectGetHeight(self.fromFrame));
        croppedImageView.tag = 103;
        croppedImageView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        [croppingView addSubview:croppedImageView];
        
        // ----- setup animation target frames -----
        self.collectionView.hidden = YES;
        
        CGSize screenSize = self.viewSize;
        CGRect screenRect = CGRectMake(0, 0, screenSize.width, screenSize.height);
        
        CGRect toFrame = AspectFitRectInRect(transitionView.frame, screenRect);;
        
        
        // ----- Animate -----
        
        [UIView animateWithDuration:moveInTime/2
                         animations:^{
                             fullImageView.alpha = 1;
                         }];
        [UIView animateWithDuration:moveInTime
                         animations:^{
                             transitionView.frame = toFrame;
                         } completion:^(BOOL finished) {
                             self.collectionView.hidden = NO;
                             [transitionView removeFromSuperview];
                         }];
        
    }
}

- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    _shouldRotateToLandscape = YES;
}

- (void) viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    // required for iOS 7
    [self.view layoutSubviews];
}

-(BOOL)shouldAutorotate {
    return YES;
}

-(NSUInteger)supportedInterfaceOrientations {
    if (!_shouldRotateToLandscape) {
        return UIInterfaceOrientationMaskPortrait;
    }
    return UIInterfaceOrientationMaskAllButUpsideDown;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {
    return UIInterfaceOrientationPortrait;
}

// iOS 8+
- (void) viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    
    self.viewSize = size;
    [self.collectionView.collectionViewLayout invalidateLayout];
    
    NSArray *visibleCells = [self.collectionView visibleCells];
    for (RAGalleryCell *cell in visibleCells) {
        [cell updateZoomDefaultsFromScreenSize:size];
        [cell resetZoomAnimated:NO];
    }
}

// iOS 7 only
- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
    
    float width = UIInterfaceOrientationIsPortrait(toInterfaceOrientation)
    ? [[UIScreen mainScreen] applicationFrame].size.width
    : [[UIScreen mainScreen] applicationFrame].size.height;
    float height = UIInterfaceOrientationIsPortrait(toInterfaceOrientation)
    ? [[UIScreen mainScreen] applicationFrame].size.height
    : [[UIScreen mainScreen] applicationFrame].size.width;
    CGSize viewSize = CGSizeMake(width, height);
    
    self.viewSize = viewSize;
    [self.collectionView.collectionViewLayout invalidateLayout];
    
    NSArray *visibleCells = [self.collectionView visibleCells];
    for (RAGalleryCell *cell in visibleCells) {
        [cell updateZoomDefaultsFromScreenSize:viewSize];
        [cell resetZoomAnimated:NO];
    }
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

#pragma mark - Actions

- (void) touchUpIn_closeButton:(UIButton*) button {
    [self close];
}

- (void) pageChanged:(UIPageControl*) pageControl {
    
    NSUInteger page = pageControl.currentPage;
    
    CGPoint contentOffset = CGPointMake(CGRectGetWidth(self.collectionView.frame) * page, self.collectionView.contentOffset.y);
    [self.collectionView setContentOffset:contentOffset animated:YES];
    
    if ([self.collectionView.collectionViewLayout respondsToSelector:@selector(setCurrentPage:)]) {
        [(id)(self.collectionView.collectionViewLayout) setCurrentPage:page];
    }
}

#pragma mark - Accessors

- (void) setHideCloseButton:(BOOL)hideCloseButton {
    self.closeButton.hidden = hideCloseButton;
    _hideCloseButton = hideCloseButton;
}

- (void) setHidePageControl:(BOOL)hidePageControl {
    self.pageControl.hidden = hidePageControl || self.pageControl.numberOfPages <= 1;
    _hidePageControl = hidePageControl;
}

- (void) toggleShowControls {
    _toggleShowingControls = !_toggleShowingControls;
    
    if (_toggleShowingControls) {
        // show
        self.closeButton.hidden = _hideCloseButton;
        self.pageControl.hidden = _hidePageControl || self.pageControl.numberOfPages <= 1;
    } else {
        // hide
        self.closeButton.hidden = YES;
        self.pageControl.hidden = YES;
    }
}

#pragma mark - Private methods

- (void) close {
    
    _shouldRotateToLandscape = NO;
    NSTimeInterval moveBackTime = 0.35;
    
    // Run all of the completion block if all the animations have played.
    // This is so we can adjust the animation times without dismissing the VC too soon.
    // Remember to update totalAnimations.
    NSUInteger totalAnimations = 3;
    __block NSUInteger animationsFinished = 0;
    void (^completion)(BOOL finished) = ^void(BOOL finished) {
        if (++animationsFinished >= totalAnimations) {
            [UIView setAnimationsEnabled:NO];
            if (self.delegate && [self.delegate respondsToSelector:@selector(gallery:willCloseFromIndex:)]) {
                NSUInteger page = [(id)(self.collectionView.collectionViewLayout) currentPage];
                [self.delegate gallery:self willCloseFromIndex:page];
            }
            
            // Run on next main loop
            dispatch_async (dispatch_get_main_queue (), ^{
                [self dismissViewControllerAnimated:NO completion:^{
                    [UIView setAnimationsEnabled:YES];
                }];
            });
        }
    };
    
    [UIView animateWithDuration:moveBackTime animations:^{
        self.backgroundCoveringView.alpha = 0.0;
    } completion:completion];
    
    
    if (self.fromImage) {
        // ----- Setup transition view -----
        
        
        
        RAGalleryCell *cell = (RAGalleryCell*)[[self.collectionView visibleCells] firstObject];
        CGRect cellFrame = cell.imageView.frame;
        UIImage *cellImage = cell.imageView.image;
        
        // TransitionView
        UIView *transitionView = [[UIView alloc] initWithFrame:CGRectMake(cellFrame.origin.x
                                                                          , cellFrame.origin.y
                                                                          , CGRectGetWidth(self.fromFrame)
                                                                          , CGRectGetHeight(self.fromFrame))];
        transitionView.userInteractionEnabled = NO;
        transitionView.autoresizesSubviews = YES;
        transitionView.tag = 100;
        [self.view addSubview:transitionView];
        
        // Full image view
        UIImageView *fullImageView = [[UIImageView alloc] initWithImage:cellImage];
        fullImageView.frame = CGRectMake(0, 0, CGRectGetWidth(self.fromFrame), CGRectGetHeight(self.fromFrame));
        fullImageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        fullImageView.alpha = 1;
        fullImageView.tag = 101;
        [transitionView addSubview:fullImageView];
        
        // Cropping view
        UIView *croppingView = [[UIView alloc] initWithFrame:CGRectMake(self.fromHolderFrameExtended.origin.x - self.fromFrame.origin.x
                                                                        , self.fromHolderFrameExtended.origin.y - self.fromFrame.origin.y
                                                                        , CGRectGetWidth(self.fromHolderFrameExtended)
                                                                        , CGRectGetHeight(self.fromHolderFrameExtended))];
        croppingView.clipsToBounds = YES;
        croppingView.autoresizesSubviews = YES;
        croppingView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        croppingView.tag = 102;
        [transitionView addSubview:croppingView];
        
        UIImageView *croppedImageView = [[UIImageView alloc] initWithImage:cellImage];
        croppedImageView.frame = CGRectMake(-croppingView.frame.origin.x
                                            , -croppingView.frame.origin.y
                                            , CGRectGetWidth(self.fromFrame)
                                            , CGRectGetHeight(self.fromFrame));
        croppedImageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        croppedImageView.tag = 103;
        [croppingView addSubview:croppedImageView];
        
        // scale up transition view to the size of the cell image size
        // scaling up all it's subviews along with it
        CGFloat scale = CGRectGetWidth(cellFrame) / CGRectGetWidth(self.fromHolderFrameExtended);
        CGRect transitionViewFrame = transitionView.frame;
        transitionViewFrame.size.width *= scale;
        transitionViewFrame.size.height *= scale;
        transitionView.frame = transitionViewFrame;
        
        UIInterfaceOrientation interfaceOrientation = [[UIApplication sharedApplication] statusBarOrientation];
        if (interfaceOrientation != UIInterfaceOrientationPortrait) {
            
            // find originalImageView View Controller
            // self.presentingViewController may return a super class
            id object = [self.originalImageView nextResponder];
            while (![object isKindOfClass:[UIViewController class]] && object != nil) {
                object = [object nextResponder];
            }
            
            NSUInteger supportedOrientations = [object supportedInterfaceOrientations];
            NSUInteger orientationMask = supportedOrientations & UIInterfaceOrientationMaskLandscape;
            if (orientationMask == 0) {
                
                // TODO: Look at a safer/better way to do this
                // http://stackoverflow.com/a/20987296/667834
                NSNumber *value = [NSNumber numberWithInt: UIInterfaceOrientationPortrait];
                [[UIDevice currentDevice] setValue:value forKey:@"orientation"];
            }
        }
        
        // ----- setup animation target frames -----
        self.collectionView.hidden = YES;
        
        CGRect toFrame = self.fromFrame;
        

        
        [UIView animateWithDuration:moveBackTime/2
                              delay:moveBackTime
                            options:0
                         animations:^{
                             fullImageView.alpha = 0;
                         } completion:completion];
        
        [UIView animateWithDuration:moveBackTime
                         animations:^{
                             transitionView.frame = toFrame;
                         } completion:completion];
    }
    
}

#pragma mark - Collection view data source

- (NSInteger) collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(numberOfImagesForGallery:)]) {
        NSUInteger count = [self.delegate numberOfImagesForGallery:self];
        return count;
    }
    
    return 0;
}

- (UICollectionViewCell*) collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    RAGalleryCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:GalleryCellIdentifer forIndexPath:indexPath];
    
    if (self.showDebugElements) {
        cell.backgroundColor = [UIColor orangeColor];
        cell.layer.borderColor = [UIColor greenColor].CGColor;
        cell.layer.borderWidth = 2.0;
    }
    cell.showDebugElements = self.showDebugElements;
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(gallery:setupImageAtIndex:forImageView:)]) {
        [self.delegate gallery:self setupImageAtIndex:indexPath.item forImageView:cell.imageView];
    }
    
    NSArray *imageViewGestureRecognizers = cell.imageView.gestureRecognizers;
    
    NSArray *collectionViewGestureRecognizers = [collectionView gestureRecognizers];
    
    cell.delegate = self;
    [cell updateZoomDefaultsFromScreenSize:collectionView.bounds.size];
    [cell resetZoomAnimated:NO];
    
    // Make the default gesture recognizer wait until the custom one fails.
    for (UIGestureRecognizer* collectionViewGestureRecognizer in collectionViewGestureRecognizers) {
        if ([collectionViewGestureRecognizer isKindOfClass:[UIPanGestureRecognizer class]]) {
            
            for (UIGestureRecognizer *imageViewGestureRecognizer in imageViewGestureRecognizers) {
                if ([imageViewGestureRecognizer isKindOfClass:[UIPanGestureRecognizer class]]) {
                    [collectionViewGestureRecognizer requireGestureRecognizerToFail:imageViewGestureRecognizer];
                }
            }
        }
    }
    
    return cell;
}

#pragma mark - Collection view delegate

#pragma mark - Flow layout delegate

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return self.viewSize;
}
- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    return UIEdgeInsetsZero;
}
- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section {
    return 0;
}
- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section {
    return 0;
}
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section {
    return CGSizeZero;
}
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout referenceSizeForFooterInSection:(NSInteger)section {
    return CGSizeZero;
}

#pragma mark - Scroll view delegate

- (void) scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    
    CGFloat pageWidth = CGRectGetWidth(scrollView.frame);
    CGFloat pageFraction = scrollView.contentOffset.x / pageWidth;
    NSUInteger currentPage = lround(pageFraction);
    
    self.pageControl.currentPage = currentPage;
    if ([self.collectionView.collectionViewLayout respondsToSelector:@selector(setCurrentPage:)]) {
        [(id)(self.collectionView.collectionViewLayout) setCurrentPage:currentPage];
    }
}

#pragma mark - Full screen gallery cell delegate

- (BOOL) galleryCell:(RAGalleryCell *)galleryCell movedAlongX:(CGFloat)xDelta onEdges:(UIEdgeInsets) edges animated:(BOOL) animated {
    CGPoint contentOffset = self.collectionView.contentOffset;
    contentOffset.x -= xDelta;
    BOOL scrolled = YES;
    
    NSUInteger page = [(id)(self.collectionView.collectionViewLayout) currentPage];
    CGFloat pageWidth = CGRectGetWidth(self.collectionView.frame);
    
    if (edges.left >= 0 && edges.right < 0) {
        if (contentOffset.x > page * pageWidth) {
            contentOffset.x = page * pageWidth;
            scrolled = NO;
        }
    } else if (edges.right >= 0 && edges.left < 0) {
        if (contentOffset.x < page * pageWidth) {
            contentOffset.x = page * pageWidth;
            scrolled = NO;
        }
    }
    
    [self.collectionView setContentOffset:contentOffset animated:animated];
    
    return scrolled;
}

- (void) galleryCell:(RAGalleryCell*) galleryCell didPan:(CGPoint) position animated:(BOOL)animated {
    
    
    UIInterfaceOrientation interfaceOrientation = [[UIApplication sharedApplication] statusBarOrientation];
    if (interfaceOrientation == UIInterfaceOrientationPortrait) {
        
        CGFloat halfHeight = CGRectGetHeight(self.view.frame)/2;
        CGFloat percentageFromCenter = 1.0 - (fabs(position.y - halfHeight) / halfHeight);
        
        if (animated) {
            [UIView animateWithDuration:0.2 animations:^{
                self.backgroundCoveringView.alpha = percentageFromCenter;
            }];
        } else {
            self.backgroundCoveringView.alpha = percentageFromCenter;
        }
    }
    
}

- (BOOL) isScrollViewDeceleratingForGalleryCell:(RAGalleryCell*) galleryCell {
    return [self.collectionView isDecelerating];
}

- (void) closeGalleryCell:(RAGalleryCell*) galleryCell {
    [self close];
}

- (void) toggleControlsForGalleryCell:(RAGalleryCell*) galleryCell {
    [self toggleShowControls];
}

#pragma mark - Memory manager

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
 #pragma mark - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 */

@end
