//
//  UIImage+image.m
//  EraserBCLBackgroundEraserObj
//
//  Created by BCL Device 3 on 11/1/23.
//

#import "UIImage+image.h"

#define SCREEN_WIDTH ([[UIScreen mainScreen] bounds].size.width)
#define SCREEN_HEIGHT ([[UIScreen mainScreen] bounds].size.height)

@implementation UIImage (image)

-(UIImage *) horizontalFlip {
    UIImageOrientation flippedOrientation = UIImageOrientationUpMirrored;
    UIImage * flippedImage = [UIImage imageWithCGImage:self.CGImage scale:1.0 orientation:flippedOrientation];

    CGImageRef inImage = self.CGImage;
    CGContextRef ctx = CGBitmapContextCreate(NULL,
                                             CGImageGetWidth(inImage),
                                             CGImageGetHeight(inImage),
                                             CGImageGetBitsPerComponent(inImage),
                                             CGImageGetBytesPerRow(inImage),
                                             CGImageGetColorSpace(inImage),
                                             CGImageGetBitmapInfo(inImage)
                                             );
    CGRect cropRect = CGRectMake(0, 0, flippedImage.size.width, flippedImage.size.height);
    CGImageRef TheOtherHalf = flippedImage.CGImage;
    CGContextDrawImage(ctx, CGRectMake(0, 0, CGImageGetWidth(inImage), CGImageGetHeight(inImage)), inImage);

    CGAffineTransform transform = CGAffineTransformMakeTranslation(flippedImage.size.width, 0.0);
    transform = CGAffineTransformScale(transform, -1.0, 1.0);
    CGContextConcatCTM(ctx, transform);

    CGContextDrawImage(ctx, cropRect, TheOtherHalf);

    CGImageRef imageRef = CGBitmapContextCreateImage(ctx);
    CGContextRelease(ctx);
    UIImage *finalImage = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    CGImageRelease(inImage);
    CGImageRelease(TheOtherHalf);

    return finalImage;
}

