//
//  SmoothFilter.m
//  BCSegmentation
//
//  Created by Nafis Ahmed on 22/5/19.
//  Copyright © 2019 Nafis Ahmed. All rights reserved.
//

#import "SmoothFilter.h"

@implementation SmoothFilter

+ (CIColorKernel *) kernel {
    static CIColorKernel *thresholdKernel;
    if (!thresholdKernel) {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            NSBundle *bundle = [NSBundle mainBundle];
            NSData *data = [NSData dataWithContentsOfURL:[bundle URLForResource:@"default" withExtension:@"metallib"]];
            thresholdKernel = [CIColorKernel kernelWithFunctionName:@"smooth_out" fromMetalLibraryData:data error:nil];
        });
    }
    return thresholdKernel;
}

- (CIImage *)outputImage {
    if (!self.inputImage) {
        return nil;
    }
    CIFilter *blurFilter = [CIFilter filterWithName:@"CIGaussianBlur" withInputParameters:@{
                                                                                            kCIInputImageKey: self.inputImage,
                                                                                            kCIInputRadiusKey: @(self.inputRadius)
                                                                                            }];
    
    return [self.class.kernel applyWithExtent:self.inputImage.extent arguments:@[blurFilter.outputImage]];
}

@end
