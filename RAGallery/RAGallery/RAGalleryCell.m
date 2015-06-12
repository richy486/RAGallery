//
//  RAGalleryCell.m
//  RAGallery
//
//  Created by Richard Adem on 12/06/2015.
//  Copyright (c) 2015 Richard Adem. All rights reserved.
//

#import "RAGalleryCell.h"
#import "CGHelpers.h"

const CGFloat GALLERY_MINIMUM_SCALE = 0.5;
const CGFloat GALLERY_MAXIMUM_SCALE = 5.0;

typedef NS_ENUM(NSUInteger, BoundsCheck) {
    BoundsCheckInside,
    BoundsCheckOutside,
    BoundsCheckAtEdge,
    BoundsCheckCount
};

@interface RAGalleryCell() <UIGestureRecognizerDelegate> {
    CGPoint _lastZoomPoint;
    NSUInteger _lastZoomTouchCount;
    CGFloat _lastScale;
    CGFloat _lastRotation;
    CGRect _defafultRect;
    
    BOOL _shouldScrollPan;
    BOOL _didScrollPan;
}
@property (nonatomic, strong) UIDynamicAnimator *animator;
@end

@implementation RAGalleryCell

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        
        self.clipsToBounds = YES;
        self.showDebugElements = NO;
        
        _defafultRect = frame;
        
        self.imageView = [[UIImageView alloc] initWithFrame:frame];
        self.imageView.contentMode = UIViewContentModeScaleAspectFill;
        
        self.imageView.translatesAutoresizingMaskIntoConstraints = NO;
        self.imageView.userInteractionEnabled = YES;
        [self.contentView addSubview:self.imageView];
        
        UIPinchGestureRecognizer *pinchGesture = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(gesturePinch:)];
        pinchGesture.delegate = self;
        [self.imageView addGestureRecognizer:pinchGesture];
        
        UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(gesturePan:)];
        panGesture.delegate = self;
        panGesture.minimumNumberOfTouches = 1;
        panGesture.maximumNumberOfTouches = 1;
        [self.imageView addGestureRecognizer:panGesture];
        
        UITapGestureRecognizer *doubleTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(gestureDoubleTap:)];
        doubleTapGesture.delegate = self;
        doubleTapGesture.numberOfTapsRequired = 2;
        [self.imageView addGestureRecognizer:doubleTapGesture];
        
        UITapGestureRecognizer *singleTapGesture;
        singleTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(gestureSingleTap:)];
        singleTapGesture.numberOfTapsRequired = 1;
        [singleTapGesture requireGestureRecognizerToFail: doubleTapGesture];
        [self.imageView addGestureRecognizer: singleTapGesture];
        
        UITapGestureRecognizer *singleTapGestureCellView;
        singleTapGestureCellView = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(gestureSingleTap:)];
        singleTapGestureCellView.numberOfTapsRequired = 1;
        [self addGestureRecognizer: singleTapGestureCellView];
        
#if 0
        UIRotationGestureRecognizer *rotationGesture = [[UIRotationGestureRecognizer alloc] initWithTarget:self action:@selector(gestureRotation:)];
        rotationGesture.delegate = self;
        [self.imageView addGestureRecognizer:rotationGesture];
#endif
        
        self.animator = [[UIDynamicAnimator alloc] initWithReferenceView:self.imageView];
    }
    return self;
}

#pragma mark - Accessors

- (void) updateZoomDefaultsFromScreenSize:(CGSize) screenSize {
    
    CGRect screenRect = CGRectMake(0, 0, screenSize.width, screenSize.height);
    CGSize imageSize = self.imageView.image.size;
    CGRect imageFrame = AspectFitRectInRect(CGRectMake(0, 0, imageSize.width, imageSize.height)
                                            , screenRect);
    _defafultRect = imageFrame;
}

- (void) resetZoomAnimated:(BOOL) animated {
    
    if (animated) {
        [UIView animateWithDuration:0.2
                         animations:^{
                             self.imageView.transform = CGAffineTransformIdentity;
                             self.imageView.frame = _defafultRect;
                         }];
    } else {
        self.imageView.transform = CGAffineTransformIdentity;
        self.imageView.frame = _defafultRect;
    }
}

- (void) resetPositionAnimated:(BOOL) animated {
    
    CGRect frame = [self repositionedFrameFromFrame:self.imageView.frame andImageSize:self.imageView.image.size];
    
    if (!CGRectEqualToRect(frame, self.imageView.frame)) {
        
        if (animated) {
            [UIView animateWithDuration:0.2
                             animations:^{
                                 self.imageView.frame = frame;
                             }];
        } else {
            self.imageView.frame = frame;
        }
    }
}