-(UIImage *)  verticalFlip {
    UIImageView *tempImageView = [[UIImageView alloc] initWithImage:self];

    UIGraphicsBeginImageContext(tempImageView.frame.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGAffineTransform flipVertical = CGAffineTransformMake(
            1, 0, 0, -1, 0, tempImageView.frame.size.height
    );
    CGContextConcatCTM(context, flipVertical);

    [tempImageView.layer renderInContext:context];

    UIImage *flipedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return flipedImage;
}

- (UIImage *) rotatedImage:(UIImage *) image rotation: (CGFloat) rotation
{
    // Calculate Destination Size
    CGAffineTransform t = CGAffineTransformMakeRotation(rotation);
    CGRect sizeRect = (CGRect) {.size = image.size};
    CGRect destRect = CGRectApplyAffineTransform(sizeRect, t);
    CGSize destinationSize = destRect.size;
    
    // Draw image
    UIGraphicsBeginImageContext(destinationSize);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextTranslateCTM(context, destinationSize.width / 2.0f, destinationSize.height / 2.0f);
    CGContextRotateCTM(context, rotation);
    [image drawInRect:CGRectMake(-image.size.width / 2.0f, -image.size.height / 2.0f, image.size.width, image.size.height)];
    
    // Save image
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

CGFloat DegreesToRadians(CGFloat degrees)
{
    return degrees * M_PI / 180;
};

CGFloat RadiansToDegrees(CGFloat radians)
{
    return radians * 180 / M_PI;
};


- (UIImage*) flipImageV:(UIImage*)img{
    UIImage *image = img;
    
    switch (img.imageOrientation) {
        case UIImageOrientationUp:
        {
            image = [UIImage imageWithCGImage:img.CGImage scale:img.scale orientation:UIImageOrientationDownMirrored];
            break;
        }
        case UIImageOrientationDown:
        {
            image = [UIImage imageWithCGImage:img.CGImage scale:img.scale orientation:UIImageOrientationUpMirrored];
            break;
        }
        case UIImageOrientationDownMirrored:
        {
            image = [UIImage imageWithCGImage:img.CGImage scale:img.scale orientation:UIImageOrientationUp];
            break;
        }
        case UIImageOrientationUpMirrored:
        {
            image = [UIImage imageWithCGImage:img.CGImage scale:img.scale orientation:UIImageOrientationDown];
            break;
        }
        default:
            break;
    }
    return image;
}



- (UIImage*) flipImageH:(UIImage*)img{
    NSLog(@"Horizontal issue %ld",img.imageOrientation);
    
    
    UIImage *image = img;
    
    switch (img.imageOrientation) {
        case UIImageOrientationUp:
        {
            image = [UIImage imageWithCGImage:img.CGImage scale:img.scale orientation:UIImageOrientationUpMirrored];
            break;
        }
        case UIImageOrientationUpMirrored:
        {
            image = [UIImage imageWithCGImage:img.CGImage scale:img.scale orientation:UIImageOrientationUp];
            break;
        }
        case UIImageOrientationDown:
        {
            image = [UIImage imageWithCGImage:img.CGImage scale:img.scale orientation:UIImageOrientationDownMirrored];
            break;
        }
        case UIImageOrientationDownMirrored:
        {
            image = [UIImage imageWithCGImage:img.CGImage scale:img.scale orientation:UIImageOrientationDown];
            break;
        }

        default:
            break;
    }
    return image;
}

#pragma mark - Trimming Image for getting the rect
+ (CGRect) trimImageforRect:(CGImageRef) imageRefForShape{
    
    // raw image reference
    CGImageRef rawImage = imageRefForShape;
    
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
    
    float topTrim = 0;
    float bottomTrim = 0;
    float leftTrim = 0;
    float rightTrim = 0;
    
    @autoreleasepool {
        
        int pixelPosition = 0;
        
        //
        
        float row = 1;
        float column = 1;
        BOOL found = NO;
        while (row < height) {
            while (column < width) {
                pixelPosition = row*width+column;
                NSInteger pixelIndex = 4*pixelPosition;
                float alphaValue = data[pixelIndex+3]/255.0f;
                if (alphaValue < 0.01f) {
                    found = YES;
                    break;
                }
                column++;
            }
            if (found) {
                break;
            }
            column = 1;
            row++;
        }
        topTrim = row;
        
        //
        
        row = height-1;
        column = 1;
        found = NO;
        while (row > 0) {
            while (column < width) {
                pixelPosition = row*width+column;
                NSInteger pixelIndex = 4*pixelPosition;
                float alphaValue = data[pixelIndex+3]/255.0f;
                if (alphaValue < 0.01f) {
                    found = YES;
                    break;
                }
                column++;
            }
            if (found) {
                break;
            }
            column = 1;
            row--;
        }
        bottomTrim = row;
        
        //
        row = 1;
        column = 1;
        found = NO;
        while (column < width) {
            while (row < height) {
                pixelPosition = row*width+column;
                NSInteger pixelIndex = 4*pixelPosition;
                float alphaValue = data[pixelIndex+3]/255.0f;
                if (alphaValue < 0.01f) {
                    found = YES;
                    break;
                }
                row++;
            }
            if (found) {
                break;
            }
            row = 1;
            column++;
        }
        leftTrim = column;
        
        //
        
        row = 1;
        column = width-1;
        found = NO;
        while (column > 0) {
            while (row < height) {
                pixelPosition = row*width+column;
                NSInteger pixelIndex = 4*pixelPosition;
                float alphaValue = data[pixelIndex+3]/255.0f;
                if (alphaValue < 0.01f) {
                    found = YES;
                    break;
                }
                row++;
            }
            if (found) {
                break;
            }
            row = 1;
            column--;
        }
        rightTrim = column;
        
    }
    // clean up
    free(color255Components);
    CGContextRelease(ctx);
    CGColorSpaceRelease(colorSpace);
    free(data);
    float trimWidth = rightTrim-leftTrim;
    float trimHeight = bottomTrim-topTrim;
    return  CGRectMake(leftTrim, topTrim, trimWidth, trimHeight);
}

#pragma mark- Trimming the Image
+ (UIImage *)trimImage: (CGImageRef) imageRefForShape{
    UIImage *originalImage = [UIImage imageWithCGImage:imageRefForShape];
    // raw image reference
    CGImageRef rawImage = imageRefForShape;

    CGFloat width = CGImageGetWidth(rawImage);
    CGFloat height = CGImageGetHeight(rawImage);
    CGRect trimRect = [self trimImageforRect:imageRefForShape];
    CGFloat topTrim = trimRect.origin.y;
    CGFloat leftTrim = trimRect.origin.x;
    float trimWidth = trimRect.size.width;
    float trimHeight = trimRect.size.height;
    UIView *trimCanvas = [[UIView alloc] initWithFrame:CGRectMake(0, 0, trimWidth, trimHeight)];
    trimCanvas.backgroundColor = [UIColor clearColor];
    
    UIImageView *trimImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, width, height)];
    trimImageView.image = originalImage;
    trimImageView.contentMode = UIViewContentModeScaleToFill;
    trimImageView.backgroundColor = [UIColor clearColor];
    
    [trimCanvas addSubview:trimImageView];
    
    trimImageView.center = CGPointMake(trimImageView.center.x-leftTrim, trimImageView.center.y-topTrim);

    CGRect __rect = [trimCanvas bounds];
    UIGraphicsBeginImageContextWithOptions(__rect.size, (NO), (originalImage.scale));
    CGContextRef __context = UIGraphicsGetCurrentContext();
    [trimCanvas.layer renderInContext:__context];
    UIImage *__image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return __image;

}

