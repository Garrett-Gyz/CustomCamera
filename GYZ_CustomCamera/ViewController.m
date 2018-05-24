//
//  ViewController.m
//  GYZ_CustomCamera
//
//  Created by 葛玉振 on 2018/5/22.
//  Copyright © 2018年 葛玉振. All rights reserved.
//

//
//  YBCustomCameraVC.m
//  YB_iOS
//
//  Created by 葛玉振 on 2018/4/24.
//  Copyright © 2018年 liu jialin. All rights reserved.
//

#define kScreenWidth [UIScreen mainScreen].bounds.size.width
#define kScreenHeight [UIScreen mainScreen].bounds.size.height
#define kScreenBounds   [UIScreen mainScreen].bounds
#define ImageWidth 228.0 / 375.0 * kScreenWidth
#define ImageHeight 362.0 / 667.0 * kScreenHeight
#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>

@interface ViewController ()<AVCaptureMetadataOutputObjectsDelegate,UIAlertViewDelegate>
{
    UIView *blackView;
}
//捕获设备，通常是前置摄像头，后置摄像头，麦克风（音频输入）
@property(nonatomic)AVCaptureDevice *device;

//AVCaptureDeviceInput 代表输入设备，他使用AVCaptureDevice 来初始化
@property(nonatomic)AVCaptureDeviceInput *input;

//当启动摄像头开始捕获输入
@property(nonatomic)AVCaptureMetadataOutput *output;

@property (nonatomic)AVCaptureStillImageOutput *ImageOutPut;

//session：由他把输入输出结合在一起，并开始启动捕获设备（摄像头）
@property(nonatomic)AVCaptureSession *session;

//图像预览层，实时显示捕获的图像
@property(nonatomic)AVCaptureVideoPreviewLayer *previewLayer;

@property (nonatomic,strong) UIImageView *bgImage;
@property (nonatomic)UIButton *PhotoButton;
@property (nonatomic)UIButton *flashButton;
@property (nonatomic)UIImageView *imageView;
@property (nonatomic,strong) UIButton *cancelBtn;
@property (nonatomic)UIView *focusView;
@property (nonatomic)BOOL isflashOn;
@property (nonatomic)UIImage *image;
@property (nonatomic,strong) UIImage *showImage;

@property (nonatomic)BOOL canCa;
@end

@implementation ViewController


- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self customCamera];
    [self customUI];
    
}
- (void)customUI{
    _bgImage = [[UIImageView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:_bgImage];
    _bgImage.image = [UIImage imageNamed:@"Mine_camera_bg"];
    _bgImage.alpha = 0.7;
    _bgImage.userInteractionEnabled = YES;
    
    _PhotoButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [_PhotoButton setImage:[UIImage imageNamed:@"Mine_camera_button"] forState: UIControlStateNormal];
    [_PhotoButton addTarget:self action:@selector(shutterCamera) forControlEvents:UIControlEventTouchUpInside];
    [_bgImage addSubview:_PhotoButton];
    _PhotoButton.frame = CGRectMake((kScreenWidth - 70) / 2, kScreenHeight - 110, 70, 70);
    

}
- (void)customCamera{
    self.view.backgroundColor = [UIColor whiteColor];
    
    //使用AVMediaTypeVideo 指明self.device代表视频，默认使用后置摄像头进行初始化
    self.device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    //使用设备初始化输入
    self.input = [[AVCaptureDeviceInput alloc]initWithDevice:self.device error:nil];
    //生成输出对象
    self.output = [[AVCaptureMetadataOutput alloc]init];
    self.ImageOutPut = [[AVCaptureStillImageOutput alloc] init];
    //生成会话，用来结合输入输出
    self.session = [[AVCaptureSession alloc]init];
    if ([self.session canSetSessionPreset:AVCaptureSessionPresetHigh]) {
        self.session.sessionPreset = AVCaptureSessionPresetHigh;
    }
    if ([self.session canAddInput:self.input]) {
        [self.session addInput:self.input];
    }
    if ([self.session canAddOutput:self.ImageOutPut]) {
        [self.session addOutput:self.ImageOutPut];
    }
    //使用self.session，初始化预览层，self.session负责驱动input进行信息的采集，layer负责把图像渲染显示
    self.previewLayer = [[AVCaptureVideoPreviewLayer alloc]initWithSession:self.session];
    //228x362
    //    self.previewLayer.frame = CGRectMake((kScreenWidth - 228.0 / 375.0) / 2, (kScreenHeight - 362.0 / 667.0) / 2, 228.0 / 375.0, 362.0 / 667.0);
    self.previewLayer.frame = CGRectMake(0, 0, kScreenWidth, kScreenHeight);
    self.previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    [self.view.layer addSublayer:self.previewLayer];
    
    //开始启动
    [self.session startRunning];
    if ([_device lockForConfiguration:nil]) {
        if ([_device isFlashModeSupported:AVCaptureFlashModeAuto]) {
            [_device setFlashMode:AVCaptureFlashModeAuto];
        }
        //自动白平衡
        if ([_device isWhiteBalanceModeSupported:AVCaptureWhiteBalanceModeAutoWhiteBalance]) {
            [_device setWhiteBalanceMode:AVCaptureWhiteBalanceModeAutoWhiteBalance];
        }
        [_device unlockForConfiguration];
    }
}

- (void)changeCamera{
    NSUInteger cameraCount = [[AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo] count];
    if (cameraCount > 1) {
        NSError *error;
        
        CATransition *animation = [CATransition animation];
        
        animation.duration = .5f;
        
        animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
        
        animation.type = @"oglFlip";
        AVCaptureDevice *newCamera = nil;
        AVCaptureDeviceInput *newInput = nil;
        AVCaptureDevicePosition position = [[_input device] position];
        if (position == AVCaptureDevicePositionFront){
            newCamera = [self cameraWithPosition:AVCaptureDevicePositionBack];
            animation.subtype = kCATransitionFromLeft;
        }
        else {
            newCamera = [self cameraWithPosition:AVCaptureDevicePositionFront];
            animation.subtype = kCATransitionFromRight;
        }
        
        newInput = [AVCaptureDeviceInput deviceInputWithDevice:newCamera error:nil];
        [self.previewLayer addAnimation:animation forKey:nil];
        if (newInput != nil) {
            [self.session beginConfiguration];
            [self.session removeInput:_input];
            if ([self.session canAddInput:newInput]) {
                [self.session addInput:newInput];
                self.input = newInput;
                
            } else {
                [self.session addInput:self.input];
            }
            
            [self.session commitConfiguration];
            
        } else if (error) {
            NSLog(@"toggle carema failed, error = %@", error);
        }
        
    }
}
- (AVCaptureDevice *)cameraWithPosition:(AVCaptureDevicePosition)position{
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for ( AVCaptureDevice *device in devices )
        if ( device.position == position ) return device;
    return nil;
}
#pragma mark - 截取照片
- (void) shutterCamera
{
    AVCaptureConnection * videoConnection = [self.ImageOutPut connectionWithMediaType:AVMediaTypeVideo];
    if (!videoConnection) {
        NSLog(@"take photo failed!");
        return;
    }
    videoConnection.preferredVideoStabilizationMode = AVCaptureVideoStabilizationModeStandard;
    
    [self.ImageOutPut captureStillImageAsynchronouslyFromConnection:videoConnection completionHandler:^(CMSampleBufferRef imageDataSampleBuffer, NSError *error) {
        if (imageDataSampleBuffer == NULL) {
            return;
        }
        NSData * imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer];
        self.image = [UIImage imageWithData:imageData];
        [self.session stopRunning];
        //显示预览层
        [self showImageAction];
    }];
}

//截取图片
-(UIImage*)image:(UIImage *)imageI scaleToSize:(CGSize)size{
    /*
     UIGraphicsBeginImageContextWithOptions(CGSize size, BOOL opaque, CGFloat scale)
     CGSize size：指定将来创建出来的bitmap的大小
     BOOL opaque：设置透明YES代表透明，NO代表不透明
     CGFloat scale：代表缩放,0代表不缩放
     创建出来的bitmap就对应一个UIImage对象
     */
    UIGraphicsBeginImageContextWithOptions(size, NO, 3.0); //此处将画布放大三倍，这样在retina屏截取时不会影响像素
    
    [imageI drawInRect:CGRectMake(0, 0, size.width, size.height)];
    
    
    UIImage* scaledImage = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return scaledImage;
}
-(UIImage *)imageFromImage:(UIImage *)imageI inRect:(CGRect)rect{
    
    CGImageRef sourceImageRef = [imageI CGImage];
    
    CGImageRef newImageRef = CGImageCreateWithImageInRect(sourceImageRef, rect);
    
    UIImage *newImage = [UIImage imageWithCGImage:newImageRef];
    
    return newImage;
}