- (void) setShowDebugElements:(BOOL)showDebugElements {
    if (showDebugElements) {
        self.contentView.layer.borderColor = [UIColor blueColor].CGColor;
        self.contentView.layer.borderWidth = 4.0;
        self.imageView.layer.borderColor = [UIColor redColor].CGColor;
        self.imageView.layer.borderWidth = 3.0;
    } else {
        self.contentView.layer.borderWidth = 0.0;
        self.imageView.layer.borderWidth = 0.0;
    }
    _showDebugElements = showDebugElements;
}

#pragma mark - Private methods

- (BOOL) imageViewIsNotInsideBounds:(CGRect*) correctedRect {
    
    BOOL notInside = NO;
    CGRect imageViewRect = self.imageView.frame;
    if (imageViewRect.origin.x > self.bounds.origin.x) {
        imageViewRect.origin.x = self.bounds.origin.x;
        notInside = YES;
    }
    else if (imageViewRect.origin.x + imageViewRect.size.width < self.bounds.origin.x + self.bounds.size.width) {
        imageViewRect.origin.x = (self.bounds.origin.x + self.bounds.size.width) - imageViewRect.size.width;
        notInside = YES;
    }
    
    if (imageViewRect.origin.y > self.bounds.origin.y) {
        imageViewRect.origin.y = self.bounds.origin.y;
        notInside = YES;
    } else if (imageViewRect.origin.y + imageViewRect.size.height < self.bounds.origin.y + self.bounds.size.height) {
        imageViewRect.origin.y = (self.bounds.origin.y + self.bounds.size.height) - imageViewRect.size.height;
        notInside = YES;
    }
    
    *correctedRect = imageViewRect;
    
    return notInside;
}

//  1 inside
//  0 equal
// -1 outside
- (BOOL) imageViewIsInsideOrEqualBounds:(CGRect*) correctedRect checkedEdges:(UIEdgeInsets*) checkedEdges {
    return [self frame:self.imageView.frame isInsideOrEqualBounds:correctedRect checkedEdges:checkedEdges];
}
- (BOOL) frame:(CGRect) frame isInsideOrEqualBounds:(CGRect*) correctedRect checkedEdges:(UIEdgeInsets*) checkedEdges {
    
    BOOL insideOrEqual = NO;
    UIEdgeInsets edges;
    if (frame.origin.x >= self.bounds.origin.x) {
        
        if (frame.origin.x == self.bounds.origin.x) {
            edges.left = 0;
        } else {
            edges.left = 1;
            frame.origin.x = self.bounds.origin.x;
        }
        insideOrEqual = YES;
    } else {
        edges.left = -1;
    }
    
    if (frame.origin.x + frame.size.width <= self.bounds.origin.x + self.bounds.size.width) {
        
        if (frame.origin.x + frame.size.width == self.bounds.origin.x + self.bounds.size.width) {
            edges.right = 0;
        } else {
            edges.right = 1;
            frame.origin.x = (self.bounds.origin.x + self.bounds.size.width) - frame.size.width;
        }
        insideOrEqual = YES;
    } else {
        edges.right = -1;
    }
    
    if (frame.origin.y >= self.bounds.origin.y) {
        
        if (frame.origin.y == self.bounds.origin.y) {
            edges.top = 0;
        } else {
            edges.top = 1;
            frame.origin.y = self.bounds.origin.y;
        }
        insideOrEqual = YES;
    } else {
        edges.top = -1;
    }
    
    if (frame.origin.y + frame.size.height <= self.bounds.origin.y + self.bounds.size.height) {
        
        if (frame.origin.y + frame.size.height == self.bounds.origin.y + self.bounds.size.height) {
            edges.bottom = 0;
        } else {
            edges.bottom = 1;
            frame.origin.y = (self.bounds.origin.y + self.bounds.size.height) - frame.size.height;
        }
        insideOrEqual = YES;
    } else {
        edges.bottom = -1;
    }
    
    *correctedRect = frame;
    *checkedEdges = edges;
    
    return insideOrEqual;
}