+ (void)saveImageToDirectory:(PHAsset *)asset withName:(NSString *)name withCompletionHandler:(void (^)(BOOL complete))completionHandler
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *pathForFile = NSTemporaryDirectory();
    if (![fileManager fileExistsAtPath:pathForFile]){
        NSError *error = nil;
        [fileManager createDirectoryAtPath:pathForFile withIntermediateDirectories:NO attributes:nil error:&error];
//        if(error)
//            NSLog(@"Error creating directory: %@", error.localizedDescription);
    }
    
    PHImageRequestOptions *requestOptions = [[PHImageRequestOptions alloc] init];
    requestOptions.resizeMode   = PHImageRequestOptionsResizeModeFast;
    requestOptions.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
    requestOptions.synchronous = false;
    requestOptions.networkAccessAllowed = YES;
    requestOptions.progressHandler = ^(double progress, NSError * _Nullable error, BOOL * _Nonnull stop, NSDictionary * _Nullable info) {
        dispatch_async(dispatch_get_main_queue(), ^{
            
        });
    };
    CGFloat deviceScale = [[UIScreen mainScreen] scale];
    CGSize size = CGSizeMake(SCREEN_WIDTH * deviceScale, SCREEN_WIDTH * deviceScale);
    
    PHImageManager *manager = [PHImageManager defaultManager];
//
//    [manager requestImageDataForAsset:asset options:requestOptions resultHandler:^(NSData * _Nullable imageData, NSString * _Nullable dataUTI, UIImageOrientation orientation, NSDictionary * _Nullable info) {
//        NSString *fullPath = [pathForFile stringByAppendingPathComponent:name];
//        [fileManager createFileAtPath:fullPath contents:imageData attributes:nil];
//    }];
    
    [manager requestImageForAsset:asset targetSize:size contentMode:PHImageContentModeAspectFit options:requestOptions resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
        
        if(result){
            // Saving square image
            [self saveImageWithPath:pathForFile withImage:result withSize:[self imageSize:result.size] withCompletionHandler:^(BOOL complete) {
                
            }];
            
            // Saving thumbnail image
//            CGFloat deviceScale = [[UIScreen mainScreen] scale];
            
            if(completionHandler)
                completionHandler(YES);
        }
        else{
            dispatch_async(dispatch_get_main_queue(), ^{
//                [SVProgressHUD showErrorWithStatus:@"Failed\nPlease try again."];
            });
            if(completionHandler)
                completionHandler(NO);
        }
    }];
}

+ (void)saveImageWithPath:(NSString *)path withImage:(UIImage *)image withSize:(CGSize)size withCompletionHandler:(void (^) (BOOL complete))completionHandler
{
    NSLog(@"%@", path);
    NSLog(@"Image XXXX ==scale=1=");
    if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
        [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
    }
    @autoreleasepool{
        completionHandler(CGImageWriteToFile([self getImageRefWithImage:image withSize:size], path));
    }
}

+ (CGBitmapInfo)normalizeBitmapInfo:(CGBitmapInfo)oldBitmapInfo {
    //extract the alpha info by resetting everything else
    CGImageAlphaInfo alphaInfo = oldBitmapInfo & kCGBitmapAlphaInfoMask;
    
    //Since iOS8 it's not allowed anymore to create contexts with unmultiplied Alpha info
    if (alphaInfo == kCGImageAlphaLast) {
        alphaInfo = kCGImageAlphaPremultipliedLast;
    }
    if (alphaInfo == kCGImageAlphaFirst) {
        alphaInfo = kCGImageAlphaPremultipliedFirst;
    }
    
    //reset the bits
    CGBitmapInfo newBitmapInfo = oldBitmapInfo & ~kCGBitmapAlphaInfoMask;
    
    //set the bits to the new alphaInfo
    newBitmapInfo |= alphaInfo;
    
    return newBitmapInfo;
}

