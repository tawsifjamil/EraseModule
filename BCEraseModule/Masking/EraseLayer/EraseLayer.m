//
//  EraseLayer.m
//  EraserBCLBackgroundEraserObj
//
//  Created by BCL Device 3 on 11/1/23.
//

#import <QuartzCore/QuartzCore.h>
#import "EraseLayer.h"
#import <UIKit/UIKit.h>
@implementation EraseLayer

#pragma mark - Layer Initialization
-(instancetype) init{
    self=[super init];
    return self;
}

- (instancetype) initWithFrame:(CGRect) frame{
    self = [super init];
    self.frame = frame;
    self.height = frame.size.height;
    self.width = frame.size.width;
    self.contentsScale = 2.0;
    return self;
}

#pragma mark - Bezierpath Initialization
- (UIBezierPath *)drawingPath
{
    if ( !_drawingPath ){
        _drawingPath = [UIBezierPath new];
//        _drawingPath.lineWidth = 20;
        [_drawingPath setLineCapStyle:kCGLineCapRound];
        [_drawingPath setLineJoinStyle:kCGLineJoinRound];
    }
    return( _drawingPath );
}

#pragma mark - DrawInContext Implementation
- (void)drawInContext:(CGContextRef)ctx
{
    UIGraphicsPushContext( ctx);
    CGContextSetStrokeColorWithColor(ctx,[UIColor whiteColor].CGColor);
    CGContextSetShouldAntialias(ctx, YES);
    CGContextSetAllowsAntialiasing(ctx, YES);
    CGContextSetInterpolationQuality(ctx, kCGInterpolationHigh);
    CGFloat value=0;
    if (_imageref!=nil) {
        CGContextTranslateCTM(ctx, 0, self.height);
        CGContextScaleCTM(ctx, 1.0, -1.0);
        CGContextDrawImage(ctx,CGRectMake(0, 0, self.width, self.height), _imageref);
        CGContextTranslateCTM(ctx, 0, self.height);
        CGContextScaleCTM(ctx, 1.0, -1.0);
    }
    else{
        [[UIColor whiteColor] set];
        CGContextFillRect( ctx, self.bounds );
    }
    
    if(_segmentationFlag){
        if(!_segFlag) {
            if(!_hardBrush)  {
                value=self.drawingPath.lineWidth/4;
                CGContextSetShadowWithColor(ctx, CGSizeMake(0.f, 0.f), value, [UIColor blackColor].CGColor);
            }
            CGContextSetStrokeColorWithColor(ctx,[UIColor blackColor].CGColor);
            CGContextSetBlendMode( ctx,kCGBlendModeNormal);
        }
        else{
            if(!_hardBrush)  {
                value=self.drawingPath.lineWidth/4;
                CGContextSetShadowWithColor(ctx, CGSizeMake(0.f, 0.f), value, [UIColor blackColor].CGColor);
                
            }
            CGContextSetBlendMode( ctx, kCGBlendModeClear);
        }
        
    }
    else{
        
        
        if(_flag){
            if(!_hardBrush)  {
                value=_drawingPath.lineWidth/3;
                CGContextSetShadow(ctx, CGSizeMake(0.0f, 0.0f),value);
                CGContextSetStrokeColor(ctx, CGColorGetComponents([UIColor colorWithRed:255.0f green:255.0f blue:255.0f alpha:0.0].CGColor));
                CGContextSetBlendMode( ctx, kCGBlendModeClear);
            }
            else{
                CGContextSetBlendMode( ctx,  kCGBlendModeClear);
            }
        }
        else{
            if(!_hardBrush){
                value=self.drawingPath.lineWidth/4;
                CGContextSetShadowWithColor(ctx, CGSizeMake(0.f, 0.f), value, [UIColor whiteColor].CGColor);
            }
            CGContextSetBlendMode( ctx, kCGBlendModeNormal);
        }
    }
    
    if( ![ self.drawingPath isEmpty ] ){
        CGContextAddPath(ctx, [self.drawingPath CGPath]);
        CGContextSetLineWidth(ctx, self.drawingPath.lineWidth-value);
        CGContextSetLineCap(ctx,   kCGLineCapRound);
        CGContextStrokePath(ctx);
        [self.drawingPath removeAllPoints];
    }
    
    
    CGImageRelease(_imageref);
    _imageref = CGBitmapContextCreateImage(ctx);
    UIGraphicsPopContext();
}

- (void)dealloc{
    CGImageRelease(_imageref);
}

@end
