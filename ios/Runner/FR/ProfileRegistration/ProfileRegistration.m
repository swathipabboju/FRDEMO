

//  Runner
//
//  Created by CGG on 29/11/23.
//

#import <Foundation/Foundation.h>
#import "ProfileRegistration.h"
#import <AVFoundation/AVFoundation.h>
#import "Tools.h"
#import "FaceAntiSpoofing.h"
#import "MobileFaceNet.h"

@interface ProfileRegistration () <AVCaptureVideoDataOutputSampleBufferDelegate , AVCapturePhotoCaptureDelegate>

@property (weak, nonatomic) IBOutlet UIView *preview;
@property (weak, nonatomic) IBOutlet UILabel *resultLabel;
@property (strong, nonatomic) IBOutlet UILabel *noteLabel;

@property (strong, nonatomic) AVCaptureSession *session;
@property (strong, nonatomic) AVCaptureDeviceInput *input;
@property (strong, nonatomic) AVCaptureVideoDataOutput *output;
@property (strong, nonatomic) AVCaptureVideoPreviewLayer *layer;

@property (assign, nonatomic) BOOL isHandling;
@property (assign, nonatomic) NSInteger frameNum;
@property (assign, nonatomic) int time;
@property (assign, nonatomic) int laplaceValue;

@property (assign, nonatomic) int boxesCount;
@property (assign, nonatomic) UIImage* finalImage;
@property (strong, nonatomic) UIImage *inputImage;
@property (strong, nonatomic) UIImage *currentFrameImage;
@property (assign, nonatomic) NSData *verifiedFaceImageData;
@property (strong, nonatomic)UIActivityIndicatorView *activityIndicator;
@property (strong, nonatomic) IBOutlet UIImageView *profileView;
@property (nonatomic, strong) NSDictionary *profileImageResult;
@property (strong, nonatomic) AVCapturePhotoOutput *photoOutput;
@property (strong, nonatomic) VNDetectFaceRectanglesRequest *faceDetectionRequest;

@end