+ (CGImageRef)getImageRefWithImage:(UIImage *)image withSize:(CGSize)size
{
    int W  = size.width;
    int H  = size.height;
    int W0 = image.size.width;
    int H0 = image.size.height;
    
    CGImageRef   imageRef = image.CGImage;
    CGColorSpaceRef colorSpaceInfo = CGImageGetColorSpace(imageRef);
    CGBitmapInfo bitmapInfo = [self normalizeBitmapInfo:CGImageGetBitmapInfo(imageRef)];
    
    CGContextRef bitmap = CGBitmapContextCreate(NULL, W, H, 8, 4 * W, colorSpaceInfo, bitmapInfo);
    if (bitmap == nil) {
        UIGraphicsBeginImageContext(size);
        [image drawInRect:CGRectMake(0, 0, size.width, size.height)];
        UIImage *destImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        imageRef = destImage.CGImage;
        colorSpaceInfo = CGImageGetColorSpace(imageRef);
        bitmapInfo = [self normalizeBitmapInfo:CGImageGetBitmapInfo(imageRef)];
        bitmap = CGBitmapContextCreate(NULL, W, H, 8, 4 * W, colorSpaceInfo, bitmapInfo);
    }
    
    if(image.imageOrientation == UIImageOrientationLeft || image.imageOrientation == UIImageOrientationRight){
        W  = size.height;
        H  = size.width;
        W0 = image.size.height;
        H0 = image.size.width;
    }
    
    double ratio = MAX(W/(double)W0, H/(double)H0);
    W0 = ratio * W0;
    H0 = ratio * H0;
    
    int dW = abs((W0-W)/2);
    int dH = abs((H0-H)/2);
    
    switch (image.imageOrientation) {
        case UIImageOrientationLeft:
        {
            CGContextRotateCTM (bitmap, M_PI/2);
            CGContextTranslateCTM (bitmap, 0, -H);
            break;
        }
        case UIImageOrientationRight:
        {
            CGContextRotateCTM (bitmap, -M_PI/2);
            CGContextTranslateCTM (bitmap, -W, 0);
            break;
        }
        case UIImageOrientationUp:
        {
            break;
        }
        case UIImageOrientationDown:
        {
            CGContextTranslateCTM (bitmap, W, H);
            CGContextRotateCTM (bitmap, -M_PI);
            break;
        }
        case UIImageOrientationLeftMirrored:
        {
            CGContextTranslateCTM (bitmap, W / 2, H / 2);
            CGContextRotateCTM (bitmap, M_PI/2);
            CGContextScaleCTM(bitmap, -1, 1);
            CGContextTranslateCTM (bitmap, -W / 2, -H / 2);
            break;
        }
        case UIImageOrientationRightMirrored:
        {
            CGContextTranslateCTM (bitmap, W / 2, H / 2);
            CGContextRotateCTM (bitmap, -M_PI/2);
            CGContextScaleCTM(bitmap, -1, 1);
            CGContextTranslateCTM (bitmap, -W / 2, -H / 2);
            break;
        }
        case UIImageOrientationUpMirrored:
        {
            CGContextTranslateCTM (bitmap, W / 2, H / 2);
            CGContextScaleCTM(bitmap, -1, 1);
            CGContextTranslateCTM (bitmap, -W / 2, -H / 2);
            break;
        }
        case UIImageOrientationDownMirrored:
        {
            CGContextTranslateCTM (bitmap, W / 2, H / 2);
            CGContextScaleCTM(bitmap, 1, -1);
            CGContextTranslateCTM (bitmap, -W / 2, -H / 2);
            break;
        }

        default:
            break;
    }
    
    CGRect finalRect = CGRectMake(-dW, -dH, W0, H0);
    CGContextDrawImage(bitmap, finalRect, imageRef);
    CGImageRef ref = CGBitmapContextCreateImage(bitmap);
    
    CGContextRelease(bitmap);
    return ref;
}

