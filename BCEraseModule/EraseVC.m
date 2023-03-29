//
//  EraseVC.m
//  BCEraseModule
//
//  Created by BCL Device 3 on 14/3/23.
//

#import "EraseVC.h"
#import "UIImage+maskImage.h"
#import "UIImage+image.h"
#import "EraseLayer.h"
#import "DrawingHandler.h"
#import "UIImage+FixOrientation.h"
#import "GestureHandler.h"
#import "OutputVC.h"

#define IS_IPAD ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad)
#define IS_IPHONE (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
#define SCREEN_WIDTH ([[UIScreen mainScreen] bounds].size.width)
#define SCREEN_HEIGHT ([[UIScreen mainScreen] bounds].size.height)
#define RATIO SCREEN_WIDTH/414.0

@interface EraseVC () {
    CIImage *maskedCIImage;
    UIImage *originalImage;
    CGImageRef maskedInImageRef;
    CGImageRef maskedOutImageRef;
    
    CGRect desiredFrame;
    CGSize sizeOfCurrentLayer;
    EraseLayer  *holdingLayer, *selectedLayer, *maskingLayer;
    CALayer *bottomLayer;
    
    UIPanGestureRecognizer *panGesture, *panGestureToErase;
    UIPinchGestureRecognizer *pinchGesture;
    
    CGPoint stateBeginPoint;
    CGPoint brushInitialPoint;
    CGFloat lastScale;
    
    CGPoint lastPoint,newPoint;
    CGFloat defaultBrushWidth;
    int numberOfPoints;
    CGPoint pathArray[5];
    
    BOOL erase, restore, saveImagePressed;
    
    DrawingHandler *drawingHandler;
    UndoRedoHandler *undoRedoHandler;
    
    //brush
    UIImageView *staticBrushView;
    CGFloat staticBrushWidth;
    
    UIImage *finaleImage;
    
}

@property (weak, nonatomic) IBOutlet UIView *containerView;
@property (weak, nonatomic) IBOutlet UISlider *brushSizeSlider;
@property (weak, nonatomic) IBOutlet UISegmentedControl *segmentControll;
@property (weak, nonatomic) IBOutlet UIButton *undoBtn;
@property (weak, nonatomic) IBOutlet UIButton *redoBtn;
@property (weak, nonatomic) IBOutlet UIView *hardBrushSelected;
@property (weak, nonatomic) IBOutlet UIView *softBrushSelected;

@end

@implementation EraseVC

- (void)viewDidLoad {
    [super viewDidLoad];
    [self initializeHandler];
    [self addGesture];
    defaultBrushWidth = 8.0;
    [self.undoBtn setEnabled:NO];
    [self.redoBtn setEnabled:NO];
    _hardBrushSelected.hidden = NO;
    _softBrushSelected.hidden = YES;
    undoRedoHandler.delegate = (id)self;
    erase = YES;
    [self.view bringSubviewToFront:_segmentControll];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if(selectedLayer != nil) {
//        selectedLayer.backgroundColor = [[UIColor clearColor] colorWithAlphaComponent:0.5].CGColor;
    }
    if(!saveImagePressed) {
        [self openGallery:nil];
    }
}

-(void) initializeHandler{
    undoRedoHandler = [[UndoRedoHandler alloc] init];
    drawingHandler = [[DrawingHandler alloc] init];
}

- (void)resetAll {
    drawingHandler = [[DrawingHandler alloc] init];
    
    _brushSizeSlider.maximumValue = 50;
    _brushSizeSlider.minimumValue = defaultBrushWidth;
    _brushSizeSlider.value = ((_brushSizeSlider.maximumValue + defaultBrushWidth) / 2);
    
    [staticBrushView removeFromSuperview];
    _segmentControll.selectedSegmentIndex = 0;
    
    originalImage = nil;
    maskedCIImage = nil;
    [selectedLayer removeFromSuperlayer];
    [holdingLayer removeFromSuperlayer];;
    [maskingLayer removeFromSuperlayer];
}

#pragma mark:- Handle Gesture
- (void)addGesture {
    panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
    panGesture.maximumNumberOfTouches = 2;
    panGesture.minimumNumberOfTouches = 2;
    panGesture.delegate = (id)self;
    [self.containerView addGestureRecognizer:panGesture];
    
    pinchGesture = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(handlePinch:)];
    pinchGesture.delegate = (id)self;
    [self.containerView addGestureRecognizer:pinchGesture];
    
    panGestureToErase = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePanToErase:)];
    panGestureToErase.maximumNumberOfTouches = 1;
    panGestureToErase.minimumNumberOfTouches = 1;
    [self.containerView addGestureRecognizer:panGestureToErase];
}