@implementation ProfileRegistration
- (void)viewDidLoad {
    [super viewDidLoad];
    _type = 1;
    // Setup Vision Face Detection Request
    self.faceDetectionRequest = [[VNDetectFaceRectanglesRequest alloc] init];
    self.isAlertPresented = NO;
    self.isNofaceAlertPresented = YES;
    _activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleLarge];
    _activityIndicator.center = self.view.center;
    _activityIndicator.color = [UIColor whiteColor];
    [self.view addSubview:_activityIndicator];
    
    self.mtcnn = [[MTCNN alloc] init];
    self.fas = [[FaceAntiSpoofing alloc] init];
    self.mfn = [[MobileFaceNet alloc] init];
    //    NSData *savedImageData = [[NSUserDefaults standardUserDefaults] objectForKey:@"demoImageKey"];
    //    _demoImg = [UIImage imageWithData:savedImageData];
    //    _demoImg = _registredProfilePhoto;
    
    NSError *error = nil;
    self.session = [[AVCaptureSession alloc] init];
    self.session.sessionPreset = AVCaptureSessionPresetHigh;
    AVCaptureDevice *frontCamera = nil;
    NSArray *cameras = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *camera in cameras) {
        if (camera.position == AVCaptureDevicePositionFront) {
            frontCamera = camera;
        }
    }
    
    // 用device对象创建一个设备对象input，并将其添加到session
    self.input = [AVCaptureDeviceInput deviceInputWithDevice:frontCamera error:&error];
    [self.session addInput:self.input];
    
    self.output = [[AVCaptureVideoDataOutput alloc] init];
    self.output.videoSettings = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:kCVPixelFormatType_32BGRA] forKey:(id)kCVPixelBufferPixelFormatTypeKey];
    [self.session addOutput:self.output];
    
    AVCaptureConnection *connection = [self.output connectionWithMediaType:AVMediaTypeVideo];
    connection.videoOrientation = AVCaptureVideoOrientationPortrait;
    
    dispatch_queue_t queue = dispatch_queue_create("CameraQueue", NULL);
    [_output setSampleBufferDelegate:self queue:queue];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        self.layer = [AVCaptureVideoPreviewLayer layerWithSession:self.session];
        self.layer.videoGravity = AVLayerVideoGravityResizeAspectFill;
        self.layer.frame = CGRectMake(0, 0, self.preview.bounds.size.width, self.preview.bounds.size.height);
        [self.preview.layer addSublayer:self.layer];
        
        
        // Calculate the label width based on screen size
        CGFloat screenWidth = CGRectGetWidth([[UIScreen mainScreen] bounds]);
        CGFloat labelWidth = screenWidth - 40;
        // Adjust as needed, subtracting 40 for some margin on both sides
        UILabel *overlayLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 20, labelWidth, 50)]; // Increased width to 280
        overlayLabel.textColor = [UIColor grayColor]; // Set the text color
        overlayLabel.backgroundColor = [UIColor whiteColor]; // Set the background color
        overlayLabel.text = @"Please avoid direct sunlight and direct focused light when capturing the face."; // Set the label text
        overlayLabel.textAlignment = NSTextAlignmentCenter; // Set the text alignment
        overlayLabel.font = [UIFont systemFontOfSize:14.0];
        overlayLabel.numberOfLines = 2;// Set the font size
        [self.preview addSubview:overlayLabel];
        // Add the label to the camera preview view
        
        [self.session commitConfiguration];
        dispatch_async(dispatch_get_main_queue(), ^{
            
            [self.session startRunning];
            // self.noteLabel.text = @"11111";
            // Create a UILabel
            
        });
        self.photoOutput = [[AVCapturePhotoOutput alloc] init];
        if ([self.session canAddOutput:self.photoOutput]) {
            [self.session addOutput:self.photoOutput];
        }
        // Inside your ProfileRegistration class
        UIButton *captureButton = [UIButton buttonWithType:UIButtonTypeCustom];
        captureButton.tintColor = [UIColor redColor];
        [captureButton setImage:[UIImage imageNamed:@"camera"] forState:UIControlStateNormal];
        [captureButton addTarget:self action:@selector(captureButtonTapped) forControlEvents:UIControlEventTouchUpInside];
        // Adjust the frame and other properties as needed
        captureButton.frame = CGRectMake(CGRectGetWidth(self.view.frame) - 100, CGRectGetHeight(self.view.frame) - 100, 50, 50);
        [self.preview addSubview:captureButton];

    });
}
- (void)captureButtonTapped {
    // Check for face detection and anti-spoofing conditions before capturing a photo
        if (![self checkFaceDetectionConditions]) {
            // Display an alert or handle the condition as needed
            return;
        }
        AVCapturePhotoSettings *photoSettings = [AVCapturePhotoSettings photoSettings];
        [self.photoOutput capturePhotoWithSettings:photoSettings delegate:self];
}

- (BOOL)checkFaceDetectionConditions {
    BOOL faceDetected = [self faceBeforeCameraClick:_currentFrameImage type:self.type];
    return faceDetected;
}

- (void)captureOutput:(AVCapturePhotoOutput *)output didFinishProcessingPhoto:(AVCapturePhoto *)photo error:(nullable NSError *)error {
    if (!error) {
        NSData *imageData = photo.fileDataRepresentation;
        UIImage *capturedImage = [UIImage imageWithData:imageData];
        
        // Handle the captured image (you may want to display it or process it)
        [self handleCapturedImage:capturedImage];
    }
}

- (void)captureOutput:(AVCapturePhotoOutput *)output didFinishCaptureForResolvedSettings:(AVCaptureResolvedPhotoSettings *)resolvedSettings error:(nullable NSError *)error {
    // Handle the completion of the capture process if needed
   
}

- (void)handleCapturedImage:(UIImage *)capturedImage {
    // Add your logic to handle the captured image
    // For example, you can display it in an image view
    dispatch_async(dispatch_get_main_queue(), ^{
        UIImage *fixedImage = [self fixImageOrientation:capturedImage];
        if (self.ProfileRegistrationHandler) {
                   NSString *base64String = [self base64StringFromImage:fixedImage];
                   self->_profileImageResult = @{
                       @"result": base64String,
                       @"status" : @"captured profile image"
                   };
                   self.ProfileRegistrationHandler(self.profileImageResult);
                   [self.session stopRunning];
                   [self dismissViewControllerAnimated:YES completion:nil];
               }
    });
}
- (NSString *)base64StringFromImage:(UIImage *)image {
    NSData *imageData = UIImageJPEGRepresentation(image, 0); // You can adjust compression quality as needed
    NSString *base64String = [imageData base64EncodedStringWithOptions:0];
    return base64String;
}

