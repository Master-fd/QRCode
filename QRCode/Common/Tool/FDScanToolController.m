//
//  FDScanToolController.m
//  QRCode
//
//  Created by asus on 16/7/23.
//  Copyright (c) 2016年 asus. All rights reserved.
//

#import "FDScanToolController.h"
#import <AVFoundation/AVFoundation.h>


static const CGFloat kBorderW = 100;
static const CGFloat kMargin = 30;

@interface FDScanToolController ()<AVCaptureMetadataOutputObjectsDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate>

@property (nonatomic, strong) AVCaptureSession *session;    //AV捕捉

@property (nonatomic, strong) UIView *scanWindow;   //扫描窗口大小

@property (nonatomic, strong) UIImageView *scanAnimationImageView;

/**
 *  防止多次扫描
 */
@property (nonatomic, assign) BOOL success;

@property (nonatomic, assign) CGFloat bottom;

@end



@implementation FDScanToolController

- (void)viewDidLoad {
    [super viewDidLoad];
    // 这个属性必须打开否则返回的时候会出现黑边
    self.view.clipsToBounds=YES;
    //1.遮罩
    [self setupMaskView];
    //2.下边栏
    [self setupBottomBar];
    //3.提示文本
    [self setupTipTitleView];
    //4.顶部导航
    [self setupNavView];
    //5.扫描区域
    [self setupScanWindowView];
    //6.开始扫描
    [self beginScanning];
    //7.启动动画
    [self resumeAnimation:nil];

    
    //注册监听，主要是防止进入后台之后，动画会被强制取消
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(resumeAnimation:) name:UIApplicationDidBecomeActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(resumeAnimation:) name:UIApplicationWillResignActiveNotification object:nil];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    self.navigationController.navigationBar.hidden = YES;
    
    }
/**
 *  隐藏导航栏
 */
-(void)viewWillDisappear:(BOOL)animated{
    
    [super viewWillDisappear:animated];
    self.navigationController.navigationBar.hidden=NO;
    
}
/**
 *  设置导航栏
 */
-(void)setupNavView{
    
    NSLayoutConstraint *left = nil;
    NSLayoutConstraint *right = nil;
    NSLayoutConstraint *top = nil;
    NSLayoutConstraint *bottom = nil;
    
    //0.bar
    UIView *barView = [[UIView alloc] init];
    barView.backgroundColor = [UIColor blackColor];
    [self.view addSubview:barView];
    
    [barView setTranslatesAutoresizingMaskIntoConstraints:NO];
    left = [NSLayoutConstraint constraintWithItem:barView attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeLeft multiplier:1.0 constant:0];
    right = [NSLayoutConstraint constraintWithItem:barView attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeRight multiplier:1.0 constant:0];
    top = [NSLayoutConstraint constraintWithItem:barView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeTop multiplier:1.0 constant:0];
    bottom = [NSLayoutConstraint constraintWithItem:barView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeTop multiplier:1.0 constant:70];
    [self.view addConstraint:left];
    [self.view addConstraint:right];
    [self.view addConstraint:top];
    [self.view addConstraint:bottom];
    
    
    //1.返回
    UIButton *backBtn=[UIButton buttonWithType:UIButtonTypeCustom];
    backBtn.frame = CGRectMake(20, 25, 35, 35);
    [backBtn setBackgroundImage:[UIImage imageNamed:@"qrcode_scan_titlebar_back_nor"] forState:UIControlStateNormal];
    backBtn.contentMode=UIViewContentModeScaleAspectFit;
    [backBtn addTarget:self action:@selector(disMiss) forControlEvents:UIControlEventTouchUpInside];
    [barView addSubview:backBtn];
    
    
    //2.相册

    UIButton * albumBtn=[UIButton buttonWithType:UIButtonTypeCustom];
    albumBtn.frame = CGRectMake(self.view.width/2-17, 20, 35, 45);
    [albumBtn setBackgroundImage:[UIImage imageNamed:@"qrcode_scan_btn_photo_down"] forState:UIControlStateNormal];
    albumBtn.contentMode=UIViewContentModeScaleAspectFit;
    [albumBtn addTarget:self action:@selector(openAlbum) forControlEvents:UIControlEventTouchUpInside];
    [barView addSubview:albumBtn];
    
    //3.闪光灯
    
    UIButton * flashBtn=[UIButton buttonWithType:UIButtonTypeCustom];
    flashBtn.frame = CGRectMake(self.view.width-55,20, 35, 45);
    [flashBtn setBackgroundImage:[UIImage imageNamed:@"qrcode_scan_btn_flash_down"] forState:UIControlStateNormal];
    flashBtn.contentMode=UIViewContentModeScaleAspectFit;
    [flashBtn addTarget:self action:@selector(openFlash:) forControlEvents:UIControlEventTouchUpInside];
    [barView addSubview:flashBtn];
}

