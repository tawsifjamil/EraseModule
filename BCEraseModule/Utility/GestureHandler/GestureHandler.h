//
//  GestureHandler.h
//  StickerMakerUI
//
//  Created by leo on 14/3/21.
//  Copyright © 2021 Shafiq Shovo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "UndoRedoHandler.h"
#import "EraseLayer.h"
NS_ASSUME_NONNULL_BEGIN

@interface GestureHandler : NSObject
- (void) handlePanGesture:(UIPanGestureRecognizer*) gesture withMainLayer:(EraseLayer *) mainLayer withMagnifyingLayer:(CALayer *) magnifyingLayer withUndoRedoHandler:(UndoRedoHandler *) undoRedoHandler;
- (void)handlePinchGesture:(UIPinchGestureRecognizer *) gestureRecognizer  withMainLayer:(EraseLayer *) mainLayer withMagnifyingLayer:(CALayer *) magnifyingLayer
    withUndoRedoHandler:(UndoRedoHandler *) undoRedoHandler;
@end

NS_ASSUME_NONNULL_END