- (IBAction)close:(id)sender {
    [self.session stopRunning];
    [self dismissViewControllerAnimated:YES completion:^{
    }];
}
- (UIImage *)convertSampleBufferToImage:(CMSampleBufferRef)sampleBuffer {
    // 制作CVImageBufferRef
    CVImageBufferRef buffer;
    buffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    CVPixelBufferLockBaseAddress(buffer, 0);
    
    // 从 CVImageBufferRef 取得影像的细部信息
    uint8_t *base;
    size_t width, height, bytesPerRow;
    base = CVPixelBufferGetBaseAddress(buffer);
    width = CVPixelBufferGetWidth(buffer);
    height = CVPixelBufferGetHeight(buffer);
    bytesPerRow = CVPixelBufferGetBytesPerRow(buffer);
    
    // 利用取得影像细部信息格式化 CGContextRef
    CGColorSpaceRef colorSpace;
    CGContextRef cgContext;
    colorSpace = CGColorSpaceCreateDeviceRGB();
    cgContext = CGBitmapContextCreate(base, width, height, 8, bytesPerRow, colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
    CGColorSpaceRelease(colorSpace);
    
    // 透过 CGImageRef 将 CGContextRef 转换成 UIImage
    CGImageRef cgImage;
    UIImage *image;
    cgImage = CGBitmapContextCreateImage(cgContext);
    image = [UIImage imageWithCGImage:cgImage];
    CGImageRelease(cgImage);
    CGContextRelease(cgContext);
    CVPixelBufferUnlockBaseAddress(buffer, 0);
    
    return image;
}

- (void)face:(UIImage *)image type:(int)type {
    CGImageRef imageRef = image.CGImage;
    size_t width = CGImageGetWidth(imageRef);
    size_t height = CGImageGetHeight(imageRef);
    NSArray<Box *> *boxes = [self.mtcnn detectFaces:image minFaceSize:(int)width / 5];
    if (boxes.count == 0) {
        [self setText:_boxesCount score:0];
        _boxesCount = 0;
        self.isHandling = NO;
        return;
    }
    
    Box *box = boxes[0];
    [box toSquareShape];
    if ([box transboundW:(int)width H:(int)height]) {
        //  [self setText:-1 score:0];
        self.isHandling = NO;
        return;
    }
    //crop live image
    UIImage *cropImage = [Tools cropImage:image toRect:box.transform2Rect];
   
    self.time++;
    
    int laplace = [self.fas laplacian:cropImage];
    _laplaceValue = laplace;
    // Save a string in NSUserDefaults
    if (laplace == 0){
        dispatch_async(dispatch_get_main_queue(), ^{
            UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"FR Attedance"
                                                                                     message:@"Spoofing detected Please try again"
                                                                              preferredStyle:UIAlertControllerStyleAlert];
            
            UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK"
                                                               style:UIAlertActionStyleDefault
                                                             handler:^(UIAlertAction * _Nonnull action) {
                // Handle OK action here
                // NSLog(@"OK button tapped");
                //  [self performOKAction]; // Call your custom method here
                if (self.ProfileRegistrationHandler) {
                    self->_profileImageResult= @{
                        @"result": @"Spoofing detected",
                        @"status" : @""
                    };
                    self.ProfileRegistrationHandler(self.profileImageResult);
                    [self.session stopRunning];
                    [self dismissViewControllerAnimated:YES completion:nil];
                }
            }];
            [alertController addAction:okAction];
            [self presentViewController:alertController animated:YES completion:nil];
        });
    }
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setInteger:laplace forKey:@"imageLightning"];
    if (laplace < laplacian_threshold) {
        [self setText:laplace score:0];
        self.isHandling = NO;
        return;
    }
    
    float score = [self.fas antiSpoofing:cropImage];
    
    [userDefaults setFloat:score forKey:@"spoofing"];
    // fas_threshold  = 0.2f
    NSLog(@"%d@score", score);
    
    if (score > fas_threshold  && score > 0.00) {
       // [self setText:laplace score:score];
        [self setTextSpoofing:laplace score:score];
        self.isHandling = NO;
        return;
    }
    NSLog(@"%d@slaplace val is", laplace);
    
}
- (void)setTextSpoofing:(int)laplace score:(float)score {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Virtuo"
                                                                                 message:@"Spoofing detected Please try again"
                                                                          preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK"
                                                           style:UIAlertActionStyleDefault
                                                         handler:^(UIAlertAction * _Nonnull action) {
            if (self.ProfileRegistrationHandler) {
                self->_profileImageResult= @{
                    @"result": @"Spoofing detected",
                    @"status" : @""
                };
                self.ProfileRegistrationHandler(self.profileImageResult);
                [self.session stopRunning];
                [self dismissViewControllerAnimated:YES completion:nil];
            }
        }];
        [alertController addAction:okAction];
        [self presentViewController:alertController animated:YES completion:nil];
    });
  //  return
}
    - (BOOL)faceBeforeCameraClick:(UIImage *)image type:(int)type {
        CGImageRef imageRef = image.CGImage;
        size_t width = CGImageGetWidth(imageRef);
        size_t height = CGImageGetHeight(imageRef);
        
        NSArray<Box *> *boxes = [self.mtcnn detectFaces:image minFaceSize:(int)width / 5];
        
        if (boxes.count == 0) {
            [self setTextBeforeCameraClick:_boxesCount score:0];
            _boxesCount = 0;
            self.isHandling = NO;
            return NO;  // Face not detected
        }
        
        Box *box = boxes[0];
        [box toSquareShape];
        
        if ([box transboundW:(int)width H:(int)height]) {
            self.isHandling = NO;
            return NO;  // Face not detected
        }
        
        // Crop live image
        UIImage *cropImage = [Tools cropImage:image toRect:box.transform2Rect];
        self.time++;
        
        int laplace = [self.fas laplacian:cropImage];
        _laplaceValue = laplace;
        
        // Save a string in NSUserDefaults
        if (laplace == 0) {
            dispatch_async(dispatch_get_main_queue(), ^{
                UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"FR Attedance"
                                                                                         message:@"Spoofing detected. Please try again"
                                                                                  preferredStyle:UIAlertControllerStyleAlert];
                
                UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK"
                                                                   style:UIAlertActionStyleDefault
                                                                 handler:^(UIAlertAction * _Nonnull action) {
                    if (self.ProfileRegistrationHandler) {
                        self->_profileImageResult= @{
                            @"result": @"Spoofing detected",
                            @"status" : @""
                        };
                        self.ProfileRegistrationHandler(self.profileImageResult);
                        [self.session stopRunning];
                        [self dismissViewControllerAnimated:YES completion:nil];
                    }
                }];
                
                [alertController addAction:okAction];
                [self presentViewController:alertController animated:YES completion:nil];
            });
            return NO;  // Spoofing detected
        }
        
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        [userDefaults setInteger:laplace forKey:@"imageLightning"];
        
        if (laplace < laplacian_threshold) {
            [self setText:laplace score:0];
            self.isHandling = NO;
            return NO;  // Face not detected
        }
        
        float score = [self.fas antiSpoofing:cropImage];
        [userDefaults setFloat:score forKey:@"spoofing"];
        
        if (score > fas_threshold) {
            [self setText:laplace score:score];
            self.isHandling = NO;
            return NO;  // Spoofing detected
        }
        
        NSLog(@"%d@slaplace val is", laplace);
        
        // If the method reaches this point, it means face detection conditions are met
        return YES;
    }