/**
 *  操作提示
 */
-(void)setupTipTitleView{
    
    //操作提示
    UILabel * tipLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, self.view.height*0.9-kBorderW*2, self.view.bounds.size.width, kBorderW)];
    tipLabel.text = @"将取景框对准二维码，即可自动扫描";
    tipLabel.textColor = [UIColor whiteColor];
    tipLabel.textAlignment = NSTextAlignmentCenter;
    tipLabel.lineBreakMode = NSLineBreakByWordWrapping;
    tipLabel.numberOfLines = 2;
    tipLabel.font=[UIFont systemFontOfSize:12];
    tipLabel.backgroundColor = [UIColor clearColor];
    [self.view addSubview:tipLabel];
    
}
/**
 *  遮罩
 */
- (void)setupMaskView
{
    UIView *mask = [[UIView alloc] initWithFrame:self.view.frame];
    mask.layer.borderColor = [UIColor colorWithRed:1 green:0 blue:0 alpha:0.7].CGColor;
    mask.layer.borderWidth = kBorderW;
    
    mask.bounds = CGRectMake(0, 0, self.view.width + kBorderW + kMargin , self.view.width + kBorderW + kMargin);
    mask.center = CGPointMake(self.view.width * 0.5, self.view.height * 0.5);
    mask.y = 0;
    
    [self.view addSubview:mask];
    
    self.bottom = CGRectGetMaxY(mask.frame);
}

- (void)setupBottomBar
{
    CGFloat height = self.view.height - self.bottom;
    
    CGFloat y = height<50 ? self.view.height-50 : self.bottom;
    
    //1.下边栏
    UIView *bottomBar = [[UIView alloc] initWithFrame:CGRectMake(0, y, self.view.width, 50)];
    bottomBar.backgroundColor = [UIColor blackColor];
    
    [self.view addSubview:bottomBar];
    
    //2.我的二维码
    UIButton * myCodeBtn=[UIButton buttonWithType:UIButtonTypeCustom];
    myCodeBtn.frame = CGRectMake(self.view.width/2-17, height/2-17, 35, 45);

    [myCodeBtn setImage:[UIImage imageNamed:@"qrcode_scan_btn_myqrcode_down"] forState:UIControlStateNormal];
    
    myCodeBtn.contentMode=UIViewContentModeScaleAspectFit;
    
    [myCodeBtn addTarget:self action:@selector(myCode) forControlEvents:UIControlEventTouchUpInside];
    [bottomBar addSubview:myCodeBtn];

}
/**
 *  设置扫描窗口
 */
- (void)setupScanWindowView
{
    CGFloat scanWindowH = self.view.width - kMargin * 2;
    CGFloat scanWindowW = self.view.width - kMargin * 2;
    _scanWindow = [[UIView alloc] initWithFrame:CGRectMake(kMargin, kBorderW, scanWindowW, scanWindowH)];
    _scanWindow.clipsToBounds = YES;
    [self.view addSubview:_scanWindow];
    
    CGFloat buttonWH = 18;
    
    UIButton *topLeft = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, buttonWH, buttonWH)];
    [topLeft setImage:[UIImage imageNamed:@"scan_1"] forState:UIControlStateNormal];
    [_scanWindow addSubview:topLeft];
    
    UIButton *topRight = [[UIButton alloc] initWithFrame:CGRectMake(scanWindowW - buttonWH, 0, buttonWH, buttonWH)];
    [topRight setImage:[UIImage imageNamed:@"scan_2"] forState:UIControlStateNormal];
    [_scanWindow addSubview:topRight];
    
    UIButton *bottomLeft = [[UIButton alloc] initWithFrame:CGRectMake(0, scanWindowH - buttonWH, buttonWH, buttonWH)];
    [bottomLeft setImage:[UIImage imageNamed:@"scan_3"] forState:UIControlStateNormal];
    [_scanWindow addSubview:bottomLeft];
    
    UIButton *bottomRight = [[UIButton alloc] initWithFrame:CGRectMake(topRight.x, bottomLeft.y, buttonWH, buttonWH)];
    [bottomRight setImage:[UIImage imageNamed:@"scan_4"] forState:UIControlStateNormal];
    [_scanWindow addSubview:bottomRight];
}
/**
 *  获取扫描区域比例关系
 */
