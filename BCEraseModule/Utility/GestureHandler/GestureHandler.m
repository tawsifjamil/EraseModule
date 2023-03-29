//
//  GestureHandler.m
//  StickerMakerUI
//
//  Created by leo on 14/3/21.
//  Copyright © 2021 Shafiq Shovo. All rights reserved.
//

#import "GestureHandler.h"


@implementation GestureHandler{
    CGPoint stateBeginPoint;
    CGRect initialFrameWhenGestureBegan;
    CGFloat lastScale;
}

#pragma mark - PanGesture Handle Implementation
- (void) handlePanGesture:(UIPanGestureRecognizer*) gestureRecognizer withMainLayer:(EraseLayer *) mainLayer withMagnifyingLayer:(CALayer *) magnifyingLayer withUndoRedoHandler:(UndoRedoHandler *) undoRedoHandler{
    if (gestureRecognizer.state ==UIGestureRecognizerStateBegan){
        stateBeginPoint = CGPointMake(mainLayer.position.x, mainLayer.position.y);
    }
    CGPoint translation = [gestureRecognizer translationInView:gestureRecognizer.view];
    [CATransaction setDisableActions:YES];
    [mainLayer setPosition:CGPointMake(stateBeginPoint.x+translation.x,stateBeginPoint.y+translation.y)]; //according to the change the holding layer is changed.
    [magnifyingLayer setPosition:CGPointMake(stateBeginPoint.x+translation.x,stateBeginPoint.y+translation.y)];
    
    if(gestureRecognizer.state == UIGestureRecognizerStateEnded){
        [undoRedoHandler startInvocationBasedUndoWithTranslation:translation withMainLayer:mainLayer];
    }
}

#pragma mark - PinchGesture Handle Implementation
- (void)handlePinchGesture:(UIPinchGestureRecognizer *) gestureRecognizer  withMainLayer:(EraseLayer *) mainLayer withMagnifyingLayer:(CALayer *) magnifyingLayer
       withUndoRedoHandler:(UndoRedoHandler *) undoRedoHandler{
    if([gestureRecognizer state] ==UIGestureRecognizerStateBegan) {
        lastScale = [gestureRecognizer scale];
        initialFrameWhenGestureBegan = mainLayer.frame;
    }
    else if ([gestureRecognizer state] == UIGestureRecognizerStateChanged) {
        CGFloat currentScale = [[mainLayer valueForKeyPath:@"transform.scale"] floatValue];
        const CGFloat kMaxScale = 5.5;
        const CGFloat kMinScale = 0.75;
        CGFloat newScale = 1 -  (lastScale - [gestureRecognizer scale]); // new scale is in the range (0-1)
        newScale = MIN(newScale, kMaxScale / currentScale);
        newScale = MAX(newScale, kMinScale / currentScale);
        [CATransaction setDisableActions:YES];
        CATransform3D trans = mainLayer.transform;
        trans=CATransform3DScale(trans, newScale, newScale, 1);
        mainLayer.transform =trans; //holding layer's transformation is changed here.
        magnifyingLayer.transform = trans;
        mainLayer.magnificationFilter = kCAFilterNearest;
        magnifyingLayer.magnificationFilter = kCAFilterNearest;
        lastScale = [gestureRecognizer scale];
    }
    else if([gestureRecognizer state]==UIGestureRecognizerStateEnded){
        [undoRedoHandler startInvocationBasedUndoWithInitialFrame:initialFrameWhenGestureBegan withMainLayer:mainLayer];
    }
}





@end
