//
//  FDQRCodeImage.h
//  QRCode
//
//  Created by asus on 16/7/20.
//  Copyright (c) 2016年 asus. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FDQRCodeImage : UIView



/**
 * 创建黑白二维码UIImage
 */
+ (UIImage *)createBwQRCode:(NSString *)code size:(CGSize )size;
/**
 * 创建彩色二维码UIImage
 */
+ (UIImage *)createMultiColorQRCode:(NSString *)code size:(CGSize )size;
/**
 * 创建logo二维码UIImage
 */
+ (UIImage *)createLogoQRCode:(NSString *)code Logo:(UIImage *)image size:(CGSize )size MultiColor:(BOOL)isMultiColor;
@end