-(CGRect)getScanCrop:(CGRect)rect readerViewBounds:(CGRect)readerViewBounds
{
    
    CGFloat x,y,width,height;
    
    x = (CGRectGetHeight(readerViewBounds)-CGRectGetHeight(rect))/2/CGRectGetHeight(readerViewBounds);
    y = (CGRectGetWidth(readerViewBounds)-CGRectGetWidth(rect))/2/CGRectGetWidth(readerViewBounds);
    width = CGRectGetHeight(rect)/CGRectGetHeight(readerViewBounds);
    height = CGRectGetWidth(rect)/CGRectGetWidth(readerViewBounds);
    
    return CGRectMake(x, y, width, height);
}

/**
 *  开始扫描
 */
- (void)beginScanning
{

    //获取摄像头设备
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
    //初始化输入流
    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:device error:nil];
    if (!input) {
        return;
    }

    //初始化输出流
    AVCaptureMetadataOutput *output = [[AVCaptureMetadataOutput alloc] init];
    [output setMetadataObjectsDelegate:self queue:dispatch_get_main_queue()];
    output.rectOfInterest = [self getScanCrop:self.scanWindow.bounds readerViewBounds:self.view.frame];
    
    //初始化连接对session
    self.session = [[AVCaptureSession alloc] init];
    //设置高质量采集率
    [self.session setSessionPreset:AVCaptureSessionPresetHigh];
    [self.session addInput:input];
    [self.session addOutput:output];

    //设置支持的二维码格式,可以设置多种,必须放在session之后，否则会崩溃
    output.metadataObjectTypes = @[AVMetadataObjectTypeQRCode, AVMetadataObjectTypeEAN8Code, AVMetadataObjectTypeEAN13Code, AVMetadataObjectTypeCode128Code];
    
    //初始化previewlayer
    AVCaptureVideoPreviewLayer *layer = [AVCaptureVideoPreviewLayer layerWithSession:self.session];
    layer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    layer.frame = self.view.layer.bounds;
    [self.view.layer insertSublayer:layer atIndex:0];


    //开始扫描
    [self.session startRunning];
}

- (void)beginScannin
{
    //获取摄像设备
    AVCaptureDevice * device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    //创建输入流
    AVCaptureDeviceInput * input = [AVCaptureDeviceInput deviceInputWithDevice:device error:nil];
    if (!input) return;
    //创建输出流
    AVCaptureMetadataOutput * output = [[AVCaptureMetadataOutput alloc]init];
    //设置代理 在主线程里刷新
    [output setMetadataObjectsDelegate:self queue:dispatch_get_main_queue()];
    //设置有效扫描区域
    CGRect scanCrop=[self getScanCrop:_scanWindow.bounds readerViewBounds:self.view.frame];
    output.rectOfInterest = scanCrop;
    //初始化链接对象
    _session = [[AVCaptureSession alloc]init];
    //高质量采集率
    [_session setSessionPreset:AVCaptureSessionPresetHigh];
    
    [_session addInput:input];
    [_session addOutput:output];
    //设置扫码支持的编码格式(如下设置条形码和二维码兼容)
    output.metadataObjectTypes=@[AVMetadataObjectTypeQRCode,AVMetadataObjectTypeEAN13Code, AVMetadataObjectTypeEAN8Code, AVMetadataObjectTypeCode128Code];
    
    AVCaptureVideoPreviewLayer * layer = [AVCaptureVideoPreviewLayer layerWithSession:_session];
    layer.videoGravity=AVLayerVideoGravityResizeAspectFill;
    layer.frame=self.view.layer.bounds;
    [self.view.layer insertSublayer:layer atIndex:0];
    //开始捕获
    [_session startRunning];
}

/**
 *  扫描图片二维码
 */
+ (void)scanQRImage:(UIImage *)qrImage result:(scanBlock)scanResultBlock
{
    if([[UIDevice currentDevice].systemVersion floatValue] >= 8.0){
        /**CIDetectorTypeQRCode 需要ios8环境以上 */
        
        //初始化一个监测器
        CIDetector *detector = [CIDetector detectorOfType:CIDetectorTypeQRCode context:nil options:@{ CIDetectorAccuracy : CIDetectorAccuracyHigh }];
        //监测到的结果数组
        NSArray *features = [detector featuresInImage:[CIImage imageWithCGImage:qrImage.CGImage]];
    
        if (features.count >=1) {
            /**结果对象 */
            CIQRCodeFeature *feature = [features objectAtIndex:0];
            NSString *result = feature.messageString;
            
            if (scanResultBlock) {
                BOOL scanAgain = NO;
                scanResultBlock(result, &scanAgain);
            }
        }
    }
}
#pragma mark-> 返回
- (void)disMiss
{
    [self.navigationController popViewControllerAnimated:YES];
}
/**
 *  恢复扫描动画
 */
