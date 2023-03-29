//
//  SmoothFilter.h
//  BCSegmentation
//
//  Created by Nafis Ahmed on 22/5/19.
//  Copyright © 2019 Nafis Ahmed. All rights reserved.
//
#import <UIKit/UIKit.h>
#import <CoreImage/CoreImage.h>

NS_ASSUME_NONNULL_BEGIN

@interface SmoothFilter : CIFilter

@property (nonatomic, weak) CIImage *inputImage;
@property (nonatomic) CGFloat inputRadius;

@end

NS_ASSUME_NONNULL_END
