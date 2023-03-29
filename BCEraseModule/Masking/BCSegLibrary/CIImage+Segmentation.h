//
//  UIImage+Segmentation.h
//  BCSegmentation
//
//  Created by Nafis Ahmed on 21/5/19.
//  Copyright © 2019 Nafis Ahmed. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface CIImage (Segmentation)

- (CIImage *)bcSegmentation;
- (CIImage *)bcSegmentationWithoutSmoothing;
- (CIImage *)resizeWithSize:(CGSize)size;

@end

NS_ASSUME_NONNULL_END
