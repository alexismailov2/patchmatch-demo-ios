///////////////////////////////////////////////////////////////////////
///
/// @file PatchMatch.h
///
/// @author Alexander Ismailov<alexismailov2@gmail.com>
///
/// @brief PatchMatch iOS wrapper definition.
///
/// @details iOS framework wrapper.
///
/// Copyright (C) 2020 Alexander Ismailov.
///
///////////////////////////////////////////////////////////////////////

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * PatchMatch callback which notify current image
 */
typedef void (^PatchMatchCallback)(UIImage* original, NSInteger percent);

@interface PatchMatch : NSObject
    /**
     * Image complete after cutting area which specified by mask.
     * @param original original image.
     * @param mask mask of area which should be deleted.
     * @param imageCompletionSteps image completion steps.
     * @param patchMatchingSteps patch matching steps.
     * @param callback callback which deliver current image state on demand, and progress
     * @param isNeededImageOnProgress true - image delivered, false image - nullptr.
     * @return completed image.
     */
    + (UIImage*) imageCompleteWithOriginal:(UIImage*)original
                                      mask:(UIImage*)mask
                      imageCompletionSteps:(NSInteger)imageCompletionSteps
                        patchMatchingSteps:(NSInteger)patchMatchingSteps
                                  callback:(PatchMatchCallback)callback
                   isNeededImageOnProgress:(bool)isNeededImageOnProgress;
@end

NS_ASSUME_NONNULL_END

