//
//  BCSegmentation.h
//  BCSegmentation
//
//  Created by Nafis Ahmed on 21/5/19.
//  Copyright © 2019 Nafis Ahmed. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreML/CoreML.h>
#include <stdint.h>

NS_ASSUME_NONNULL_BEGIN


/// Model Prediction Input Type
API_AVAILABLE(macos(10.13), ios(11.0), watchos(4.0), tvos(11.0)) __attribute__((visibility("hidden")))
@interface BCSegmentationInput : NSObject<MLFeatureProvider>

/// ImageTensor__0 as color (kCVPixelFormatType_32BGRA) image buffer, 513 pixels wide by 513 pixels high
@property (readwrite, nonatomic) CVPixelBufferRef ImageTensor__0;
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithImageTensor__0:(CVPixelBufferRef)ImageTensor__0;
@end


/// Model Prediction Output Type
API_AVAILABLE(macos(10.13), ios(11.0), watchos(4.0), tvos(11.0)) __attribute__((visibility("hidden")))
@interface BCSegmentationOutput : NSObject<MLFeatureProvider>

/// ResizeBilinear_3__0 as 21 x 513 x 513 3-dimensional array of doubles
@property (readwrite, nonatomic, strong) MLMultiArray * ResizeBilinear_3__0;

/// SemanticPredictions__0 as multidimensional array of doubles
@property (readwrite, nonatomic, strong) MLMultiArray * SemanticPredictions__0;
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithResizeBilinear_3__0:(MLMultiArray *)ResizeBilinear_3__0 SemanticPredictions__0:(MLMultiArray *)SemanticPredictions__0;
@end


/// Class for model loading and prediction
API_AVAILABLE(macos(10.13), ios(11.0), watchos(4.0), tvos(11.0)) __attribute__((visibility("hidden")))
@interface BCSegmentation : NSObject
@property (readonly, nonatomic, nullable) MLModel * model;
- (nullable instancetype)init;
- (nullable instancetype)initWithContentsOfURL:(NSURL *)url error:(NSError * _Nullable * _Nullable)error;
- (nullable instancetype)initWithConfiguration:(MLModelConfiguration *)configuration error:(NSError * _Nullable * _Nullable)error API_AVAILABLE(ios(12.0));
- (nullable instancetype)initWithContentsOfURL:(NSURL *)url configuration:(MLModelConfiguration *)configuration error:(NSError * _Nullable * _Nullable)error API_AVAILABLE(ios(12.0));

/**
 Make a prediction using the standard interface
 @param input an instance of BCSegmentationInput to predict from
 @param error If an error occurs, upon return contains an NSError object that describes the problem. If you are not interested in possible errors, pass in NULL.
 @return the prediction as BCSegmentationOutput
 */
- (nullable BCSegmentationOutput *)predictionFromFeatures:(BCSegmentationInput *)input error:(NSError * _Nullable * _Nullable)error;

/**
 Make a prediction using the standard interface
 @param input an instance of BCSegmentationInput to predict from
 @param options prediction options
 @param error If an error occurs, upon return contains an NSError object that describes the problem. If you are not interested in possible errors, pass in NULL.
 @return the prediction as BCSegmentationOutput
 */
- (nullable BCSegmentationOutput *)predictionFromFeatures:(BCSegmentationInput *)input options:(MLPredictionOptions *)options error:(NSError * _Nullable * _Nullable)error;

/**
 Make a prediction using the convenience interface
 @param ImageTensor__0 as color (kCVPixelFormatType_32BGRA) image buffer, 513 pixels wide by 513 pixels high:
 @param error If an error occurs, upon return contains an NSError object that describes the problem. If you are not interested in possible errors, pass in NULL.
 @return the prediction as BCSegmentationOutput
 */
- (nullable BCSegmentationOutput *)predictionFromImageTensor__0:(CVPixelBufferRef)ImageTensor__0 error:(NSError * _Nullable * _Nullable)error;

/**
 Batch prediction
 @param inputArray array of BCSegmentationInput instances to obtain predictions from
 @param options prediction options
 @param error If an error occurs, upon return contains an NSError object that describes the problem. If you are not interested in possible errors, pass in NULL.
 @return the predictions as NSArray<BCSegmentationOutput *>
 */
- (nullable NSArray<BCSegmentationOutput *> *)predictionsFromInputs:(NSArray<BCSegmentationInput*> *)inputArray options:(MLPredictionOptions *)options error:(NSError * _Nullable * _Nullable)error;
@end

NS_ASSUME_NONNULL_END

