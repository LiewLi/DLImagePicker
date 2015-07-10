//
//  DLSlideScrollingImagePicker.m
//  DLImagePicker
//
//  Created by liewli on 7/2/15.
//  Copyright (c) 2015 li liew. All rights reserved.
//

#import "DLSlideScrollingImagePicker.h"
#import "DLSlideScrollingCheckCell.h"
#import "DLSlideScrollingLayout.h"
#import "DLCollectionViewCell.h"
#import "ELCImagePickerController.h"
#import <CoreLocation/CoreLocation.h>

@import AssetsLibrary;

#define kImageSpacing 5.0f
#define kCollectionViewHeight 178.0f
#define kCollectionViewLargeHeight 280
#define kSubTitleHeight 65.0f
#define ItemHeight 50.0f
#define H [UIScreen mainScreen].bounds.size.height - self.navigationController.navigationBar.frame.size.height - (self.navigationController?[UIApplication sharedApplication].statusBarFrame.size.height:0)
#define W [UIScreen mainScreen].bounds.size.width
#define Color [UIColor colorWithRed:26/255.0f green:178.0/255.0f blue:10.0f/255.0f alpha:1]
#define Spacing 7.0f


@interface DLSlideScrollingImagePicker()<UICollectionViewDataSource, UICollectionViewDelegate, UIGestureRecognizerDelegate, UICollectionViewDelegateFlowLayout, ELCImagePickerControllerDelegate, UIImagePickerControllerDelegate>
@property (nonatomic, strong)NSMutableArray *selectedMedia;
@property (nonatomic, weak)UICollectionView *collectionView;
@property (nonatomic, strong)NSMutableArray *allMedia;
@property (nonatomic, strong)NSMapTable *indexPathToCheckViewTable;
@property (nonatomic, weak) UIView *backView;
@property (nonatomic, strong)NSArray *buttonTitles;
@property (nonatomic, strong)ALAssetsLibrary *library;
@property (nonatomic, assign)BOOL reload;
@property (nonatomic, assign)BOOL slideLarge;
@end

@implementation DLSlideScrollingImagePicker


- (void)viewDidLoad {

    [super viewDidLoad];
    [self setup];
}

#define MEDIA_BATCH_SIZE 50
- (void)setup {
    _reload = NO;
    _slideLarge = NO;
    _allMedia = [@[] mutableCopy];
    
    //if ([ALAssetsLibrary authorizationStatus] == ALAuthorizationStatusAuthorized) {
        self.selectedMedia = [NSMutableArray array];
        self.indexPathToCheckViewTable = [NSMapTable strongToWeakObjectsMapTable];
        dispatch_async(dispatch_get_main_queue(), ^{
             [self loadUI];
        });
    
        
        dispatch_async(dispatch_get_global_queue(0, DISPATCH_QUEUE_PRIORITY_DEFAULT), ^{
            _library = [[ALAssetsLibrary alloc] init];
            [_library enumerateGroupsWithTypes:ALAssetsGroupSavedPhotos usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
                [group enumerateAssetsWithOptions:NSEnumerationReverse usingBlock:^(ALAsset *result, NSUInteger index, BOOL *stop) {
                   // NSLog(@"count: %ld", _allMedia.count);
                    if (result && [[result valueForProperty:ALAssetPropertyType] isEqualToString:ALAssetTypePhoto]) {
                        if (_allMedia.count >= MEDIA_BATCH_SIZE) {
                            *stop = true;
                        }
                        [_allMedia addObject:result];
                    }
                   
                }];
                if (_allMedia.count >= MEDIA_BATCH_SIZE || group == nil) {
                    *stop = YES;
                    if (!_reload) {
                        _reload = YES;
                    dispatch_async(dispatch_get_main_queue(), ^{
                       // NSLog(@"images %s : %ld", __PRETTY_FUNCTION__, _allMedia.count);
                        [self.collectionView reloadData];
                       
                    });
                    }
                }
               
            } failureBlock:^(NSError *error) {
                NSLog(@"%s error: failed to load images", __PRETTY_FUNCTION__);
            }];
            
        });
        
   // }
    if ([ALAssetsLibrary authorizationStatus] == ALAuthorizationStatusDenied) {
        UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"读取失败"
                                                       message:@"请打开 设置-隐私-照片 来进行设置"
                                                      delegate:self
                                             cancelButtonTitle:@"确定"
                                             otherButtonTitles:nil, nil];
        [alert show];

    }
}