- (void)resumeAnimation:(NSNotification *)info
{
    if (!_scanAnimationImageView) {
        _scanAnimationImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"scan_net"]];
    }
    
    if ([info.name isEqualToString:UIApplicationDidBecomeActiveNotification] || !info) {
        
        CAAnimation *animation = [_scanAnimationImageView.layer animationForKey:@"myTranslationAnimation"];
        if (animation) {
            //恢复动画
            // 1. 将动画的时间偏移量作为暂停时的时间点
            CFTimeInterval pauseTime = _scanAnimationImageView.layer.timeOffset;
            // 2. 根据媒体时间计算出准确的启动动画时间，对之前暂停动画的时间进行修正
            CFTimeInterval beginTime = CACurrentMediaTime() - pauseTime;
            // 3. 要把偏移时间清零
            [_scanAnimationImageView.layer setTimeOffset:0.0];
            // 4. 设置图层的开始动画时间
            [_scanAnimationImageView.layer setBeginTime:beginTime];
            // 5.这个速度是和动画的速度相乘的，在这里也就是1*1.5
            [_scanAnimationImageView.layer setSpeed:1];
            
            
        } else {
            //初始化一个动画
            //动画条
            
            CGFloat scanNetImageViewH = 241;
            CGFloat scanWindowH = self.view.width - kMargin * 2;
            CGFloat scanNetImageViewW = _scanWindow.width;
            
            _scanAnimationImageView.frame = CGRectMake(0, -scanNetImageViewH, scanNetImageViewW, scanNetImageViewH);
            CABasicAnimation *scanNetAnimation = [CABasicAnimation animation];
            scanNetAnimation.keyPath = @"transform.translation.y";
            scanNetAnimation.byValue = @(scanWindowH);
            scanNetAnimation.duration = 1.5;
            scanNetAnimation.repeatCount = MAXFLOAT;
            scanNetAnimation.removedOnCompletion = NO;
            [_scanAnimationImageView.layer addAnimation:scanNetAnimation forKey:@"myTranslationAnimation"];
            [_scanWindow addSubview:_scanAnimationImageView];
        }
        
    }if ([info.name isEqualToString:UIApplicationWillResignActiveNotification]) {
        FDLog(@"暂停动画");
        CFTimeInterval pauseTime = CACurrentMediaTime();
        _scanAnimationImageView.layer.timeOffset = pauseTime;
        _scanAnimationImageView.layer.speed = 0;
    }
    
    

    
}

#pragma mark - AVCaptureMetadataOutputObjectsDelegate
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection
{
    //捕获信息，可能会被调用多次
    FDLog(@"扫描结果");
    if (metadataObjects.count>0 && self.success == NO) {
        //避免重复扫描
        self.success = YES;
        AVMetadataMachineReadableCodeObject *obj = [metadataObjects objectAtIndex:0];
        NSString *result = [obj stringValue];
        if (self.scanResultBlock) {
            BOOL scanAgain = NO;
            self.scanResultBlock(result, &scanAgain);
            if (scanAgain == YES) {
                self.success = NO;
                [self.session startRunning];
            }else{
                [self disMiss];
            }
        }
    }
}


#pragma mark - 公共方法
- (void)myCode
{
    FDLog(@"我的二维码");
}

- (void)openAlbum
{
    FDLog(@"打开相册");
}
-(void)openFlash:(UIButton*)button{
    
    NSLog(@"闪光灯");
    button.selected = !button.selected;
    if (button.selected) {
        [self turnTorchOn:YES];
    }
    else{
        [self turnTorchOn:NO];
    }
    
}
/**
 *  闪关灯控制
 */
- (void)turnTorchOn:(BOOL )on
{
    //获取摄像头设备
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    if (device) {
        if ([device hasTorch] && [device hasFlash]) {
            
            [device lockForConfiguration:nil];
            if (on) {
                [device setTorchMode:AVCaptureTorchModeOn];
                [device setFlashMode:AVCaptureFlashModeOn];
            }else{
                [device setFlashMode:AVCaptureFlashModeOff];
                [device setTorchMode:AVCaptureTorchModeOff];
            }
            
            [device unlockForConfiguration];
        }
    }
}


@end
