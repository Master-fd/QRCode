//
//  FDQRScanViewController.m
//  QRCode
//
//  Created by asus on 16/7/19.
//  Copyright (c) 2016年 asus. All rights reserved.
//

#import "FDQRScanViewController.h"
#import "FDScanToolController.h"



@interface FDQRScanViewController ()

- (IBAction)beginScan:(id)sender;

@property (weak, nonatomic) IBOutlet UILabel *resultLab;


@end

@implementation FDQRScanViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.

    
}



#pragma mark - UIAlertViewDelegate



- (IBAction)beginScan:(id)sender {
    
    __weak typeof(self) _weakSelf = self;
    
    FDScanToolController *scanVc = [[FDScanToolController alloc] init];
    [self.navigationController pushViewController:scanVc animated:YES];
    
    scanVc.scanResultBlock = ^(NSString *result, BOOL *scanAgain){
        FDLog(@"result = %@", result);
        _weakSelf.resultLab.text = result;
        *scanAgain = NO; //不重复扫描
        
    };

    
}
@end