- (void)loadUI {
    [self.view setFrame:CGRectMake(0, 0, W, H)];
    [self.view setBackgroundColor:[UIColor clearColor]];
    
    UIView *backView = [[UIView alloc] init];
    
    _buttonTitles = @[@"拍摄",@"从相册选择"];
    
    backView.backgroundColor = [UIColor colorWithRed:223.0f/255.0f green:226.0f/255.f blue:236.0f/255.0f alpha:1];
    CGFloat height = ((ItemHeight+0.5f)+Spacing) + (_buttonTitles.count * (ItemHeight+0.5f)) + kCollectionViewHeight;
    [backView setFrame:CGRectMake(0, H, W, height)];
    
    [self.view addSubview:backView];
    self.backView = backView;
    
    UIButton *cancelbtn = [UIButton buttonWithType:UIButtonTypeSystem];
    [cancelbtn setBackgroundColor:[UIColor whiteColor]];
    [cancelbtn setFrame:CGRectMake(0, CGRectGetHeight(backView.bounds) - ItemHeight, W, ItemHeight)];
    [cancelbtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [cancelbtn setTitle:@"取消" forState:UIControlStateNormal];
    [cancelbtn addTarget:self action:@selector(selectedActions:) forControlEvents:UIControlEventTouchUpInside];
    [cancelbtn setTag:100];
    [backView addSubview:cancelbtn];
 
    
    for (NSString *Title in _buttonTitles) {
        
        NSInteger index = [_buttonTitles indexOfObject:Title];
        
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
        [btn setBackgroundColor:[UIColor whiteColor]];
        
        CGFloat h = (50.5 * _buttonTitles.count)+Spacing;
        CGFloat y = (CGRectGetMinY(cancelbtn.frame) + (index * (ItemHeight+0.5))) - h;
        
        [btn setFrame:CGRectMake(0, y, W, ItemHeight)];
        [btn setTag:(index + 100)+1];
        [btn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [btn setTitle:Title forState:UIControlStateNormal];
        [btn addTarget:self action:@selector(selectedActions:) forControlEvents:UIControlEventTouchUpInside];
        [backView addSubview:btn];
    }
    
    DLSlideScrollingLayout *flow = [[DLSlideScrollingLayout alloc] init];
    flow.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    flow.minimumInteritemSpacing = kImageSpacing;
    
    // Configure the collection view
    UICollectionView *collectionView = [[UICollectionView alloc] initWithFrame:self.view.bounds collectionViewLayout:flow];
    collectionView.translatesAutoresizingMaskIntoConstraints = NO;
    collectionView.delegate = self;
    collectionView.dataSource = self;
    collectionView.allowsMultipleSelection = YES;
    collectionView.showsHorizontalScrollIndicator = NO;
    collectionView.collectionViewLayout = flow;
    [collectionView registerClass:[DLCollectionViewCell class] forCellWithReuseIdentifier:@"Cell"];
    [collectionView registerClass:[DLSlideScrollingCheckCell class] forSupplementaryViewOfKind:@"check" withReuseIdentifier:@"CheckCell"];
    collectionView.contentInset = UIEdgeInsetsMake(0, 6, 0, 6);
    
    [backView addSubview:collectionView];
    self.collectionView = collectionView;
    [self.collectionView setFrame:CGRectMake(0, 5, W, kCollectionViewHeight-10)];
    self.collectionView.backgroundColor = [UIColor clearColor];
    
    
    [UIView animateWithDuration:0.3f delay:0 usingSpringWithDamping:0.8f initialSpringVelocity:0 options:UIViewAnimationOptionLayoutSubviews animations:^{
        
        [self.view  setBackgroundColor:[UIColor colorWithRed:0 green:0 blue:0 alpha:0.5f]];
        [self.backView setFrame:CGRectMake(0, H - height, W, height+10)];
        
    } completion:^(BOOL finished) {
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismiss:)];
        tap.delegate = self;
        [self.view addGestureRecognizer:tap];
        
        [self.backView setFrame:CGRectMake(0, H - height, W, height)];
    }];

}


- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.allMedia.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    DLCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"Cell" forIndexPath:indexPath];
    
    ALAsset *asset = [_allMedia objectAtIndex:indexPath.row];
    
    UIImage *image = [UIImage imageWithCGImage:[asset aspectRatioThumbnail]];
    
    cell.imageView.image = image;
    return cell;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{

    DLSlideScrollingCheckCell *checkView = [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:@"CheckCell" forIndexPath:indexPath];
    [self.indexPathToCheckViewTable setObject:checkView forKey:indexPath];
    
    if ([[collectionView indexPathsForSelectedItems] containsObject:indexPath]) {
        [checkView setChecked:YES];
    }
    else [checkView setChecked:NO];
    
    return checkView;
}

- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath;
{
    
    DLSlideScrollingCheckCell *checkmarkView = [self.indexPathToCheckViewTable objectForKey:indexPath];
    [self.selectedMedia removeObject:indexPath];
    [checkmarkView setChecked:NO];
    
    [self toggleTitle];
    
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath;
{
    BOOL flag = NO;
    
    if (self.collectionView.frame.size.height <= kCollectionViewHeight-10) {
        flag = YES;
        _slideLarge = YES;
       // [UIView animateWithDuration:0.3 animations:^{
            CGFloat height = ((ItemHeight+0.5f)+Spacing) + (_buttonTitles.count * (ItemHeight+0.5f)) + kCollectionViewLargeHeight;
            self.backView.frame = CGRectMake(0, H-height, W, height);
            UIView *cancelbtn = [self.backView viewWithTag:100];
            [cancelbtn setFrame:CGRectMake(0, CGRectGetHeight(self.backView.bounds) - ItemHeight, W, ItemHeight)];
            for (int i = 1; i <= _buttonTitles.count; ++i) {
                UIView *btn = [self.backView viewWithTag:100+i];
                CGFloat h = (50.5 * _buttonTitles.count)+Spacing;
                CGFloat y = (CGRectGetMinY(cancelbtn.frame) + ((i-1) * (ItemHeight+0.5))) - h;

                btn.frame = CGRectMake(0, y, W, ItemHeight);
            }
            self.collectionView.frame = CGRectMake(0, 6, W, kCollectionViewLargeHeight-12);
       // } completion:^(BOOL finished) {
            //[self.collectionView.collectionViewLayout invalidateLayout];
       // }];
    }
    else flag = false;
    [collectionView selectItemAtIndexPath:indexPath animated:YES scrollPosition:UICollectionViewScrollPositionCenteredHorizontally];
    DLSlideScrollingCheckCell* checkmarkView = [self.indexPathToCheckViewTable objectForKey:indexPath];
    if ([self.selectedMedia indexOfObject:indexPath] == NSNotFound) {
        [self.selectedMedia addObject:indexPath];
        [checkmarkView setChecked:YES];
        [self toggleTitle];
    }
   
    if (flag) {
        NSLog(@"resize collectionview");
       // [self.collectionView.collectionViewLayout invalidateLayout];
        //[self.collectionView reloadData];
        DLSlideScrollingLayout *flow = [[DLSlideScrollingLayout alloc] init];
        flow.scrollDirection = UICollectionViewScrollDirectionHorizontal;
        flow.minimumInteritemSpacing = kImageSpacing;

        [self.collectionView performBatchUpdates:^{
          //  self.collectionView.frame = CGRectMake(0, 6, W, kCollectionViewLargeHeight-12);
            [UIView animateWithDuration:0.5 animations:^{
                  [self.collectionView setCollectionViewLayout:flow animated:YES];
            }];
          
        } completion:^(BOOL finished) {
            
        }];
       
    }
    
}

- (CGSize)collectionView:(UICollectionView *)collectionView
                  layout:(UICollectionViewLayout*)collectionViewLayout
  sizeForItemAtIndexPath:(NSIndexPath *)indexPath;
{
    
    ALAsset *asset = [_allMedia objectAtIndex:indexPath.row];
    CGSize size;
    CGFloat imageHeight, imageWidth;
    CGImageRef image = [asset aspectRatioThumbnail];
    imageHeight = CGImageGetHeight(image);
    imageWidth = CGImageGetWidth(image);
    size = (CGSize) {imageWidth, imageHeight};
    
    CGFloat viewHeight = collectionView.bounds.size.height;
    CGFloat scaleFactor = viewHeight/imageHeight;
    
    CGSize scaledSize = (CGSize) {imageWidth*scaleFactor, imageHeight*scaleFactor};
    return scaledSize;
}


- (void)toggleTitle
{
    UIButton *btn = (UIButton *)[_backView viewWithTag:101];
    if (self.selectedMedia.count == 0) {
        [btn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [btn setTitle:[_buttonTitles objectAtIndex:btn.tag-101] forState:UIControlStateNormal];
        
    }else{
        
        [btn setTitle:[NSString stringWithFormat:@"选择(%lu张)",(unsigned long )self.selectedMedia.count] forState:UIControlStateNormal];
        [btn setTitleColor:Color forState:UIControlStateNormal];
        
    }
}

- (void)selectedActions:(UIButton *)sender {

    NSLog(@"button tapped: %ld", sender.tag-100);
    NSInteger tag = sender.tag - 100;
    if (tag == 0) { //cancel
        [self.delegate dlSlideScrollingImagePickerDidCancel:self];
        [self dismiss];
    }
    else if (tag == 1) { // camera or chose from slides
        if (self.selectedMedia.count > 0) {
            NSMutableArray * assets = [@[] mutableCopy];
            for (NSIndexPath *indexPath in self.selectedMedia) {
                [assets addObject:self.allMedia[indexPath.row]];
            }
            [self selectedAssets:assets];
        }
        else {
            if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
                UIImagePickerController *picker = [[UIImagePickerController alloc] init];
                picker.delegate = self;
                picker.sourceType = UIImagePickerControllerSourceTypeCamera;
                CGFloat height = ((ItemHeight+0.5f)+Spacing) + (_buttonTitles.count * (ItemHeight+0.5f)) + (_slideLarge? kCollectionViewLargeHeight:kCollectionViewHeight);
                [UIView animateWithDuration:0.3 animations:^{
                    [self.view setBackgroundColor:[UIColor colorWithRed:0 green:0 blue:0 alpha:0.0f]];
                    [_backView setFrame:CGRectMake(0, H, W, height)];
                } completion:^(BOOL finished) {
                    [self presentViewController:picker animated:YES completion:^{
                    }];
                }];
                
            }
            else {
                UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"读取失败"
                                                               message:@"无法打开摄像头"
                                                              delegate:self
                                                     cancelButtonTitle:@"确定"
                                                     otherButtonTitles:nil, nil];
                [alert show];
            }
        }
    }
    else if (tag == 2) { //photo library
        ELCImagePickerController *picker = [[ELCImagePickerController alloc] initImagePicker];
        picker.imagePickerDelegate = self;
        CGFloat height = ((ItemHeight+0.5f)+Spacing) + (_buttonTitles.count * (ItemHeight+0.5f)) + (_slideLarge? kCollectionViewLargeHeight:kCollectionViewHeight);
        [UIView animateWithDuration:0.3 animations:^{
            [self.view setBackgroundColor:[UIColor colorWithRed:0 green:0 blue:0 alpha:0.0f]];
            [_backView setFrame:CGRectMake(0, H, W, height)];
        } completion:^(BOOL finished) {
            [self presentViewController:picker animated:YES completion:^{
            }];
        }];
    }
}

