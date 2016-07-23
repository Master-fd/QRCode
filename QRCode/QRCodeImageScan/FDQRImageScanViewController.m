//
//  FDQRImageScanViewController.m
//  QRCode
//
//  Created by asus on 16/7/19.
//  Copyright (c) 2016年 asus. All rights reserved.
//

#import "FDQRImageScanViewController.h"
#import "FDQRCodeImage.h"
#import "FDScanToolController.h"


@interface FDQRImageScanViewController ()

- (IBAction)scanQRCodeImage:(id)sender;

@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UILabel *resultLab;

@end

@implementation FDQRImageScanViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    
    self.imageView.image = [FDQRCodeImage createMultiColorQRCode:@"扫描图片二维码" size:CGSizeMake(200, 200)];
}


- (IBAction)scanQRCodeImage:(id)sender {
    
    __weak typeof(self) _weakSelf = self;
    [FDScanToolController scanQRImage:self.imageView.image result:^(NSString *str, BOOL *scanAgain) {
        _weakSelf.resultLab.text = str;
        FDLog(@"%@", str);
    }];
}
@end
