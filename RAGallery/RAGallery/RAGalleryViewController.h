//
//  RAGalleryViewController.h
//  RAGallery
//
//  Created by Richard Adem on 12/06/2015.
//  Copyright (c) 2015 Richard Adem. All rights reserved.
//

#import <UIKit/UIKit.h>

@class RAGalleryViewController;

@protocol RAGalleryViewControllerDelegate <NSObject>

- (NSUInteger) numberOfImagesForGallery:(RAGalleryViewController*) viewController;
- (void) gallery:(RAGalleryViewController*) viewController setupImageAtIndex:(NSUInteger) index forImageView:(UIImageView*) imageView;
- (void) gallery:(RAGalleryViewController*) viewController willCloseFromIndex:(NSUInteger) index;
@end

@interface RAGalleryViewController : UIViewController

@property (nonatomic, assign) id<RAGalleryViewControllerDelegate> delegate;
@property (nonatomic, assign) BOOL hideCloseButton;
@property (nonatomic, assign) BOOL hidePageControl;
@property (nonatomic, assign) BOOL showDebugElements;
- (id) initWithStartingPage:(NSUInteger) startingPage;
- (id) initWithStartingPage:(NSUInteger) startingPage withImageView:(UIImageView*) imageView andApplicationWindow:(UIWindow*) window;

@end
