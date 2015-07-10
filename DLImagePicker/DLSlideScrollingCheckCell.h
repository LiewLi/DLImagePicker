//
//  DLSlideScrollingCheckCell.h
//  DLImagePicker
//
//  Created by liewli on 7/2/15.
//  Copyright (c) 2015 li liew. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DLSlideScrollingCheckCell : UICollectionReusableView
@property (nonatomic, weak) UIImageView *imageView;
+ (CGSize)defaultSize;
- (void)setChecked:(BOOL)checked;

@end