BOOL CGImageWriteToFile(CGImageRef image, NSString *path)
{
    CFURLRef url = (__bridge CFURLRef)[NSURL fileURLWithPath:path];
    CGImageDestinationRef destination = CGImageDestinationCreateWithURL(url, kUTTypePNG, 1, NULL);
    if (!destination) {
        NSLog(@"Failed to create CGImageDestination for %@", path);
        CGImageRelease(image);
        return NO;
    }
    
    CGImageDestinationAddImage(destination, image, nil);
    if (!CGImageDestinationFinalize(destination))
    {
        NSLog(@"Failed to write image to %@", path);
        
        CFRelease(destination);
        CGImageRelease(image);
        
        return NO;
    }
    
    CFRelease(destination);
    CGImageRelease(image);
    NSLog(@"Image saved at: %@", path);
    return YES;
}

+ (CGSize)imageSize:(CGSize)size{
    CGFloat m = [[NSByteCountFormatter stringFromByteCount:[NSProcessInfo processInfo].physicalMemory countStyle:NSByteCountFormatterCountStyleFile] doubleValue];
    CGSize tmsize;
    CGFloat aspect = size.width / size.height;
    if (m >= 2.8f) {
        tmsize = CGSizeMake(960 * (aspect < 1? aspect :1), 960 / (aspect > 1? aspect :1));
    }else if (m >= 1.8f){
        tmsize = CGSizeMake(840 * (aspect < 1? aspect :1), 840 / (aspect > 1? aspect :1));
    }else{
        tmsize = CGSizeMake(720 * (aspect < 1? aspect :1), 720 / (aspect > 1? aspect :1));
    }
    return [self absoluteSize:tmsize aspect:aspect];
    
}

+ (CGSize)absoluteSize:(CGSize)size aspect:(CGFloat)aspect{
    if (fmod(size.width, 1.0) > 0.5) {
        return CGSizeMake(ceill(size.width), ceill(size.height));
    }
    return CGSizeMake(floorl(size.width), floorl(size.height));
}

- (BOOL) saveImageAtPath:(NSString*)path{
    return [UIImagePNGRepresentation(self) writeToFile:path atomically:YES];
}

+ (CGRect) imageSizeAfterAspectFit:(CGSize) size withOriginalImage:(UIImage *) image withOffsetValue:(CGSize) offsetValue{
    float newwidth,newheight;
    float changedWidth = size.width - offsetValue.width;
    float changedHeight = size.height - offsetValue.height;
    
    
    if (image.size.height>=image.size.width){
        newheight=changedHeight;
        newwidth=(image.size.width/image.size.height)*newheight;
        if(newwidth>changedWidth){
            newheight=changedWidth * (image.size.height/image.size.width);
            newwidth=changedWidth;
        }
        
    }
    else{
        newwidth=changedWidth;
        newheight=(image.size.height/image.size.width)*newwidth;
        if(newheight>changedHeight){
            float diff=changedHeight-newheight;
            newwidth=newwidth+diff/newwidth*newheight;
            newheight=changedHeight;
        }
    }
    
    CGFloat changedX= ((size.width-newwidth))/2.0;
    CGFloat changedY= ((size.height-newheight))/2.0;
    
    return CGRectMake(lroundf(changedX), lroundf(changedY), lroundf(newwidth), lroundf(newheight));
}

#pragma mark - Resizing image
+ (UIImage *)imageWithImage:(UIImage *)image AspectFitToSize:(CGSize)size {
    float newwidth,newheight;
    UIImage *sampleImage= image;
    if (sampleImage.size.height>=sampleImage.size.width){
        newheight=size.height;
        newwidth=(sampleImage.size.width/sampleImage.size.height)*newheight;
        
        if(newwidth>size.width){
            float diff=size.width-newwidth;
            newheight=newheight+diff/newheight*newheight;
            newwidth=size.width;
        }
    }
    else{
        newwidth=size.width;
        newheight=(sampleImage.size.height/sampleImage.size.width)*newwidth;
        
        if(newheight>size.height){
            float diff=size.height-newheight;
            newwidth=newwidth+diff/newwidth*newwidth;
            newheight=size.height;
        }
    }
  
    size = CGSizeMake(newwidth, newheight);
    UIGraphicsBeginImageContext(size);
    [image drawInRect:CGRectMake(0, 0, size.width, size.height)];
    UIImage *destImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return destImage;
    
}

