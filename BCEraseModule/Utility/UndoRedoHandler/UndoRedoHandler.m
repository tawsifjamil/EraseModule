//
//  UndoRedoHandler.m
//  StickerMakerUI
//
//  Created by leo on 14/3/21.
//  Copyright © 2021 Shafiq Shovo. All rights reserved.
//

#import "UndoRedoHandler.h"

@implementation UndoRedoHandler{
    CIContext *context;
}
- (id)init {
    self = [super init];
    if (self) {
        self.undoRedoManager = [[NSUndoManager alloc] init];
    }
    return self;
}

#pragma mark - Undo Redo Operation with PanGesture
-(void) undoOperationForGestureWithtransLationPoint:(CGPoint) translation
                                      withMainLayer:(EraseLayer *)mainLayer {
    if([self.undoRedoManager isUndoing]){
        [[self.undoRedoManager prepareWithInvocationTarget:self] redoOperationForGestureWithTranslationPoint:translation withMainLayer:mainLayer];
    }
    
    [mainLayer setPosition:CGPointMake(mainLayer.position.x-translation.x,mainLayer.position.y-translation.y)];
}

-(void) redoOperationForGestureWithTranslationPoint:(CGPoint) translation
                                      withMainLayer:(EraseLayer *)mainLayer {

    if([self.undoRedoManager isRedoing]){
        [[self.undoRedoManager prepareWithInvocationTarget:self] undoOperationForGestureWithtransLationPoint:translation withMainLayer:mainLayer];
    }
    [mainLayer setPosition:CGPointMake(mainLayer.position.x+translation.x,mainLayer.position.y+translation.y)];
}

-(void) startInvocationBasedUndoWithTranslation:(CGPoint ) translation
                                  withMainLayer:(EraseLayer *)mainLayer {
    [[self.undoRedoManager prepareWithInvocationTarget:self] undoOperationForGestureWithtransLationPoint:translation withMainLayer:mainLayer];
    [self callDelegateToChangeState];
}


#pragma mark - Undo Redo Operation with PinchGesture
-(void) redoOperationForGestureWithInitialFrame:(CGRect) initialFrame
                                  withMainLayer:(EraseLayer *)mainLayer {
    CGRect currentFrame = mainLayer.frame;
    if([self.undoRedoManager isRedoing]){
        [[self.undoRedoManager prepareWithInvocationTarget:self] undoOperationForGestureWithInitialFrame:currentFrame withMainLayer:mainLayer];
    }
    CATransform3D trans = mainLayer.transform;
    trans=CATransform3DScale(trans, initialFrame.size.width/currentFrame.size.width, initialFrame.size.height/currentFrame.size.height, 1);
    mainLayer.transform =trans; //holding layer's transformation is changed here.
}


-(void) undoOperationForGestureWithInitialFrame:(CGRect) initialFrame
                                  withMainLayer:(EraseLayer *)mainLayer {
    CGRect currentFrame = mainLayer.frame;
    if([self.undoRedoManager isUndoing]){
        [[self.undoRedoManager prepareWithInvocationTarget:self] redoOperationForGestureWithInitialFrame:currentFrame withMainLayer:mainLayer];
    }
    CATransform3D trans = mainLayer.transform;
    trans=CATransform3DScale(trans, initialFrame.size.width/currentFrame.size.width, initialFrame.size.height/currentFrame.size.height, 1);
    mainLayer.transform =trans; //holding layer's transformation is changed here.
}

-(void) startInvocationBasedUndoWithInitialFrame:(CGRect) initialFrame
                                   withMainLayer:(EraseLayer *) mainLayer {
    [[self.undoRedoManager prepareWithInvocationTarget:self] undoOperationForGestureWithInitialFrame:initialFrame withMainLayer:mainLayer];
    [self callDelegateToChangeState];
}