- (void)setText:(int)boxesCount score:(float)score {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (boxesCount == 0) {
            //   [self.session stopRunning];
            NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
            [userDefaults setObject:@"No Face detected" forKey:@"reason"];
            self.resultLabel.text = @"No Face detected";
           if (!self.isAlertPresented) {
                self.isAlertPresented = YES;
                UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"FR Attedance"
                                                                                         message:@"No face detected, Please try again"
                                                                                  preferredStyle:UIAlertControllerStyleAlert];
                
                UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK"
                                                                   style:UIAlertActionStyleDefault
                                                                 handler:^(UIAlertAction * _Nonnull action) {
                    // Handle OK action here
                    NSLog(@"OK button tapped");
                    // Call the result handler with the data
                    
                    if (self.ProfileRegistrationHandler) {
                        self->_profileImageResult= @{
                            @"result": @"No face Detected",
                            @"status" : @"punchIn"
                        };
                        self.ProfileRegistrationHandler(self.profileImageResult);
                        [self.session stopRunning];
                        [self dismissViewControllerAnimated:YES completion:nil];
                    }
                    
                    
                }];
                [alertController addAction:okAction];
                [self presentViewController:alertController animated:YES completion:nil];
            }
           // return;
        }
        
//        NSString *text = [NSString stringWithFormat:@"Recognition times：%d\nPicture Clarity Score：%d", self.time, laplace];
//        if (laplace > laplacian_threshold) {
//            text = [text stringByAppendingFormat:@"\nliveness detection score：%f", score];
//        }
  //      self.resultLabel.text = text;
        
    });
}
- (void)setTextBeforeCameraClick:(int)boxesCount score:(float)score {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (boxesCount == 0) {
            //   [self.session stopRunning];
            NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
            [userDefaults setObject:@"No Face detected" forKey:@"reason"];
            self.resultLabel.text = @"No Face detected";
           if (!self.isNofaceAlertPresented) {
                self.isNofaceAlertPresented = YES;
                UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"FR Attedance"
                                                                                         message:@"No face detected, Please try again"
                                                                                  preferredStyle:UIAlertControllerStyleAlert];
                
                UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK"
                                                                   style:UIAlertActionStyleDefault
                                                                 handler:^(UIAlertAction * _Nonnull action) {
                    // Handle OK action here
                    NSLog(@"OK button tapped");
                    // Call the result handler with the data
                    
                    if (self.ProfileRegistrationHandler) {
                        self->_profileImageResult= @{
                            @"result": @"No face Detected",
                            @"status" : @"punchIn"
                        };
                        self.ProfileRegistrationHandler(self.profileImageResult);
                        [self.session stopRunning];
                        [self dismissViewControllerAnimated:YES completion:nil];
                    }
                    
                    
                }];
                [alertController addAction:okAction];
                [self presentViewController:alertController animated:YES completion:nil];
            }
           // return;
        }
        
