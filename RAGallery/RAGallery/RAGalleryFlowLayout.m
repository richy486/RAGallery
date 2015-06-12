//
//  RAGalleryFlowLayout.m
//  RAGallery
//
//  Created by Richard Adem on 12/06/2015.
//  Copyright (c) 2015 Richard Adem. All rights reserved.
//

#import "RAGalleryFlowLayout.h"

@interface RAGalleryFlowLayout()
@end

@implementation RAGalleryFlowLayout

-(void)prepareLayout {
    [super prepareLayout];
    
    CGFloat page = self.currentPage;
    CGFloat width = page * CGRectGetWidth(self.collectionView.frame);
    CGFloat height = self.collectionView.contentOffset.y;
    self.collectionView.contentOffset = CGPointMake(width, height);
}

@end
