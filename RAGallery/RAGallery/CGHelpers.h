//
//  CGHelpers.h
//  RAGallery
//
//  Created by Richard Adem on 12/06/2015.
//  Copyright (c) 2015 Richard Adem. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

CGAffineTransform CGAffineTransformFromRectToRect(CGRect fromRect, CGRect toRect);

// https://gist.github.com/milkllc/6874933
CGRect AspectFitRectInRect(CGRect rfit, CGRect rtarget);
CGFloat ScaleToAspectFitRectInRect(CGRect rfit, CGRect rtarget);
CGFloat ScaleToAspectFitRectAroundRect(CGRect rfit, CGRect rtarget);
CGRect AspectFitRectAroundRect(CGRect rfit, CGRect rtarget);
