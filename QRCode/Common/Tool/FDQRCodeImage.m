//
//  FDQRCodeImage.m
//  QRCode
//
//  Created by asus on 16/7/20.
//  Copyright (c) 2016年 asus. All rights reserved.
//

#import "FDQRCodeImage.h"


void providerReleaseDataCallback(void *info, const void *data, size_t size)
{
    FDLog(@"release data, ");
    free((void *)data);
}

@implementation FDQRCodeImage


/**
 *  重绘，修改CIImage大小,创建一个UIImage图片
 */
+ (UIImage *)resizeQRCodeImage:(CIImage *)image withSize:(CGSize )size
{
    CGRect rect = CGRectIntegral(image.extent);
    CGFloat scale = MIN(size.width/CGRectGetWidth(rect), size.height/CGRectGetHeight(rect));
    size_t width = CGRectGetWidth(rect) * scale;
    size_t height = CGRectGetHeight(rect) * scale;
    
    //创建位图上下文
    CGColorSpaceRef colorSpaceRef = CGColorSpaceCreateDeviceGray();
    CGContextRef contextRef = CGBitmapContextCreate(nil, width, height, 8, 0, colorSpaceRef, (CGBitmapInfo)kCGImageAlphaNone);
    
    //创建图片
    CIContext *context = [CIContext contextWithOptions:nil];
    CGImageRef imageRef = [context createCGImage:image fromRect:rect];
    
    //设置位图质量
    CGContextSetInterpolationQuality(contextRef, kCGInterpolationNone);
    CGContextScaleCTM(contextRef, scale, scale);
    
    //绘图
    CGContextDrawImage(contextRef, rect, imageRef);
    
    //获取图片
    CGImageRef newImage = CGBitmapContextCreateImage(contextRef);
    
    //转换成UIImage
    UIImage *QRCodeImage = [UIImage imageWithCGImage:newImage];
    
    //release
    CGColorSpaceRelease(colorSpaceRef);
    CGContextRelease(contextRef);
    CGImageRelease(imageRef);
    CGImageRelease(newImage);
    
    return QRCodeImage;
}


/**
 *  给图片填充颜色
 */
+ (UIImage *)specialColorImage:(UIImage*)image withR1:(CGFloat)r1 g1:(CGFloat)g1 b1:(CGFloat)b1 andR2:(CGFloat)r2 g2:(CGFloat)g2 b2:(CGFloat)b2{
    
    int imageWidth = image.size.width;
    int imageHeight = image.size.height;
    CGRect rect = CGRectMake(0, 0, imageWidth, imageHeight);
    size_t bytesPerRow = imageWidth*4;  //每个行多少字节
    uint32_t *rgbImageBuffer = (uint32_t *)malloc(bytesPerRow * imageWidth);
    
    //创建一个位图上下文
    CGColorSpaceRef colorSpaceRef = CGColorSpaceCreateDeviceRGB();
    CGContextRef contextRef =CGBitmapContextCreate(rgbImageBuffer, imageWidth, imageHeight, 8, bytesPerRow, colorSpaceRef, kCGBitmapByteOrder32Little | kCGImageAlphaNoneSkipLast);
    
    //绘图,这里将黑白二维码绘图进去
    CGContextDrawImage(contextRef, rect, image.CGImage);
    
    int pixelNum = imageWidth*imageHeight;  //所有的像素点
    uint32_t *pCurPtr = rgbImageBuffer;
    for (int i=0; i<pixelNum; i++, pCurPtr++) {
        uint8_t *ptr = (uint8_t *)pCurPtr;
        if ((*pCurPtr&0XFFFFFF00) < 0X99999900) {
            
            ptr[3] = r1;    //将RGB转入到对应的黑色像素点的位置,黑色rgb = 000,
            ptr[2] = g1;
            ptr[1] = b1;
        }else{
            ptr[3] = r2;    //将RGB转入到对应的白色像素点的位置,白色rgb = ffffff,
            ptr[2] = g2;
            ptr[1] = b2;
        }
    }
    
    //转换到图片
    CGDataProviderRef dataProviderRef = CGDataProviderCreateWithData(NULL, rgbImageBuffer
                                                                     , bytesPerRow*imageHeight, providerReleaseDataCallback);
    CGImageRef newImage = CGImageCreate(imageWidth, imageHeight, 8, 32, bytesPerRow, colorSpaceRef, kCGImageAlphaLast | kCGBitmapByteOrder32Little, dataProviderRef, NULL, true, kCGRenderingIntentDefault);
    
    //转换成UIImage
    UIImage *img = [UIImage imageWithCGImage:newImage];
    
    //release
    CGImageRelease(newImage);
    CGDataProviderRelease(dataProviderRef);  //此时dataProviderRef ,回调函数不会马上执行，需要等到img不使用的时候才会执行回调，释放内存
    CGContextRelease(contextRef);
    CGColorSpaceRelease(colorSpaceRef);
    
    
    return img;
    
}

