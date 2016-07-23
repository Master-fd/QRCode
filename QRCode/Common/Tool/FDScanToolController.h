//
//  FDScanToolController.h
//  QRCode
//
//  Created by asus on 16/7/23.
//  Copyright (c) 2016年 asus. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void(^scanBlock)(NSString *str, BOOL *scanAgain);
@interface FDScanToolController : UIViewController


/**
 *  扫描结果
 */
@property (nonatomic, copy) scanBlock scanResultBlock;

/**
 *  扫描图片二维码
 */
+ (void)scanQRImage:(UIImage *)qrImage result:(scanBlock )scanResultBlock;

@end