-(void)selectedAssets:(NSArray *)assets
{
    NSMutableArray *returnArray = [[NSMutableArray alloc] init];
    
    for(ALAsset *asset in assets) {
        id obj = [asset valueForProperty:ALAssetPropertyType];
        if (!obj) {
            continue;
        }
        NSMutableDictionary *workingDictionary = [[NSMutableDictionary alloc] init];
        
        CLLocation* wgs84Location = [asset valueForProperty:ALAssetPropertyLocation];
        if (wgs84Location) {
            [workingDictionary setObject:wgs84Location forKey:ALAssetPropertyLocation];
        }
        
        [workingDictionary setObject:obj forKey:UIImagePickerControllerMediaType];
        
        //This method returns nil for assets from a shared photo stream that are not yet available locally. If the asset becomes available in the future, an ALAssetsLibraryChangedNotification notification is posted.
        ALAssetRepresentation *assetRep = [asset defaultRepresentation];
        
        if(assetRep != nil) {
            CGImageRef imgRef = nil;
            //defaultRepresentation returns image as it appears in photo picker, rotated and sized,
            //so use UIImageOrientationUp when creating our image below.
            UIImageOrientation orientation = UIImageOrientationUp;
            
            
            imgRef = [assetRep fullScreenImage];
            
            UIImage *img = [UIImage imageWithCGImage:imgRef
                                               scale:1.0f
                                         orientation:orientation];
            [workingDictionary setObject:img forKey:UIImagePickerControllerOriginalImage];
        }
        
        [workingDictionary setObject:[[asset valueForProperty:ALAssetPropertyURLs] valueForKey:[[[asset valueForProperty:ALAssetPropertyURLs] allKeys] objectAtIndex:0]] forKey:UIImagePickerControllerReferenceURL];
        
        [returnArray addObject:workingDictionary];
        
        
    }
    [self.delegate dlSlideScrollingImagePicker:self didFinishingPickingMediaWithInfo:returnArray];
    [self dismiss];
}


