//
//  DrawingHandler.m
//  EraserBCLBackgroundEraserObj
//
//  Created by BCL Device 3 on 11/1/23.
//

#import "DrawingHandler.h"

@implementation DrawingHandler

#pragma mark - For finding the Mid point of Two Touch Point
CGPoint findMiddlePoint(CGPoint p1, CGPoint p2) {
    return CGPointMake((p1.x + p2.x)/2.0, ((p1.y + p2.y)/2.0));
}

#pragma mark - Mask layer are drawn to show erase and redraw
-(void) drawInEraseLayerAndWhiteMaskLayerWithMainLayerMask:(EraseLayer *) mainLayerMask
                                   withPathArray:(CGPoint *) pathArray withCurrentDrawingState:(BOOL) drawingState drawingStatewithLineWidth:(CGFloat)lineWidth{
    [mainLayerMask.drawingPath setLineWidth:lineWidth];
    [mainLayerMask.drawingPath moveToPoint:pathArray[0]];
    [mainLayerMask.drawingPath addQuadCurveToPoint:pathArray[3] controlPoint:pathArray[1] ];
    [mainLayerMask setNeedsDisplay];

//    [mainLayerMask.drawingPath setLineWidth:lineWidth];
//    CGPoint position;
//    position.x = pathArray[0].x - lineWidth/2;
//    position.y = pathArray[0].y - lineWidth/2;
//
//    CGPoint p1 = CGPointMake(position.x, position.y);
//    CGPoint p2 = CGPointMake(position.x, position.y + lineWidth);
//    CGPoint p3 = CGPointMake(position.x + lineWidth, position.y + lineWidth);
//    CGPoint p4 = CGPointMake(position.x + lineWidth, position.y);
//
//    [mainLayerMask.drawingPath moveToPoint:p1];
//    [mainLayerMask.drawingPath addLineToPoint:p2];
//    [mainLayerMask.drawingPath addLineToPoint:p3];
//    [mainLayerMask.drawingPath addLineToPoint:p4];
//    [mainLayerMask.drawingPath closePath];
//    [mainLayerMask setNeedsDisplay];
    
    
}

- (void)drawSquareInEraseLayerAndWhiteMaskLayerWithMainLayerMask:(EraseLayer *)mainLayerMask size:(CGFloat)size position:(CGPoint)position{
    
    position.x = position.x - size/2;
    position.y = position.y - size/2;
    CGPoint p1 = CGPointMake(position.x, position.y);
    CGPoint p2 = CGPointMake(position.x, position.y + size);
    CGPoint p3 = CGPointMake(position.x + size, position.y + size);
    CGPoint p4 = CGPointMake(position.x + size, position.y);
    
    [mainLayerMask.drawingPath moveToPoint:p1];
    [mainLayerMask.drawingPath addLineToPoint:p2];
    [mainLayerMask.drawingPath addLineToPoint:p3];
    [mainLayerMask.drawingPath addLineToPoint:p4];
    [mainLayerMask.drawingPath closePath];
    [mainLayerMask setNeedsDisplay];
}

- (void)drawCircleInView:(UIImageView *)imageView size:(CGFloat)size position:(CGPoint)position {
    NSArray *layersInView = [NSArray arrayWithArray:imageView.layer.sublayers];
    for(CALayer *layer in layersInView) {
        [layer removeFromSuperlayer];
    }
    imageView.frame = CGRectMake(position.x, position.y, size, size);
    
    UIBezierPath *circlePath = [[UIBezierPath alloc] init];
    [circlePath addArcWithCenter:CGPointMake(imageView.frame.size.width/2, imageView.frame.size.height/2) radius:size/2 startAngle:0 endAngle:M_PI * 2 clockwise:TRUE];
    
    CAShapeLayer *circleMaskLayer = [CAShapeLayer layer];
    [circleMaskLayer setPath:circlePath.CGPath];
    circleMaskLayer.fillColor = UIColor.clearColor.CGColor;
    circleMaskLayer.fillRule = kCAFillRuleEvenOdd;
    circleMaskLayer.strokeColor = UIColor.whiteColor.CGColor;
    circleMaskLayer.lineWidth = 2.0;
    [imageView.layer addSublayer:circleMaskLayer];
}

@end
