//
//  UndoRedoHandler.h
//  StickerMakerUI
//
//  Created by leo on 14/3/21.
//  Copyright © 2021 Shafiq Shovo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EraseLayer.h"
#import "EraseLayer.h"

NS_ASSUME_NONNULL_BEGIN
@protocol SMUndoRedoDelegate<NSObject>

-(void) disableButtonWithRedo:(BOOL) redo withUndo:(BOOL) undo;


@end


@interface UndoRedoHandler : NSObject
@property (nonnull,nonatomic)  NSUndoManager *undoRedoManager;
@property (nonatomic,strong) id <SMUndoRedoDelegate> delegate;
-(void) undoRecentOperation;
-(void) redoRecentOperation;
-(void) resetUndoRedoManager;
-(void) callDelegateToChangeState;
-(void) startInvocationBasedUndoWithTranslation:(CGPoint ) translation withMainLayer:(EraseLayer *)mainLayer;
-(void) startInvocationBasedUndoWithInitialFrame:(CGRect) initialFrame withMainLayer:(EraseLayer *) mainLayer;
-(void) startInvocationBasedUndoWithMainLayerMask:(EraseLayer *) mainMaskLayer withCIImage:(CIImage *) maskCIImage;
-(void) startInvocationBasedInvertWithMainLayerMask:(EraseLayer *)mainMaskLayer withCIImage:(CIImage *) currentCIImage;


@end

NS_ASSUME_NONNULL_END
