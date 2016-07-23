//
//  FDCreateQRCodeViewController.m
//  QRCode
//
//  Created by asus on 16/7/19.
//  Copyright (c) 2016年 asus. All rights reserved.
//

#import "FDCreateQRCodeViewController.h"
#import "FDQRCodeImage.h"



@interface FDCreateQRCodeViewController ()


- (IBAction)CreateRQCode1:(id)sender;
- (IBAction)CreateRQCode2:(id)sender;
- (IBAction)CreateRQCode3:(id)sender;
- (IBAction)saveQRCodeToAlbum:(id)sender;


@property (weak, nonatomic) IBOutlet UIImageView *imageView;

@end





@implementation FDCreateQRCodeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.imageView.layer.borderColor = [UIColor orangeColor].CGColor;
    self.imageView.layer.borderWidth = 1;
    
}


- (IBAction)CreateRQCode1:(id)sender {
    FDLog(@"创建黑白二维码");
    
    
    UIImage *image = [FDQRCodeImage createBwQRCode:@"黑白二维码" size:CGSizeMake(200, 200)];
    
    self.imageView.image = image;
    
}

- (IBAction)CreateRQCode2:(id)sender {
    FDLog(@"创建彩色二维码");

    UIImage *image = [FDQRCodeImage createMultiColorQRCode:@"彩色二维码" size:CGSizeMake(200, 200)];
    self.imageView.image = image;

}

- (IBAction)CreateRQCode3:(id)sender {
    FDLog(@"创建logo二维码");
    
    UIImage *image = [FDQRCodeImage createLogoQRCode:@"带logo二维码" Logo:[UIImage imageNamed:@"logo"] size:CGSizeMake(200, 200) MultiColor:YES];
    
    self.imageView.image = image;
}

- (IBAction)saveQRCodeToAlbum:(id)sender {
    
    if (self.imageView.image) {
        UIImageWriteToSavedPhotosAlbum(self.imageView.image, self, nil, nil);
        
        FDLog(@"保存成功");
    }
    
}
@end