- (IBAction)openGallery:(id)sender {
    UIImagePickerController *pickerView = [[UIImagePickerController alloc] init];
    pickerView.mediaTypes = @[(NSString *)kUTTypeImage];
    pickerView.delegate = (id)self;
    [self presentViewController:pickerView animated:YES completion:nil];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    [self resetAll];
    originalImage = [info[UIImagePickerControllerOriginalImage] fixOrientation];
    maskedCIImage = [UIImage getMaskImageFromOriginalImage: originalImage];
    [picker dismissViewControllerAnimated:YES completion:nil];
    [self prepareLayers];
    [self createBrushView:defaultBrushWidth + self.brushSizeSlider.value position:CGPointMake(self.containerView.frame.size.width/2, self.containerView.frame.size.height - 100)];
}

#pragma mark:- Layers & Segmentation
- (void)prepareLayers {
    CGImageRef imgRef = [originalImage CGImage];
    CGSize offsetSize;
    offsetSize = (IS_IPAD) ? CGSizeMake(110, 110) : CGSizeMake(104, 104);
    desiredFrame = [UIImage imageSizeAfterAspectFit:self.containerView.frame.size withOriginalImage:originalImage withOffsetValue:CGSizeMake(offsetSize.width*RATIO, offsetSize.width*RATIO)];
    sizeOfCurrentLayer = desiredFrame.size;
    
    //holds all the layers
    holdingLayer = [[EraseLayer layer] initWithFrame:desiredFrame];
    [self.containerView.layer addSublayer:holdingLayer];
    
    //this layer is for containing the original InputImage
    bottomLayer = [[CALayer alloc] init];
    [bottomLayer setFrame: CGRectMake(0, 0, desiredFrame.size.width, desiredFrame.size.height)];
    bottomLayer.contents = (__bridge id)(imgRef);
    [holdingLayer addSublayer:bottomLayer];
    
    //All the erase/restore done in this layer
    CIImage *img = [[CIImage alloc] initWithImage:originalImage];
    CGImageRef colorImgRef = [self redColorCGImageRed:img];
    selectedLayer = [[EraseLayer layer] initWithFrame:CGRectMake(0, 0, desiredFrame.size.width, desiredFrame.size.height)];
    selectedLayer.contents = (__bridge id)(colorImgRef);
    [holdingLayer addSublayer:selectedLayer];

    //this layer holds the segmentedImage and set the mask for selected layer
    maskingLayer = [[EraseLayer layer] initWithFrame:CGRectMake(0, 0, desiredFrame.size.width, desiredFrame.size.height)];
    selectedLayer.mask = maskingLayer;
    
    [self performSegmentation];
}

- (void)performSegmentation {
    CGImageRef imageRef = [originalImage CGImage];
    CIContext *context = [CIContext contextWithOptions:nil];
    imageRef = [context createCGImage:maskedCIImage fromRect:maskedCIImage.extent];
    maskingLayer.imageref = imageRef;
    maskingLayer.segmentationFlag = YES;
    maskingLayer.hardBrush = YES;
    maskingLayer.segFlag = YES;
    maskingLayer.opacity = 1.0;
    [maskingLayer setNeedsDisplay];
    
    context = [CIContext contextWithOptions:nil];
}

//Helper Methods
- (CGImageRef) redColorCGImageRed:(CIImage *)backgroundImage {
    CGColorRef colorRef = [[UIColor redColor] colorWithAlphaComponent:0.5].CGColor;
    NSString *colorString = [CIColor colorWithCGColor:colorRef].stringRepresentation;
    CIColor *coreColor = [CIColor colorWithString:colorString];
    CIImage *result = [CIImage imageWithColor:coreColor];
    // set the input image's extent to match the background image's extent
    result = [result imageByClampingToExtent];
    result = [result imageByCroppingToRect:backgroundImage.extent];
    CIContext *context = [CIContext contextWithOptions:nil];
    CGRect extent = [result extent];
    CGImageRef cgImage = [context createCGImage:result fromRect:extent];
    return cgImage;
}