+ (UIImage *) convertToiMessageSpecifiedSizeWithImage:(UIImage *)image{
    image = [UIImage imageWithImage:image AspectFitToSize:CGSizeMake(408, 408)];
    image = [UIImage convertToiMessageFormatWithImage:image];
    return  image;
}



#pragma mark - Resizing image
+ (UIImage *)convertToiMessageFormatWithImage:(UIImage *)image{
    CGFloat remainingWidth = 408 - image.size.width;
    CGFloat remainingHeight = 408 -  image.size.height;
    CIImage *inputImage = [CIImage imageWithCGImage:[image CGImage]];
    CIContext *context = [CIContext contextWithOptions:nil];
    CGImageRef km = [context createCGImage:inputImage fromRect:CGRectMake(-remainingWidth/2, -remainingHeight/2, inputImage.extent.size.width + remainingWidth, inputImage.extent.size.height + remainingHeight)];
    context = nil;
    UIImage *destImage = [UIImage imageWithCGImage:km];
    CGImageRelease(km);
    return destImage;
}

+ (UIImage *) convertToWhatsAppSpecifiedSizeWithImage:(UIImage *)image{
    image = [UIImage imageWithImage:image AspectFitToSize:CGSizeMake(512, 512)];
    image = [UIImage convertToWhatsAppFormatWithImage:image];
    return  image;
}



#pragma mark - Resizing image
+ (UIImage *)convertToWhatsAppFormatWithImage:(UIImage *)image{
    CGFloat remainingWidth = 512 - image.size.width;
    CGFloat remainingHeight = 512 -  image.size.height;
    CIImage *inputImage = [CIImage imageWithCGImage:[image CGImage]];
    CIContext *context = [CIContext contextWithOptions:nil];
    CGImageRef km = [context createCGImage:inputImage fromRect:CGRectMake(-remainingWidth/2, -remainingHeight/2, inputImage.extent.size.width + remainingWidth, inputImage.extent.size.height + remainingHeight)];
    context = nil;
    UIImage *destImage = [UIImage imageWithCGImage:km];
    CGImageRelease(km);
    return destImage;
}

#pragma mark - This function created specifically for fixing Shape issue, hopefully will change this to make a generic function later.
+ (UIImage *)imageFromLayerFromShapeVC:(CALayer *)layer {
//    CGSize originalSize = [BCStickerManager sharedManager].originalImageSize;
//    CGSize ratio = CGSizeMake(originalSize.width/layer.frame.size.width, originalSize.height/layer.frame.size.height);
//    return [self imageFromLayer:layer withSize:CGSizeMake(layer.frame.size.width*MAX(ratio.width, ratio.height), layer.frame.size.height*MAX(ratio.width, ratio.height))];
    return nil;
}

#pragma mark - Image From Layer
+ (UIImage *)imageFromLayer:(CALayer *)layer size:(CGSize)size {
    CGSize ratio = CGSizeMake(size.width/layer.frame.size.width, size.height/layer.frame.size.height);
    return [self imageFromLayer:layer withSize:CGSizeMake(layer.frame.size.width*ratio.width, layer.frame.size.height*ratio.height)];
}

+ (UIImage *)imageFromLayer:(CALayer *)layer withSize:(CGSize)size
{
    UIGraphicsBeginImageContextWithOptions(layer.frame.size, layer.opaque, 0);
    [layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *outputImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return [self resizeImage:outputImage newSize:size];
}

+ (UIImage *)resizeImage:(UIImage*)image newSize:(CGSize)newSize {
    CGRect newRect = CGRectIntegral(CGRectMake(0, 0, newSize.width, newSize.height));
    CGImageRef imageRef = image.CGImage;
    
    UIGraphicsBeginImageContextWithOptions(newSize, NO, 1);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    // Set the quality level to use when rescaling
    CGContextSetInterpolationQuality(context, kCGInterpolationHigh);
    CGAffineTransform flipVertical = CGAffineTransformMake(1, 0, 0, -1, 0, newSize.height);
    
    CGContextConcatCTM(context, flipVertical);
    // Draw into the context; this scales the image
    CGContextDrawImage(context, newRect, imageRef);
    
    // Get the resized image from the context and a UIImage
    CGImageRef newImageRef = CGBitmapContextCreateImage(context);
    UIImage *newImage = [UIImage imageWithCGImage:newImageRef];
    
    CGImageRelease(newImageRef);
    UIGraphicsEndImageContext();
    
    return newImage;
}




@end
