//
//  UIImage+Segmentation.m
//  BCSegmentation
//
//  Created by Nafis Ahmed on 21/5/19.
//  Copyright © 2019 Nafis Ahmed. All rights reserved.
//

#import "CIImage+Segmentation.h"

@implementation CIImage (Segmentation)

- (CIImage *)resizeWithSize:(CGSize)size {
    CGFloat scaleX = size.width / CGRectGetWidth(self.extent);
    CGFloat scaleY = size.height / CGRectGetHeight(self.extent);

    CIImage *output = [self imageByApplyingTransform:CGAffineTransformMakeScale(scaleX, scaleY)];
    return output;
}

@end
