//
//  Cell.h
//  RAGallery
//
//  Created by Richard Adem on 12/06/2015.
//  Copyright (c) 2015 Richard Adem. All rights reserved.
//

#import <UIKit/UIKit.h>

@class RAGalleryCell;

@protocol RAGalleryCellDelegate <NSObject>

- (BOOL) galleryCell:(RAGalleryCell*) galleryCell movedAlongX:(CGFloat) xDelta onEdges:(UIEdgeInsets) edges animated:(BOOL) animated;
- (void) galleryCell:(RAGalleryCell*) galleryCell didPan:(CGPoint) position animated:(BOOL) animated;
// RA - Is the best way to do this? Seems like delegates are not the right pattern here
- (BOOL) isScrollViewDeceleratingForGalleryCell:(RAGalleryCell*) galleryCell;
- (void) closeGalleryCell:(RAGalleryCell*) galleryCell;
- (void) toggleControlsForGalleryCell:(RAGalleryCell*) galleryCell;
@end

@interface RAGalleryCell : UICollectionViewCell
@property (nonatomic, strong) id<RAGalleryCellDelegate> delegate;
@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, assign) BOOL showDebugElements;
- (void) updateZoomDefaultsFromScreenSize:(CGSize) screenSize;
- (void) resetZoomAnimated:(BOOL) animated;

@end