#pragma mark - UIImagePickerControllerDelegate

- (void)dismissController {
    [self dismissViewControllerAnimated:YES completion:^{
        [self.view removeFromSuperview];
        [self removeFromParentViewController];
    }];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [self.delegate dlSlideScrollingImagePickerDidCancel:self];
    [self dismissController];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    [self.delegate dlSlideScrollingImagePicker:self didFinishingPickingMediaWithInfo:@[info]];
    [self dismissController];
}

#pragma mark - ELCImagePickerControllerDelegate
- (void)elcImagePickerController:(ELCImagePickerController *)picker didFinishPickingMediaWithInfo:(NSArray *)info {
    [self.delegate dlSlideScrollingImagePicker:self didFinishingPickingMediaWithInfo:info];
    [self dismissController];

}

-(void)elcImagePickerControllerDidCancel:(ELCImagePickerController *)picker {
    [self.delegate dlSlideScrollingImagePickerDidCancel:self];
    [self dismissController];
}


- (void)dismiss {

    CGFloat height = ((ItemHeight+0.5f)+Spacing) + (_buttonTitles.count * (ItemHeight+0.5f)) + (_slideLarge? kCollectionViewLargeHeight:kCollectionViewHeight);
    
    [UIView animateWithDuration:0.4f delay:0 usingSpringWithDamping:0.8f initialSpringVelocity:0 options:UIViewAnimationOptionLayoutSubviews animations:^{
        
        [self.view setBackgroundColor:[UIColor colorWithRed:0 green:0 blue:0 alpha:0.0f]];
        [_backView setFrame:CGRectMake(0, H, W, height)];
        
    } completion:^(BOOL finished) {
        
        [self.view removeFromSuperview];
        [self removeFromParentViewController];
    }];

}

-(void)dismiss:(UITapGestureRecognizer *)tap{
    
    if( CGRectContainsPoint(self.view.frame, [tap locationInView:_backView])) {
        NSLog(@"tap");
    } else{
        
        [self dismiss];
    }
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    if (touch.view != self.view) {
        return NO;
    }
    
    return YES;
}

@end
