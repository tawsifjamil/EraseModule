//
//  DrawingHandler.h
//  EraserBCLBackgroundEraserObj
//
//  Created by BCL Device 3 on 11/1/23.
//


#import <Foundation/Foundation.h>
#import "EraseLayer.h"

NS_ASSUME_NONNULL_BEGIN

@interface DrawingHandler : NSObject

-(void) drawInEraseLayerAndWhiteMaskLayerWithMainLayerMask:(EraseLayer *) mainLayerMask withPathArray:(CGPoint *) pathArray withCurrentDrawingState:(BOOL) drawingState drawingStatewithLineWidth:(CGFloat)lineWidth;

- (void)drawCircleInView:(UIImageView *)imageView size:(CGFloat)size position:(CGPoint)position;

@end

NS_ASSUME_NONNULL_END