- (UIImage *) maskTwoImage: (CIImage *)inputBackgroundImage inputImage:(CIImage *)inputImage {
    CIFilter *filter = [CIFilter filterWithName:@"CISourceInCompositing"];
    [filter setValue:inputBackgroundImage forKey:kCIInputImageKey];
    [filter setValue:inputImage forKey:@"inputBackgroundImage"];
    CIImage *result = [filter valueForKey:kCIOutputImageKey];
    UIImage *finalImage = [UIImage imageWithCIImage:result];
    return finalImage;
}

#pragma mark - Multiple Gesture Enable Simultaneously
-(BOOL) gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer
shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return YES;
}

- (void)handlePan:(UIPanGestureRecognizer *)gesture {
    if(selectedLayer != nil) {
        if (gesture.state ==UIGestureRecognizerStateBegan){
            stateBeginPoint = CGPointMake(holdingLayer.position.x, holdingLayer.position.y);
        }
        CGPoint translation = [gesture translationInView:gesture.view];
        [CATransaction setDisableActions:YES];
        [holdingLayer setPosition:CGPointMake(stateBeginPoint.x+translation.x,stateBeginPoint.y+translation.y)];
    }
}

- (void)handlePinch:(UIPinchGestureRecognizer *)gesture {
    if(selectedLayer != nil) {
        if([gesture state] == UIGestureRecognizerStateBegan) {
            lastScale = [gesture scale];
        }
        else if ([gesture state] == UIGestureRecognizerStateChanged) {
            CGFloat currentScale = [[holdingLayer valueForKeyPath:@"transform.scale"] floatValue];
            const CGFloat kMaxScale = 5.5;
            const CGFloat kMinScale = 0.75;
            CGFloat newScale = 1 -  (lastScale - [gesture scale]); // new scale is in the range (0-1)
            newScale = MIN(newScale, kMaxScale / currentScale);
            newScale = MAX(newScale, kMinScale / currentScale);
            [CATransaction setDisableActions:YES];
            CATransform3D trans = holdingLayer.transform;
            trans=CATransform3DScale(trans, newScale, newScale, 1);
            holdingLayer.transform = trans; //holding layer's transformation is changed here.
            lastScale = [gesture scale];
        }
    }
}

- (void)handlePanToErase:(UIPanGestureRecognizer *)gesture {
    if(selectedLayer!=nil){
        if([gesture state] == UIGestureRecognizerStateBegan){
            numberOfPoints = 0;
            brushInitialPoint = CGPointMake(staticBrushView.frame.origin.x, staticBrushView.frame.origin.y);
            lastPoint=  brushInitialPoint;
            lastPoint = [selectedLayer convertPoint:lastPoint fromLayer:self.containerView.layer];
            EraseLayer *layer = selectedLayer.mask;
            CIImage *undoCIImage  = [CIImage imageWithCGImage:layer.imageref];
            [undoRedoHandler startInvocationBasedUndoWithMainLayerMask:selectedLayer.mask withCIImage:undoCIImage];
        }
        if([gesture state]==UIGestureRecognizerStateChanged){
            CGPoint staticBrushCenter = CGPointMake(staticBrushView.frame.origin.x + (staticBrushView.frame.size.width /2), staticBrushView.frame.origin.y + (staticBrushWidth/2));
            CGPoint newPoint = staticBrushCenter;
            CGPoint translation = [gesture translationInView:self.containerView];
            [staticBrushView setFrame:CGRectMake(brushInitialPoint.x + translation.x , brushInitialPoint.y + translation.y, staticBrushView.frame.size.width, staticBrushView.frame.size.height)];
            newPoint = [selectedLayer convertPoint:newPoint fromLayer:self.containerView.layer];
            
            CGFloat brushWidth = lroundf((defaultBrushWidth + [self.brushSizeSlider value])/(holdingLayer.frame.size.width/sizeOfCurrentLayer.width));
            
            if(erase || restore) {
                
                pathArray[numberOfPoints++] = newPoint;
                if(numberOfPoints==5){
                    pathArray[3] = CGPointMake((pathArray[2].x + pathArray[4].x)/2.0, (pathArray[2].y + pathArray[4].y)/2.0);
                    [drawingHandler drawInEraseLayerAndWhiteMaskLayerWithMainLayerMask:selectedLayer.mask withPathArray:pathArray withCurrentDrawingState:erase drawingStatewithLineWidth:brushWidth];
                    for(int i = 0; i<numberOfPoints; i++) {
                        NSLog(@"The point is %@", NSStringFromCGPoint(pathArray[i]));
                    }
                    pathArray[0] = pathArray[3];
                    pathArray[1] = pathArray[4];
                    numberOfPoints = 2;
                    
                    
                    NSLog(@"BREAKKKKKKKkkkkkkk");
                   
                }
                lastPoint=newPoint;
            }
        }
        
        if([gesture state]==UIGestureRecognizerStateEnded) {
            
        }
    }
}

