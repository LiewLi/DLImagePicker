//
//  DLSlideScrollingCheckCell.m
//  DLImagePicker
//
//  Created by liewli on 7/2/15.
//  Copyright (c) 2015 li liew. All rights reserved.
//

#import "DLSlideScrollingCheckCell.h"

@implementation DLSlideScrollingCheckCell
{
  BOOL _open;
}
- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
    UIView *hitView = [super hitTest:point withEvent:event];
    if(!_open){
        if (hitView == self){
            return nil;
        }else{
            return hitView;
        }
    }
    return hitView;
}

+ (CGSize)defaultSize;
{
    CGSize size = CGSizeMake([UIImage imageNamed:@"ImageResources.bundle/FriendsSendsPicturesSelectBigNIcon.png"].size.width/2, [UIImage imageNamed:@"ImageResources.bundle/FriendsSendsPicturesSelectBigNIcon.png"].size.height/2);
    return size;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _open = YES;
        [self setup];
    }
    return self;
}

- (void)awakeFromNib
{
    [self setup];
}

- (void)setup
{
    UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"ImageResources.bundle/FriendsSendsPicturesSelectBigNIcon.png"]];
    [self addSubview:imageView];
    self.imageView = imageView;
    [imageView setFrame:CGRectMake(0, 0, 28, 28)];
}

- (void)setChecked:(BOOL)checked;
{
    if (checked) {
        UIImage *emptyCheckmark = [UIImage imageNamed:@"ImageResources.bundle/FriendsSendsPicturesSelectBigYIcon.png"];
        self.imageView.image = emptyCheckmark;
        
    } else {
        UIImage *fullCheckmark = [UIImage imageNamed:@"ImageResources.bundle/FriendsSendsPicturesSelectBigNIcon.png"];
        self.imageView.image = fullCheckmark;
    }
}

- (void)prepareForReuse
{
    [self setChecked:NO];
}

@end