- (CGRect) repositionedFrameFromFrame:(CGRect) frame andImageSize:(CGSize) imageSize {
    CGRect correctedRect;
    UIEdgeInsets checkedEdges;
    BOOL insideOrEqual = [self frame:frame isInsideOrEqualBounds:&correctedRect checkedEdges:&checkedEdges];
    
    if (insideOrEqual) {
        
        CGRect imageFrame = AspectFitRectInRect(CGRectMake(0, 0, imageSize.width, imageSize.height), self.bounds);
        
        if (CGRectGetHeight(imageFrame) < CGRectGetHeight(self.bounds)) {
            frame.origin.x = correctedRect.origin.x;
            if (CGRectGetHeight(frame) < CGRectGetHeight(self.bounds)) {
                // center image view
                frame.origin.y = CGRectGetMidY(self.bounds) - (CGRectGetHeight(frame)/2);
            } else if (checkedEdges.top == 1 && checkedEdges.bottom != 1) {
                // move to top
                frame.origin.y = 0;
            } else if (checkedEdges.bottom == 1 && checkedEdges.top != 1) {
                // move to bottom
                frame.origin.y = CGRectGetHeight(self.bounds) - CGRectGetHeight(frame);
            }
        } else {
            frame.origin.y = correctedRect.origin.y;
            if (CGRectGetWidth(frame) < CGRectGetWidth(self.bounds)) {
                frame.origin.x = CGRectGetMidX(self.bounds) - (CGRectGetWidth(frame)/2);
            } else if (checkedEdges.left == 1 && checkedEdges.right != 1) {
                frame.origin.x = 0;
            } else if (checkedEdges.right == 1 && checkedEdges.left != 1) {
                frame.origin.x = CGRectGetWidth(self.bounds) - CGRectGetWidth(frame);
            }
        }
    }
    
    return frame;
}

- (CGFloat) currentScale {
    CGSize imageSize = self.imageView.image.size;
    CGRect imageFrame = AspectFitRectInRect(CGRectMake(0, 0, imageSize.width, imageSize.height), self.bounds);
    CGFloat currentScale = self.imageView.frame.size.width / imageFrame.size.width;
    
    return currentScale;
}

#pragma mark - Gestures

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    if (([gestureRecognizer isMemberOfClass:[UIPinchGestureRecognizer class]] && [otherGestureRecognizer isMemberOfClass:[UIRotationGestureRecognizer class]])
        || ([gestureRecognizer isMemberOfClass:[UIRotationGestureRecognizer class]] && [otherGestureRecognizer isMemberOfClass:[UIPinchGestureRecognizer class]])){
        
        return YES;
    }
    
    return NO;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(isScrollViewDeceleratingForGalleryCell:)]) {
        if ([self.delegate isScrollViewDeceleratingForGalleryCell:self]) {
            return NO;
        }
    }
    
    return YES;
}

- (void)gesturePinch:(UIPinchGestureRecognizer *) gestureRecognizer {
    switch (gestureRecognizer.state) {
        case UIGestureRecognizerStatePossible:
            break;
        case UIGestureRecognizerStateBegan:
            gestureRecognizer.scale = 1;
            _lastZoomPoint = [gestureRecognizer locationOfTouch:0 inView:[gestureRecognizer view]];
            _lastZoomTouchCount = [gestureRecognizer numberOfTouches];
            _lastScale = 1.0;
            
            break;
        case UIGestureRecognizerStateChanged:
        {
            // When one finger is released or added offset the last zoom point to be relative to the current touch point
            if (_lastZoomTouchCount != gestureRecognizer.numberOfTouches) {
                CGPoint point = [gestureRecognizer locationOfTouch:0 inView:[gestureRecognizer view]];
                _lastZoomPoint.x -= _lastZoomPoint.x - point.x;
                _lastZoomPoint.y -= _lastZoomPoint.y - point.y;
            }
            
            CGFloat scale = 1.0 - (_lastScale - gestureRecognizer.scale);
            
            if (scale < GALLERY_MINIMUM_SCALE) {
                scale = GALLERY_MINIMUM_SCALE;
            }
            if (scale > GALLERY_MAXIMUM_SCALE) {
                scale = GALLERY_MAXIMUM_SCALE;
            }
            
            // Mixes pan and pinch for two finger touches
            CGAffineTransform transform = CGAffineTransformScale([[gestureRecognizer view] transform], scale, scale);
            [gestureRecognizer view].transform = transform;
            
            CGPoint point = [gestureRecognizer locationOfTouch:0 inView:[gestureRecognizer view]];
            CGPoint translation = CGPointMake(point.x - _lastZoomPoint.x, point.y - _lastZoomPoint.y);
            CGAffineTransform transformTranslate = CGAffineTransformTranslate([[gestureRecognizer view] transform], translation.x, translation.y);
            [gestureRecognizer view].transform = transformTranslate;
            
            gestureRecognizer.scale = 1;
            _lastZoomPoint = [gestureRecognizer locationOfTouch:0 inView:[gestureRecognizer view]];
            _lastZoomTouchCount = [gestureRecognizer numberOfTouches];
        }
            break;
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateCancelled:
        {
            CGFloat currentScale = [self currentScale];
            
            if (currentScale < 1.0) {
                [self resetZoomAnimated:YES];
            } else if (currentScale > 1.0) {
                [self resetPositionAnimated:YES];
            }
        }
            break;
        case UIGestureRecognizerStateFailed:
            break;
        default:
            break;
    }
}