- (void)showImageAction {
    //纠正图片角度
    //    [self.image fixOrientation];
    //将原来的图片尺寸更改为屏幕尺寸
    self.image = [self image:self.image scaleToSize:CGSizeMake(kScreenWidth, kScreenHeight)];
    //生成一个固定尺寸的图片
    CGSize oldImageSize = CGSizeMake(self.image.size.width * 3, self.image.size.height * 3);
    CGFloat newImageWidth = 228.0 / 375.0 * oldImageSize.width;
    CGFloat newImageHeight = 362.0 / 667.0 * oldImageSize.height;
    
    UIImage *scaleImage = [self imageFromImage:self.image inRect:CGRectMake((oldImageSize.width - newImageWidth) / 2, (oldImageSize.height - newImageHeight) / 2, newImageWidth, newImageHeight)];
    //旋转图片 90度
    self.showImage = [self imageByRotate:90 * M_PI / 180 fitSize:YES image:scaleImage];
    
    
    //黑色背景
    blackView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, kScreenWidth, kScreenHeight)];
    blackView.backgroundColor = [UIColor blackColor];
    [self.view insertSubview:blackView aboveSubview:_bgImage];
    
    CGFloat hengWidth = 308.0 / 375.0 * kScreenWidth;
    CGFloat hengHeight = hengWidth / 362.0  * 228.0;
    //相框图片
    UIImageView *centerImage = [[UIImageView alloc] initWithFrame:CGRectMake((kScreenWidth - hengWidth) / 2 - 2, (kScreenHeight - hengHeight) / 2 - 2, hengWidth + 4, hengHeight + 4)];
    [blackView addSubview:centerImage];
    centerImage.image = [UIImage imageNamed:@"Mine_camera_xiangkuang"];
    //显示的图片
    self.imageView = [[UIImageView alloc]initWithFrame:CGRectMake((kScreenWidth - hengWidth) / 2, (kScreenHeight - hengHeight) / 2, hengWidth, hengHeight)];
    [blackView addSubview:_imageView];
    self.imageView.layer.masksToBounds = YES;
    self.imageView.image = _showImage;
    self.imageView.userInteractionEnabled = YES;
    //重拍
    UIButton *cancelBtn = [[UIButton alloc] initWithFrame:CGRectMake(50, kScreenHeight - 60 - 50, 60, 50)];
    [blackView addSubview:cancelBtn];
    
    [cancelBtn setTitle:@"重拍" forState:UIControlStateNormal];
    [cancelBtn.titleLabel setFont:[UIFont systemFontOfSize:15]];
    [cancelBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];

    [cancelBtn addTarget:self action:@selector(cancelAction:) forControlEvents:UIControlEventTouchUpInside];
}

- (UIImage *)imageByRotate:(CGFloat)radians fitSize:(BOOL)fitSize image:(UIImage *)image{
    size_t width = (size_t)CGImageGetWidth(image.CGImage);
    size_t height = (size_t)CGImageGetHeight(image.CGImage);
    CGRect newRect = CGRectApplyAffineTransform(CGRectMake(0., 0., width, height),
                                                fitSize ? CGAffineTransformMakeRotation(radians) : CGAffineTransformIdentity);
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(NULL,
                                                 (size_t)newRect.size.width,
                                                 (size_t)newRect.size.height,
                                                 8,
                                                 (size_t)newRect.size.width * 4,
                                                 colorSpace,
                                                 kCGBitmapByteOrderDefault | kCGImageAlphaPremultipliedFirst);
    CGColorSpaceRelease(colorSpace);
    if (!context) return nil;
    
    CGContextSetShouldAntialias(context, true);
    CGContextSetAllowsAntialiasing(context, true);
    CGContextSetInterpolationQuality(context, kCGInterpolationHigh);
    
    CGContextTranslateCTM(context, +(newRect.size.width * 0.5), +(newRect.size.height * 0.5));
    CGContextRotateCTM(context, radians);
    
    CGContextDrawImage(context, CGRectMake(-(width * 0.5), -(height * 0.5), width, height), image.CGImage);
    CGImageRef imgRef = CGBitmapContextCreateImage(context);
    UIImage *img = [UIImage imageWithCGImage:imgRef scale:image.scale orientation:image.imageOrientation];
    CGImageRelease(imgRef);
    CGContextRelease(context);
    return img;
}

- (void)cancelAction:(UIButton *)button {
    [self.imageView removeFromSuperview];
    self.imageView = nil;
    [self removeAllSubviewsWithView:blackView];
    [blackView removeFromSuperview];
    [self.session startRunning];
}

- (void)removeAllSubviewsWithView:(UIView *)parentView {
    
    while (parentView.subviews.count) {
        [parentView.subviews.lastObject removeFromSuperview];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}




@end