/**
 *  使用CIFilter创建二维码
 *
 * 错误修正容量
 * L水平 7%的字码可被修正
 * M水平 15%的字码可被修正
 * Q水平 25%的字码可被修正
 * H水平 30%的字码可被修正
 */
+ (CIImage *)createRQCIImage:(NSString *)code
{
    NSData *data = [code dataUsingEncoding:NSUTF8StringEncoding];
    
    CIFilter *filter = [CIFilter filterWithName:@"CIQRCodeGenerator"];  //初始化二维码滤镜
    [filter setValue:data forKey:@"inputMessage"];     //二维码携带的信息
    [filter setValue:@"Q" forKey:@"inputCorrectionLevel"];   //设置纠错等级越高；即识别越容易，值可设置为L(Low) |  M(Medium) | Q | H(High)
    
    return filter.outputImage;
}

/**
 *  用于生成二维码的字符串string,生成size大小的uiimage二维码
 */
+ (UIImage *)QRCodeImageWithString:(NSString *)string atSize:(CGSize )size
{
    //使用iOS 7后的CIFilter对象操作，生成二维码图片imgQRCode（比较小，会拉伸图片，比较模糊，效果不佳）
    CIImage *ciImage = [self createRQCIImage:string];
    
    //使用核心绘图框架CG（Core Graphics）对象操作，进一步针对大小生成二维码图片imgAdaptiveQRCode（图片大小适合，清晰，效果好）
    UIImage *QRImage = [self resizeQRCodeImage:ciImage withSize:size];
    
    return QRImage;
}

/**
 * 创建黑白二维码UIImage
 */
+ (UIImage *)createBwQRCode:(NSString *)code size:(CGSize )size
{
    UIImage *image = [self QRCodeImageWithString:code atSize:size];
 
    return image;
}


/**
 * 创建彩色二维码UIImage
 */
+ (UIImage *)createMultiColorQRCode:(NSString *)code size:(CGSize )size
{
    UIImage *image = [self QRCodeImageWithString:code atSize:size];

    return [self specialColorImage:image withR1:74 g1:194 b1:41 andR2:255 g2:255 b2:255];
}

/**
 * 创建logo二维码UIImage
 */
+ (UIImage *)createLogoQRCode:(NSString *)code Logo:(UIImage *)image size:(CGSize )size MultiColor:(BOOL)isMultiColor
{
    CGFloat imageWidth = size.width;
    CGFloat imageHeight = size.height;
    CGFloat iconWidth = image.size.width;
    CGFloat iconHeight = image.size.height;
    
    if (imageHeight < iconHeight || imageWidth < iconWidth) {
        return nil;
    }
    //创建二维码
    UIImage *qrImage = nil;
    if (isMultiColor) {
        //彩色
        qrImage = [self createMultiColorQRCode:code size:size];
    }else{
        //黑白
        qrImage = [self createBwQRCode:code size:size];
    }
    
    //开启一个图片上下文
    UIGraphicsBeginImageContext(size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    [qrImage drawInRect:CGRectMake(0, 0, imageWidth, imageHeight)];
    
    CGRect rect = CGRectMake((imageWidth-iconWidth)/2, (imageHeight-iconHeight)/2, iconWidth, iconHeight);
    CGContextAddRect(context, rect);
    [[UIColor whiteColor] set];
    CGContextFillRect(context, rect);
    [image drawInRect:rect];
    UIImage *qrCode = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return qrCode;
}
@end