- (void) gesturePan:(UIPanGestureRecognizer*) gestureRecognizer {
    
    switch (gestureRecognizer.state) {
        case UIGestureRecognizerStatePossible:
            break;
        case UIGestureRecognizerStateBegan:
        {
            _shouldScrollPan = NO;
            _didScrollPan = NO;
            CGPoint velocity = [gestureRecognizer velocityInView:gestureRecognizer.view];
            double radian = atan(velocity.y/velocity.x);
            double degree = radian * 180 / M_PI;
            double thresholdAngle = 45.0;
            if (fabs(degree) < thresholdAngle) {
                _shouldScrollPan = YES;
            }
        }
            break;
        case UIGestureRecognizerStateChanged:
        {
            CGPoint translation = [gestureRecognizer translationInView:self.imageView];
            
            CGRect correctedRect;
            UIEdgeInsets checkedEdges;
            BOOL insideOrEqual = [self imageViewIsInsideOrEqualBounds:&correctedRect checkedEdges:&checkedEdges];
            CGFloat currentScale = [self currentScale];
            
            _didScrollPan = NO;
            if (_shouldScrollPan && insideOrEqual) {
                
                if ((checkedEdges.left >= 0)
                    || (checkedEdges.right >= 0)
                    || currentScale <= 1.0) {
                    
                    if (self.delegate && [self.delegate respondsToSelector:@selector(galleryCell:movedAlongX:onEdges:animated:)]) {
                        CGFloat currentScale = [self currentScale];
                        _didScrollPan = [self.delegate galleryCell:self movedAlongX:translation.x * currentScale onEdges:checkedEdges animated:NO];
                    }
                }
            }
            
            CGAffineTransform transform = self.imageView.transform;
            if (_didScrollPan) {
                transform = CGAffineTransformTranslate(transform, 0, translation.y);
            } else {
                transform = CGAffineTransformTranslate(transform, translation.x, translation.y);
            }
            
            if (!_didScrollPan || currentScale > 1.0) {
                self.imageView.transform = transform;
            }
            
            if (currentScale <= 1.0 && self.delegate && [self.delegate respondsToSelector:@selector(galleryCell:didPan:animated:)]) {
                CGPoint center = CGPointMake(CGRectGetMidX(self.imageView.frame), CGRectGetMidY(self.imageView.frame));
                [self.delegate galleryCell:self didPan:center animated:NO];
            }
            
            [gestureRecognizer setTranslation:CGPointZero inView:self];
        }
            break;
        case UIGestureRecognizerStateCancelled:
        case UIGestureRecognizerStateEnded:
        {
            if (_didScrollPan) {
                [self resetPositionAnimated:YES];
            } else {
                
                
                CGFloat currentScale = [self currentScale];
                CGFloat centerY = CGRectGetMidY(self.imageView.frame);
                
                BOOL willClose = NO;
                if (currentScale <= 1.0) {
                    UIInterfaceOrientation interfaceOrientation = [[UIApplication sharedApplication] statusBarOrientation];
                    if (interfaceOrientation == UIInterfaceOrientationPortrait) {
                        if (centerY > CGRectGetHeight(self.bounds) * 0.6
                            || centerY < CGRectGetHeight(self.bounds) * 0.4) {
                            if (self.delegate && [self.delegate respondsToSelector:@selector(closeGalleryCell:)]) {
                                willClose = YES;
                            }
                        }
                    }
                }
                
                if (willClose) {
                    [self.delegate closeGalleryCell:self];
                } else {
                    CGFloat duration = 0.2;
                    
                    if (currentScale > 1.0) {
                        
                        [self resetPositionAnimated:YES];
                    } else {
                        if (self.delegate && [self.delegate respondsToSelector:@selector(galleryCell:didPan:animated:)]) {
                            CGPoint center = CGPointMake(CGRectGetMidX(self.frame), CGRectGetMidY(self.frame));
                            [self.delegate galleryCell:self didPan:center animated:YES];
                        }
                        
                        [UIView animateWithDuration:duration
                                         animations:^{
                                             self.imageView.transform = CGAffineTransformIdentity;
                                         }
                                         completion:nil];
                    }
                }
            }
            
        }
            break;
        case UIGestureRecognizerStateFailed:
            break;
        default:
            break;
    }
}