#pragma mark - Undo Redo Operation with Drawing
-(void) redoDrawWithMainMaskLayer:(EraseLayer *) mainMaskLayer withCIImage:(CIImage *) maskCIImage{
    CIImage *undoCIImage  = [CIImage imageWithCGImage:mainMaskLayer.imageref];
    if([self.undoRedoManager isRedoing]){
    [[self.undoRedoManager prepareWithInvocationTarget:self] undoDrawWithMainMaskLayer:mainMaskLayer withCIImage:undoCIImage];
    }
    context = [CIContext contextWithOptions:nil];
    CGImageRef mainImageRef = [context createCGImage:maskCIImage fromRect:maskCIImage.extent];
    mainMaskLayer.imageref = mainImageRef;
    [mainMaskLayer setNeedsDisplay];
    
}



-(void) undoDrawWithMainMaskLayer:(EraseLayer *) mainMaskLayer withCIImage:(CIImage *) maskCIImage{
    CIImage *undoCIImage  = [CIImage imageWithCGImage:mainMaskLayer.imageref];
    if([self.undoRedoManager isUndoing]){
    [[self.undoRedoManager prepareWithInvocationTarget:self] redoDrawWithMainMaskLayer:mainMaskLayer withCIImage:undoCIImage];
    }
    context = [CIContext contextWithOptions:nil];
    CGImageRef mainImageRef = [context createCGImage:maskCIImage fromRect:maskCIImage.extent];
    mainMaskLayer.imageref = mainImageRef;
    [mainMaskLayer setNeedsDisplay];
}

-(void) startInvocationBasedUndoWithMainLayerMask:(EraseLayer *) mainMaskLayer
                          withCIImage:(CIImage *) maskCIImage{
    [[self.undoRedoManager prepareWithInvocationTarget:self] undoDrawWithMainMaskLayer:mainMaskLayer withCIImage:maskCIImage];
    [self callDelegateToChangeState];
}

