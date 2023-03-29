//
//  UIImage+maskImage.h
//  EraserBCLBackgroundEraserObj
//
//  Created by BCL Device 3 on 11/1/23.
//


#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIImage (maskImage)
+ (CIImage *) getMaskImageFromOriginalImage:(UIImage *) originalImage;
+ (BOOL) imageFound:(CIImage *) originalCIImage;
@end

NS_ASSUME_NONNULL_END
