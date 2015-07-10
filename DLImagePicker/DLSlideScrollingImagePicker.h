//
//  DLSlideScrollingImagePicker.h
//  DLImagePicker
//
//  Created by liewli on 7/2/15.
//  Copyright (c) 2015 li liew. All rights reserved.
//

#import <UIKit/UIKit.h>

@class DLSlideScrollingImagePicker;

@protocol DLSlideScrollingImagePickerDelegate <NSObject>
- (void)dlSlideScrollingImagePicker:(DLSlideScrollingImagePicker * __nonnull)picker didFinishingPickingMediaWithInfo:(NSArray * __nonnull) info;

- (void)dlSlideScrollingImagePickerDidCancel:(DLSlideScrollingImagePicker * __nonnull)picker;
@end



@interface DLSlideScrollingImagePicker : UIViewController
@property (nonatomic, weak, nullable) id<DLSlideScrollingImagePickerDelegate> delegate;

@end
