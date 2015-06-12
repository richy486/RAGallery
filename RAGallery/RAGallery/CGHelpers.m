//
//  CGHelpers.m
//  RAGallery
//
//  Created by Richard Adem on 12/06/2015.
//  Copyright (c) 2015 Richard Adem. All rights reserved.
//

#import "CGHelpers.h"

CGAffineTransform CGAffineTransformFromRectToRect(CGRect fromRect, CGRect toRect)
{
    CGAffineTransform trans1 = CGAffineTransformMakeTranslation(-fromRect.origin.x, -fromRect.origin.y);
    CGAffineTransform scale = CGAffineTransformMakeScale(toRect.size.width/fromRect.size.width, toRect.size.height/fromRect.size.height);
    CGAffineTransform trans2 = CGAffineTransformMakeTranslation(toRect.origin.x, toRect.origin.y);
    return CGAffineTransformConcat(CGAffineTransformConcat(trans1, scale), trans2);
}

// https://gist.github.com/milkllc/6874933
CGRect AspectFitRectInRect(CGRect rfit, CGRect rtarget)
{
    CGFloat s = ScaleToAspectFitRectInRect(rfit, rtarget);
    CGFloat w = CGRectGetWidth(rfit) * s;
    CGFloat h = CGRectGetHeight(rfit) * s;
    CGFloat x = CGRectGetMidX(rtarget) - w / 2;
    CGFloat y = CGRectGetMidY(rtarget) - h / 2;
    return CGRectMake(x, y, w, h);
}
CGFloat ScaleToAspectFitRectInRect(CGRect rfit, CGRect rtarget)
{
    // first try to match width
    CGFloat s = CGRectGetWidth(rtarget) / CGRectGetWidth(rfit);
    // if we scale the height to make the widths equal, does it still fit?
    if (CGRectGetHeight(rfit) * s <= CGRectGetHeight(rtarget)) {
        return s;
    }
    // no, match height instead
    return CGRectGetHeight(rtarget) / CGRectGetHeight(rfit);
}
CGFloat ScaleToAspectFitRectAroundRect(CGRect rfit, CGRect rtarget)
{
    // fit in the target inside the rectangle instead, and take the reciprocal
    return 1 / ScaleToAspectFitRectInRect(rtarget, rfit);
}
CGRect AspectFitRectAroundRect(CGRect rfit, CGRect rtarget)
{
    CGFloat s = ScaleToAspectFitRectAroundRect(rfit, rtarget);
    CGFloat w = CGRectGetWidth(rfit) * s;
    CGFloat h = CGRectGetHeight(rfit) * s;
    CGFloat x = CGRectGetMidX(rtarget) - w / 2;
    CGFloat y = CGRectGetMidY(rtarget) - h / 2;
    return CGRectMake(x, y, w, h);
}
