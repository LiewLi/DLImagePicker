//
//  ViewController.m
//  DLImagePicker
//
//  Created by liewli on 7/2/15.
//  Copyright (c) 2015 li liew. All rights reserved.
//

#import "ViewController.h"
#import "DLSlideScrollingImagePicker.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (IBAction)imagePicker:(id)sender {
    DLSlideScrollingImagePicker *picker = [[DLSlideScrollingImagePicker alloc]init];
    
    [self.view addSubview:picker.view];
    [self addChildViewController:picker];
}

@end
