//
//  UIImage+maskImage.m
//  EraserBCLBackgroundEraserObj
//
//  Created by BCL Device 3 on 11/1/23.
//

#import "UIImage+maskImage.h"
#import "DeepLabV3.h"
#import "CIImage+Segmentation.h"
#import "SmoothFilter.h"

#pragma mark - Memory
#define Current_RAM [NSProcessInfo processInfo].physicalMemory / (1024.0 * 1024.0 * 1024.0)


CIImage *curImage;
CIImage *curSegmentationMask;
UIImage *globalImage;
CIContext *context;
@import MLImageSegmentationLibrary;
@implementation UIImage (maskImage)


+ (CIImage *) getMaskImageFromOriginalImage:(UIImage *) originalImage{
    globalImage = originalImage;
    curImage = [CIImage imageWithCGImage:[originalImage CGImage]];
    curSegmentationMask = [self bcSegmentation:curImage];
    return curSegmentationMask;
}

+ (CIImage *) bcSegmentation:(CIImage*)sampleImage {
    @autoreleasepool {
        CVPixelBufferRef pixBuf = [self pixelBufferWithSize:CGSizeMake(513, 513) :sampleImage];
        NSError *error;
        DeepLabV3 *bcseg = [[DeepLabV3 alloc] init];
        DeepLabV3Output *segOutput = [bcseg predictionFromImage:pixBuf error:&error];
        CVPixelBufferRelease(pixBuf);
        int width = 513, height = 513;
        NSMutableArray<NSNumber *> *res = [NSMutableArray array];
        BOOL imageContainsHuman = NO;
        for (int i = 0; i < height; i++) {
            for (int j = 0; j < width; j++) {
                int pageOffset = i * height + j;
                int type = segOutput.semanticPredictions[pageOffset].intValue;
                if(type==15){
                    imageContainsHuman = YES;
                }
                [res addObject:@(type)];
                /*
                 types map  [
                 'background', 'aeroplane', 'bicycle', 'bird', 'boat', 'bottle', 'bus',
                 'car', 'cat', 'chair', 'cow', 'diningtable', 'dog', 'horse', 'motorbike',
                 'person', 'pottedplant', 'sheep', 'sofa', 'train', 'tv'
                 ]
                 */
            }
        }
        NSLog(@"%f", Current_RAM);
        if(Current_RAM<1.8||!imageContainsHuman){
            curSegmentationMask =  [self getCIImageFromDeepLabModel:res];
            bcseg = nil;
            segOutput = nil;
            return curSegmentationMask;
        }
        else{
            res = nil;
            curSegmentationMask = [self getCIImageFromHuaweiModel];
            return  curSegmentationMask;
        }
    }
}

+ (CIImage *) getCIImageFromDeepLabModel:( NSMutableArray<NSNumber *> *)result{
    int width = 513, height = 513;
    UInt8 *pixelData = malloc(sizeof(UInt8) * width * height * 3);
    int bytesPerComponent = 1;
    int bytesPerPixel = bytesPerComponent * 3;
    int counter = 0;
    for (int i = 0; i < result.count; i++) {
        int currentPixValue = 0;
        switch (result[i].intValue) {
            case 3:     // bird
            case 8:     // cat
            case 12:    // dog
            case 15:    // person
                currentPixValue = 255;
                break;
            default:
                currentPixValue = 0;
                break;
        }
        for (int j = 0; j < 3; j++) {
            pixelData[counter++] = currentPixValue;
        }
    }
    CFDataRef rgbData = CFDataCreate(NULL, pixelData, width * height * 3);
    CGDataProviderRef provider = CGDataProviderCreateWithCFData(rgbData);
    CGImageRef rgbImageRef = CGImageCreate(width, height,
                                           bytesPerComponent * 8, bytesPerPixel * 8,
                                           width * bytesPerPixel,
                                           CGColorSpaceCreateDeviceRGB(),
                                           kCGBitmapByteOrderDefault,
                                           provider,
                                           NULL,
                                           false,
                                           kCGRenderingIntentDefault);
    
    
    
    
    result = nil;
    CFRelease(rgbData);
    CGDataProviderRelease(provider);
    free(pixelData);
    curSegmentationMask = [CIImage imageWithCGImage:rgbImageRef];
    curSegmentationMask = [self processCIImageWithFilter];
    CGImageRelease(rgbImageRef);
    return curSegmentationMask;
}
+(CIImage *) processCIImageWithFilter{
    curSegmentationMask = [curSegmentationMask imageByApplyingFilter:@"CIMaskToAlpha"];
    SmoothFilter *smoothFilter = [[SmoothFilter alloc] init];
    smoothFilter.inputImage = curSegmentationMask;
    smoothFilter.inputRadius = (curSegmentationMask.extent.size.width / 360.0);
    curSegmentationMask = smoothFilter.outputImage;
    curSegmentationMask = [curSegmentationMask resizeWithSize:CGSizeMake(curImage.extent.size.width, curImage.extent.size.height)];
    curSegmentationMask = [curSegmentationMask imageByApplyingFilter:@"CIMaskToAlpha"];
    return  curSegmentationMask;
}

+(CIImage *) getCIImageFromHuaweiModel{
    MLImageSegmentationSetting *setting = [[MLImageSegmentationSetting alloc] init];
    setting.exact = YES;
    setting.analyzerType = MLImageSegmentationAnalyzerTypeImage;
    setting.scene = MLImageSegmentationSceneAll;
    MLFrame *mlFrame = [[MLFrame alloc] initWithImage:globalImage];
    setting= nil;
    MLImageSegmentation *segmentation;
    segmentation =  [MLImageSegmentationAnalyzer.sharedInstance analyseFrame:mlFrame];
    curSegmentationMask = [CIImage imageWithCGImage:[segmentation.getForeground CGImage]];
    return curSegmentationMask;
}