#pragma mark - Undo Redo Operation for invert
-(void) redoInvertWithMainLayerMask:(EraseLayer *)mainMaskLayer withcurrentImage:(CIImage*) currentmaskImage{
    CIFilter *inputImageFilter = [CIFilter filterWithName:@"CIConstantColorGenerator" withInputParameters:@{
        kCIInputColorKey:CIColor.whiteColor
    }];
    CIImage *inputImage = [inputImageFilter.outputImage imageByCroppingToRect:currentmaskImage.extent];
    
    CIFilter *backGroundImageFilter = [CIFilter filterWithName:@"CIConstantColorGenerator" withInputParameters:@{
        kCIInputColorKey:CIColor.blackColor
    }];
    CIImage *backGroundImage = [backGroundImageFilter.outputImage imageByCroppingToRect:currentmaskImage.extent];
    
    
    CIFilter *filter = [CIFilter filterWithName:@"CIBlendWithAlphaMask"];
    [filter setValue:inputImage forKey:@"inputImage"];
    [filter setValue:backGroundImage forKey:@"inputBackgroundImage"];
    [filter setValue:currentmaskImage forKey:@"inputMaskImage"];
    currentmaskImage =[filter.outputImage imageByCroppingToRect:currentmaskImage.extent];
    
    //Image for WhiteMaskLayer
    CIImage *imageForWhiteMaskLayer = currentmaskImage;
    currentmaskImage = [currentmaskImage imageByApplyingFilter:@"CIColorInvert"];
    currentmaskImage = [currentmaskImage imageByApplyingFilter:@"CIMaskToAlpha"];
    
    imageForWhiteMaskLayer = [imageForWhiteMaskLayer imageByApplyingFilter:@"CIColorInvert"];
    imageForWhiteMaskLayer = [imageForWhiteMaskLayer imageByApplyingFilter:@"CIMaskToAlpha"];
    
    
    context = [CIContext contextWithOptions:nil];
    mainMaskLayer.imageref = [context createCGImage:currentmaskImage fromRect:currentmaskImage.extent];
    [mainMaskLayer setNeedsDisplay];
    
    if([self.undoRedoManager isRedoing]){
        [[self.undoRedoManager  prepareWithInvocationTarget:self] undoInvertWithMainLayerMask:mainMaskLayer withcurrentImage:currentmaskImage];
    }
    
    
}
-(void) undoInvertWithMainLayerMask:(EraseLayer *)mainMaskLayer withcurrentImage:(CIImage*) currentmaskImage{
    CIFilter *inputImageFilter = [CIFilter filterWithName:@"CIConstantColorGenerator" withInputParameters:@{
        kCIInputColorKey:CIColor.whiteColor
    }];
    CIImage *inputImage = [inputImageFilter.outputImage imageByCroppingToRect:currentmaskImage.extent];
    
    CIFilter *backGroundImageFilter = [CIFilter filterWithName:@"CIConstantColorGenerator" withInputParameters:@{
        kCIInputColorKey:CIColor.blackColor
    }];
    CIImage *backGroundImage = [backGroundImageFilter.outputImage imageByCroppingToRect:currentmaskImage.extent];
    
    
    CIFilter *filter = [CIFilter filterWithName:@"CIBlendWithAlphaMask"];
    [filter setValue:inputImage forKey:@"inputImage"];
    [filter setValue:backGroundImage forKey:@"inputBackgroundImage"];
    [filter setValue:currentmaskImage forKey:@"inputMaskImage"];
    currentmaskImage =[filter.outputImage imageByCroppingToRect:currentmaskImage.extent];
    
    //Image for WhiteMaskLayer
    CIImage *imageForWhiteMaskLayer = currentmaskImage;
    currentmaskImage = [currentmaskImage imageByApplyingFilter:@"CIColorInvert"];
    currentmaskImage = [currentmaskImage imageByApplyingFilter:@"CIMaskToAlpha"];
    
    imageForWhiteMaskLayer = [imageForWhiteMaskLayer imageByApplyingFilter:@"CIColorInvert"];
    imageForWhiteMaskLayer = [imageForWhiteMaskLayer imageByApplyingFilter:@"CIMaskToAlpha"];
    
    
    context = [CIContext contextWithOptions:nil];
    mainMaskLayer.imageref = [context createCGImage:currentmaskImage fromRect:currentmaskImage.extent];
    [mainMaskLayer setNeedsDisplay];
    
    if([self.undoRedoManager isUndoing]){
        [[self.undoRedoManager prepareWithInvocationTarget:self] redoInvertWithMainLayerMask:mainMaskLayer withcurrentImage:currentmaskImage];
    }
    
}

-(void) startInvocationBasedInvertWithMainLayerMask:(EraseLayer *)mainMaskLayer withCIImage:(nonnull CIImage *)currentCIImage{
    [[self.undoRedoManager prepareWithInvocationTarget:self] undoInvertWithMainLayerMask:mainMaskLayer withcurrentImage:currentCIImage];
    [self callDelegateToChangeState];
}


#pragma mark - Maintaining Redo Undo Button
-(void) callDelegateToChangeState{
    [self.delegate disableButtonWithRedo:[self.undoRedoManager canRedo] withUndo:[self.undoRedoManager canUndo]];
}

-(void) undoRecentOperation{
    if([self.undoRedoManager canUndo]){
        [self.undoRedoManager undo];
    }
    [self callDelegateToChangeState];
}

-(void) redoRecentOperation{
    if([self.undoRedoManager canRedo]){
        [self.undoRedoManager redo];
    }
    [self callDelegateToChangeState];
}

-(void) resetUndoRedoManager{
    [self.undoRedoManager removeAllActions];
    [self callDelegateToChangeState];
}

-(BOOL) canUndo{
    return [self.undoRedoManager canUndo];
}

-(BOOL) canRedo{
    return [self.undoRedoManager canRedo];
}
@end