- (void) gestureDoubleTap:(UITapGestureRecognizer*) gestureRecognizer {
    
    switch (gestureRecognizer.state) {
        case UIGestureRecognizerStatePossible:
            break;
        case UIGestureRecognizerStateBegan:
            
            break;
        case UIGestureRecognizerStateChanged:
        {
            
        }
            break;
        case UIGestureRecognizerStateEnded:
        {
            CGFloat currentScale = [self currentScale];
            if (currentScale <= 1.0) {
                CGRect frame = [gestureRecognizer view].frame;
                
                CGFloat scale = ScaleToAspectFitRectAroundRect(frame, self.bounds);
                
                CGRect zoomRect = CGRectZero;
                CGPoint point = [gestureRecognizer locationOfTouch:0 inView:[gestureRecognizer view]];
                
                zoomRect.size.height = frame.size.height * scale;
                zoomRect.size.width  = frame.size.width  * scale;
                
                zoomRect.origin.x = CGRectGetMidX(frame) - (CGRectGetWidth(zoomRect)/2) + (scale * (CGRectGetWidth(frame)/2 - point.x)) - (CGRectGetWidth(frame)/2 - point.x);
                zoomRect.origin.y = CGRectGetMidY(frame) - (CGRectGetHeight(zoomRect)/2) + (scale * (CGRectGetHeight(frame)/2 - point.y)) - (CGRectGetHeight(frame)/2 - point.y);
                
                zoomRect = [self repositionedFrameFromFrame:zoomRect andImageSize:self.imageView.image.size];
                
                CGAffineTransform transform = CGAffineTransformFromRectToRect(frame, zoomRect);
                
                [UIView animateWithDuration:0.2
                                 animations:^{
                                     [gestureRecognizer view].transform = transform;
                                     [gestureRecognizer view].frame = zoomRect;
                                 }];
            } else {
                [self resetZoomAnimated:YES];
            }
        }
            break;
        case UIGestureRecognizerStateCancelled:
            break;
        case UIGestureRecognizerStateFailed:
            break;
        default:
            break;
    }
}

- (void) gestureSingleTap:(UITapGestureRecognizer*) gestureRecognizer {
    switch (gestureRecognizer.state) {
        case UIGestureRecognizerStatePossible:
            break;
        case UIGestureRecognizerStateBegan:
            break;
        case UIGestureRecognizerStateChanged:
            break;
        case UIGestureRecognizerStateEnded:
        {
            //            [gestureRecognizer.view isEqual:self]
            //            CGPoint location = [gestureRecognizer locationInView:self];
            if ([gestureRecognizer.view isEqual:self]) {
                if (self.delegate && [self.delegate respondsToSelector:@selector(closeGalleryCell:)]) {
                    [self.delegate closeGalleryCell:self];
                }
            } else {
                if (self.delegate && [self.delegate respondsToSelector:@selector(toggleControlsForGalleryCell:)]) {
                    [self.delegate toggleControlsForGalleryCell:self];
                }
            }
        }
            break;
        case UIGestureRecognizerStateCancelled:
            break;
        case UIGestureRecognizerStateFailed:
            break;
        default:
            break;
    }
}

- (void) gestureRotation:(UIRotationGestureRecognizer*) gestureRecognizer {
    switch (gestureRecognizer.state) {
        case UIGestureRecognizerStatePossible:
            break;
        case UIGestureRecognizerStateBegan:
        case UIGestureRecognizerStateChanged:
        {
            CGFloat rotation = 0.0 - (_lastRotation - gestureRecognizer.rotation);
            
            CGAffineTransform currentTransform = self.imageView.transform;
            CGAffineTransform rotatedTransform = CGAffineTransformRotate(currentTransform, rotation);
            
            self.imageView.transform = rotatedTransform;
            
            _lastRotation = gestureRecognizer.rotation;
        }
            break;
        case UIGestureRecognizerStateEnded:
        {
            _lastRotation = 0.0;
            CGFloat rotation = atan2(self.imageView.transform.b, self.imageView.transform.a);
            CGAffineTransform currentTransform = self.imageView.transform;
            CGAffineTransform rotatedTransform = CGAffineTransformRotate(currentTransform, -rotation);
            
            [UIView animateWithDuration:0.2
                             animations:^{
                                 self.imageView.transform = rotatedTransform;
                             }];
        }
            break;
        case UIGestureRecognizerStateCancelled:
        case UIGestureRecognizerStateFailed:
            break;
            
        default:
            break;
    }
}

@end