//- (UIBezierPath *)segmentedImagePathFromImage:(UIImage *)image {
//    MLImageSegmentation *segmentation = [MLImageSegmentation init];
//    MLImageSegmentationSetting *settings = [[MLImageSegmentationSetting alloc] init];
//    segmentation.configuration = settings;
//
//    CVPixelBufferRef pixelBuffer = [image pixelBufferWithWidth:224 height:224];
//    if (pixelBuffer == NULL) {
//        return nil;
//    }
//
//    NSError *error = nil;
//    MLImageSegmentationResult *segmentationResult = [segmentation predictionFromImage:pixelBuffer error:&error];
//    if (error || segmentationResult == nil) {
//        return nil;
//    }
//
//    MLMultiArray *mask = segmentationResult.semanticPredictions;
//
//    int width = (int)CVPixelBufferGetWidth(pixelBuffer);
//    int height = (int)CVPixelBufferGetHeight(pixelBuffer);
//    UInt8 *rawData = (UInt8 *)mask.dataPointer;
//    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceGray();
//    CGContextRef context = CGBitmapContextCreate(rawData, width, height, 8, mask.strides[0].intValue, colorSpace, kCGImageAlphaNone);
//    CGImageRef imageRef = CGBitmapContextCreateImage(context);
//
//    UIBezierPath *path = [UIBezierPath bezierPath];
//    for (int y = 0; y < height; y++) {
//        for (int x = 0; x < width; x++) {
//            float value = ((float)rawData[y * width + x]) / 255.0;
//            if (value > 0.5) {
//                CGPoint point = CGPointMake(x, y);
//                if (path.isEmpty) {
//                    [path moveToPoint:point];
//                } else {
//                    [path addLineToPoint:point];
//                }
//            }
//        }
//    }
//
//    return path;
//}



+ (CVPixelBufferRef)pixelBufferWithSize:(CGSize)size :(CIImage*)sampleImage {
    @autoreleasepool {
        CIImage *image = [self resizeWithSize:size :sampleImage];
        // Due to the way [CIContext:render:toCVPixelBuffer] works, we need to translate the image so the cropped section is at the origin
        image = [image imageByApplyingTransform:CGAffineTransformMakeTranslation(-image.extent.origin.x, -image.extent.origin.y)];
        
        CVPixelBufferRef output = NULL;
        CVPixelBufferCreate(nil,
                            CGRectGetWidth(image.extent),
                            CGRectGetHeight(image.extent),
                            kCVPixelFormatType_32ARGB,
                            nil,
                            &output);
        
        if (output != NULL) {
            CIContext *context = [CIContext contextWithOptions:nil];
            [context render:image toCVPixelBuffer:output];
            context = nil;
        }
        
        return output;
    }
}

+ (CIImage *)resizeWithSize:(CGSize)size :(CIImage*)sampleImage {
    @autoreleasepool {
        CGFloat scaleX = size.width / CGRectGetWidth(sampleImage.extent);
        CGFloat scaleY = size.height / CGRectGetHeight(sampleImage.extent);
        
        CIImage *output = [sampleImage imageByApplyingTransform:CGAffineTransformMakeScale(scaleX, scaleY)];
        return output;
    }
}

+(BOOL) imageFound:(CIImage *)originalCIImage {

    // raw image reference
    context = [CIContext contextWithOptions:nil];
    CGImageRef rawImage = [context createCGImage:originalCIImage fromRect:[originalCIImage extent]];

    // components of replacement color – in a 255 UInt8 format (fairly standard bitmap format)
    const CGFloat* colorComponents = CGColorGetComponents([UIColor colorWithRed:1 green:0 blue:0 alpha:1].CGColor);
    UInt8* color255Components = calloc(sizeof(UInt8), 4);
    for (int i = 0; i < 4; i++) color255Components[i] = (UInt8)round(colorComponents[i]*255.0);

    // image attributes
    size_t width = CGImageGetWidth(rawImage);
    size_t height = CGImageGetHeight(rawImage);
    CGRect rect = {CGPointZero, {width, height}};

    // image format
    size_t bitsPerComponent = 8;
    size_t bytesPerRow = width*4;

    // the bitmap info
    CGBitmapInfo bitmapInfo = kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big;

    // data pointer – stores an array of the pixel components. For example (r0, b0, g0, a0, r1, g1, b1, a1 .... rn, gn, bn, an)
    UInt8* data = calloc(bytesPerRow, height);

    // get new RGB color space
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();

    // create bitmap context
    CGContextRef ctx = CGBitmapContextCreate(data, width, height, bitsPerComponent, bytesPerRow, colorSpace, bitmapInfo);

    // draw image into context (populating the data array while doing so)
    CGContextDrawImage(ctx, rect, rawImage);

    //float iln2 = 1.0f/log(2.0f);
    
    BOOL found = NO;
    @autoreleasepool {
        int pixelPosition = 0;
        float row = 1;
        float column = 1;
        for(row =0 ; row<height; row++){
            for(column=0; column<width; column++){
                pixelPosition = row*width+column;
                NSInteger pixelIndex = 4*pixelPosition;
                float alphaValue = data[pixelIndex+3]/255.0f;
                if (alphaValue > 0.01f) {
                    found = YES;
                    break;
                }
            }
        }
    }

    // clean up
    free(color255Components);
    CGContextRelease(ctx);
    CGColorSpaceRelease(colorSpace);
    free(data);
    CGImageRelease(rawImage);
    context = nil;
    return found;
}




@end