//        NSString *text = [NSString stringWithFormat:@"Recognition times：%d\nPicture Clarity Score：%d", self.time, laplace];
//        if (laplace > laplacian_threshold) {
//            text = [text stringByAppendingFormat:@"\nliveness detection score：%f", score];
//        }
  //      self.resultLabel.text = text;
        
    });
}
#pragma mark - AVCaptureVideoDataOutputSampleBufferDelegate
- (void)captureOutput:(AVCaptureOutput *)output didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
       
    //    NSLog(@"isHandling: %d",!self.isHandling);
    //    NSLog(@"typre: %i",self.type);
   // NSLog(@"frameNum : %ld",(long)self.frameNum);
   _currentFrameImage = [self convertSampleBufferToImage:sampleBuffer];

    
    // Perform face detection
       
        if (self.frameNum > 15 && !self.isHandling) {
            self.isHandling = YES;
            UIImage *image = [self convertSampleBufferToImage:sampleBuffer];
            CIContext *context = [CIContext contextWithOptions:[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:kCIContextUseSoftwareRenderer]];
            CIDetector *detector = [CIDetector detectorOfType:CIDetectorTypeFace context:context options:[NSDictionary dictionaryWithObject:CIDetectorAccuracyHigh forKey:CIDetectorAccuracy]];
            CIImage *ciImage = [[CIImage alloc]init];
            ciImage = [CIImage imageWithCGImage:image.CGImage];
          //  dispatch_async(dispatch_get_main_queue(), ^{
             //   previewIV.image = resultImage;
         //   });
            NSArray *results = [detector featuresInImage:ciImage options:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:6] forKey:CIDetectorImageOrientation]];
            for (CIFaceFeature *face in results) {
                UIImage *faceImage = [UIImage imageWithCGImage:[context createCGImage:ciImage fromRect:face.bounds] scale:1.0 orientation:UIImageOrientationRight];
                int size = [results count];
                NSLog(@"there are %d objects in the array", size);
                NSLog(@"111111====%@", face);
             //   NSLog(@"====%@", NSStringFromCGRect(face.bounds));
                
           //     results  @"2 elements"
                if (size > 1){
                    dispatch_async(dispatch_get_main_queue(), ^{
                        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"FR Attedance"
                                                                                                 message:@"More than one face detected Please try again"
                                                                                          preferredStyle:UIAlertControllerStyleAlert];
                        
                        UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK"
                                                                           style:UIAlertActionStyleDefault
                                                                         handler:^(UIAlertAction * _Nonnull action) {
                            // Handle OK action here
                            // NSLog(@"OK button tapped");
                            //  [self performOKAction]; // Call your custom method here
                            [self dismissViewControllerAnimated:YES completion:^{
                                if (self.ProfileRegistrationHandler) {
                                    self->_profileImageResult= @{
                                        @"result": @"More than one face detected",
                                        @"status" : @""
                                    };
                                    self.ProfileRegistrationHandler(self.profileImageResult);
                                    [self.session stopRunning];
                                    [self dismissViewControllerAnimated:YES completion:nil];
                                }
                            }];
                        }];
                        [alertController addAction:okAction];
                        [self presentViewController:alertController animated:YES completion:nil];
                    });
                }  else {
                //    [self detectFaceInImage:image];
                    [self face:image type:self.type];
                    return;
                }
               

            }
        [self face:image type:self.type];
        }
    self.frameNum++;
}
- (void)detectFaceInImage:(UIImage *)image {
    // Create a request handler
    VNImageRequestHandler *handler = [[VNImageRequestHandler alloc] initWithCGImage:image.CGImage options:@{}];

    // Perform face detection
    NSError *error;
    [handler performRequests:@[self.faceDetectionRequest] error:&error];

    if (error) {
        NSLog(@"Error in face detection: %@", error.localizedDescription);
        return;
    }

    // Retrieve the face observations
    NSArray<VNFaceObservation *> *faceObservations = self.faceDetectionRequest.results;

    // Call your extractFace method with the detected face observations
    BOOL wellPositioned = [self extractFace:faceObservations];

    if (wellPositioned) {
        // Perform additional actions when faces are well positioned
        NSLog(@"Faces are well positioned");
    } else {
        // Handle the case when faces are not well positioned
        NSLog(@"Faces are not well positioned");
    }
}