#pragma mark:- Events
//SegmentControl
- (IBAction)eraseRestoreSegmentChanged:(id)sender {
    if(_segmentControll.selectedSegmentIndex == 0) {
        maskingLayer.backgroundColor = [UIColor clearColor].CGColor;
        erase = YES;
        restore = NO;
        maskingLayer.segFlag = YES;
        [maskingLayer setNeedsDisplay];
    } else if(_segmentControll.selectedSegmentIndex == 1) {
        erase = NO;
        restore = YES;
        maskingLayer.segFlag = NO;
        [maskingLayer setNeedsDisplay];
    } else {
        erase = NO;
        restore = NO;
        maskingLayer.backgroundColor = [UIColor clearColor].CGColor;
        [self performSegmentation];
    }
}

#pragma mark:- Create & Draw Brush
-(void) createBrushView:(CGFloat)brushWidth position:(CGPoint)position{
    staticBrushWidth = brushWidth * RATIO;
    staticBrushView = [[UIImageView alloc] init];
    [self.containerView addSubview:staticBrushView];
    [self.containerView bringSubviewToFront:staticBrushView];
    [staticBrushView setFrame:CGRectMake(position.x - (staticBrushWidth/2), position.y - (staticBrushWidth/2), staticBrushWidth, staticBrushWidth)];
    staticBrushView.layer.cornerRadius = staticBrushWidth/2.0;
    staticBrushView.clipsToBounds = YES;
    staticBrushView.layer.masksToBounds = YES;
    staticBrushView.backgroundColor = [UIColor redColor];
}

//Brush
- (IBAction)hardBrushPressed:(id)sender {
    _hardBrushSelected.hidden = NO;
    _softBrushSelected.hidden = YES;
    maskingLayer.hardBrush = YES;
    [maskingLayer setNeedsDisplay];
}

- (IBAction)softBrushPressed:(id)sender {
    _hardBrushSelected.hidden = YES;
    _softBrushSelected.hidden = NO;
    maskingLayer.hardBrush = NO;
    [maskingLayer setNeedsDisplay];
}

//BrushSizeSlider
- (IBAction)brushSliderChanged:(UISlider *)sender {
    CGFloat value = [self.brushSizeSlider value];
    NSLog(@"slider Value: %f", value);
    CGPoint staticBrushCenter = CGPointMake(staticBrushView.frame.origin.x + (staticBrushView.frame.size.width /2), staticBrushView.frame.origin.y + (staticBrushWidth/2));
    
    [staticBrushView removeFromSuperview];
    [self createBrushView:sender.value + defaultBrushWidth position:CGPointMake(staticBrushCenter.x, staticBrushCenter.y)];
}

- (IBAction)undoPressed:(id)sender {
    [undoRedoHandler undoRecentOperation];
}

- (IBAction)redoPressed:(id)sender {
    [undoRedoHandler redoRecentOperation];
}

-(void) disableButtonWithRedo:(BOOL)redo withUndo:(BOOL)undo{
    [self.redoBtn setEnabled:redo];
    [self.undoBtn setEnabled:undo];
}

- (IBAction)save:(id)sender {
    saveImagePressed = YES;
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    OutputVC *vc = [storyboard instantiateViewControllerWithIdentifier:@"OutputVC"];
//    maskingLayer.backgroundColor = [UIColor clearColor].CGColor;
//    selectedLayer.backgroundColor = [UIColor clearColor].CGColor;
    
    EraseLayer *tempLayer = [EraseLayer layer];
    tempLayer.frame = selectedLayer.frame;
    tempLayer.backgroundColor = [[UIColor clearColor] colorWithAlphaComponent:1.0].CGColor;
    tempLayer.contents = selectedLayer.contents;
    
    
    CIImage *backgroundImage = [[CIImage alloc] initWithImage:originalImage];
    CIImage *inputImage = [[CIImage alloc] initWithImage:[UIImage imageFromLayer:tempLayer size:originalImage.size]];
    UIImage *outputImg = [self maskTwoImage:backgroundImage inputImage:inputImage];

    vc.outputImage = outputImg;
    vc.modalPresentationStyle = UIModalPresentationFullScreen;
    [self presentViewController:vc animated:YES completion:nil];
}

@end