- (BOOL)extractFace:(NSArray<VNFaceObservation *> *)faces {
    BOOL wellPositioned = faces.count > 0;

    for (VNFaceObservation *face in faces) {
        // Get the bounding box of the detected face
        CGRect faceBoundingBox = face.boundingBox;

        // Extract left and right position values
        CGFloat faceLeft = faceBoundingBox.origin.x;
        CGFloat faceRight = faceBoundingBox.origin.x + faceBoundingBox.size.width;
        NSLog(@"faceLeft: %f", faceLeft);
        NSLog(@"faceRight: %f", faceRight);
        // Do something with faceLeft and faceRight...

        // Perform your face extraction logic here based on the bounding box
        // You can integrate your existing face extraction logic from the extractFace method here
        // ...

        // Example: Check if the face is well positioned based on your existing conditions
//        if (faceLeft > thresholdX || faceRight < thresholdY) {
//            wellPositioned = NO;
//            break;
//        }
    }

    return wellPositioned;
}

- (void)performOKAction {
    [self dismissViewControllerAnimated:YES completion:^{
    }];
}
-(UIImage *)fixImageOrientation:(UIImage *)image {
    if (image.imageOrientation == UIImageOrientationUp) {
        return image;
    }
    
    UIGraphicsBeginImageContextWithOptions(image.size, NO, image.scale);
    [image drawInRect:(CGRect){0, 0, image.size}];
    UIImage *fixedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return fixedImage;
}


@end
