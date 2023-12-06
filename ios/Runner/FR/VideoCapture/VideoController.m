//
//  VideoController.m
//  Runner
//
//  Created by CGG on 29/11/23.
//

#import <Foundation/Foundation.h>
#import "VideoController.h"
#import <AVFoundation/AVFoundation.h>
#import "Tools.h"
#import "FaceAntiSpoofing.h"
#import "MobileFaceNet.h"

@interface VideoController () <AVCaptureVideoDataOutputSampleBufferDelegate>

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
@property (assign, nonatomic) UIImage* finalImage;
@property (strong, nonatomic) UIImage *inputImage;
@property (assign, nonatomic) NSData *verifiedFaceImageData;
@property (strong, nonatomic)UIActivityIndicatorView *activityIndicator;
@property (strong, nonatomic) IBOutlet UIImageView *profileView;
@property (nonatomic, strong) NSDictionary *resultData;
@property (nonatomic, strong) NSData *profileImageData;

@end

@implementation VideoController
- (void)viewDidLoad {
    [super viewDidLoad];
    _type = 1;
    self.isAlertPresented = NO;
    self.loadImage;
    //    NSLog(@"Image path IOS: %@", _filePath);
    
    
    //    NSString *imageURLString = _profileUrl;
    //    NSLog(@"_registredProfilePhoto: %@",_registredProfilePhoto);
    //    NSString *imageURLString = @"https://virtuo.cgg.gov.in/EmployeeProfileIcon/1970employeeimage20231009142548_044.png";
    //    NSURL *imageURL = [NSURL URLWithString:imageURLString];
    //
    //    NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithURL:imageURL completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
    //        if (error) {
    //            NSLog(@"Error fetching image: %@", error);
    //            return;
    //        }
    //
    //        if (data) {
    //            UIImage *image = [UIImage imageWithData:data];
    //            if (image) {
    //                // Use the image
    //                image = [self fixImageOrientation:image];
    //                _registredProfilePhoto = image;
    //
    //                dispatch_async(dispatch_get_main_queue(), ^{
    //                    // Update UI with the image (if needed)
    //                });
    //            } else {
    //                NSLog(@"Failed to convert data to image");
    //            }
    //        } else {
    //            NSLog(@"No image data received");
    //        }
    //    }];
    //  [task resume];
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
    });
}
- (void)loadImage {
    @try {
        // Get the application documents directory
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0];
        
        // Create a file path for the saved image
        NSString *imageName = @"profile.jpg"; // Replace with the actual image name
        NSString *imagePath = [documentsDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"images/%@", imageName]];
        
        // Check if the image file exists
        NSFileManager *fileManager = [NSFileManager defaultManager];
        
        if ([fileManager fileExistsAtPath:imagePath]) {
            // Load the image data
            // Load the image data
            NSData *imageData = [NSData dataWithContentsOfFile:imagePath];
            
            // Convert the image data to a UIImage
            UIImage *originalImage = [UIImage imageWithData:imageData];
            
            // Determine the correct orientation and create a new UIImage
            UIImage *fixedImage = [self fixImageOrientation:originalImage];
            NSLog(@"_registredProfilePhoto: %@",fixedImage);
            // Convert the fixed image data to a Base64-encoded string
            NSData *fixedImageData = UIImageJPEGRepresentation(fixedImage, 1.0);
            _profileImageData = fixedImageData;
            
            NSString *base64String = [fixedImageData base64EncodedStringWithOptions:0];
            
            // Print the Base64-encoded string
          //  NSLog(@"Image Data: %@", base64String);
            
            // Perform actions with the loaded image
            NSLog(@"Image loaded successfully");
            
        } else {
            NSLog(@"Image not found");
        }
    } @catch (NSException *exception) {
        NSLog(@"Error loading image: %@", [exception reason]);
    }
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
        [self setText:-1 score:0];
        self.isHandling = NO;
        return;
    }
    
    Box *box = boxes[0];
    [box toSquareShape];
    if ([box transboundW:(int)width H:(int)height]) {
        [self setText:-1 score:0];
        self.isHandling = NO;
        return;
    }
    //crop live image
    UIImage *cropImage = [Tools cropImage:image toRect:box.transform2Rect];
    _finalImage = cropImage;
    
    //  NSLog(@"_finalImage: %@", _finalImage);
    //  NSLog(@"_registredProfilePhoto: %@", _registredProfilePhoto);
    self.time++;
    
    int laplace = [self.fas laplacian:cropImage];
    // Save a string in NSUserDefaults
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setInteger:laplace forKey:@"imageLightning"];
    if (laplace < laplacian_threshold) {
        [self setText:laplace score:0];
        self.isHandling = NO;
        return;
    }
    float score = [self.fas antiSpoofing:cropImage];
    [userDefaults setFloat:score forKey:@"spoofing"];
    if (score > fas_threshold) {
        [self setText:laplace score:score];
        self.isHandling = NO;
        return;
    }
    float compare = 0;
    
    //  if (type == 2) {
    compare = [self.mfn compare:self.inputImage with:cropImage];
    NSLog(@"compare",compare);
    if (type == 1){
        // NSLog(@"_registredProfilePhoto: %@",_registredProfilePhoto);
        [self sendFormDataWithImages:_finalImage image2 :_registredProfilePhoto ];
    }
}





- (void)setText:(int)laplace score:(float)score {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (laplace == -1) {
            //   [self.session stopRunning];
            NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
            [userDefaults setObject:@"no face detected" forKey:@"reason"];
            self.resultLabel.text = @"no face detected";
            if (!self.isAlertPresented) {
                self.isAlertPresented = YES;
                UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Virtuo"
                                                                                         message:@"No face detected, Please try again"
                                                                                  preferredStyle:UIAlertControllerStyleAlert];
                
                UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK"
                                                                   style:UIAlertActionStyleDefault
                                                                 handler:^(UIAlertAction * _Nonnull action) {
                    // Handle OK action here
                    NSLog(@"OK button tapped");
                    // Call the result handler with the data
                    
                    if (self.PunchInresultHandler) {
                        self->_resultData= @{
                            @"result": @"No face Detected",
                            @"status" : @"punchIn"
                        };
                        self.PunchInresultHandler(self.resultData);
                        [self.session stopRunning];
                        [self dismissViewControllerAnimated:YES completion:nil];
                    }
                    if (self.PunchOutresultHandler) {
                        self->_resultData= @{
                            @"result": @"No face Detected",
                            @"status" : @"punchOut"
                        };
                        self.PunchOutresultHandler(self.resultData);
                        [self.session stopRunning];
                        [self dismissViewControllerAnimated:YES completion:nil];
                    }
                    if (self.ForgotPunchOutresultHandler) {
                        self->_resultData= @{
                            @"result": @"No face Detected",
                            @"status" : @"forgotPunchOut"
                        };
                        self.ForgotPunchOutresultHandler(self.resultData);
                        [self.session stopRunning];
                        [self dismissViewControllerAnimated:YES completion:nil];
                    }
                    //                    [self.delegateForgotPunchOut didReceiveDataForgotPunchOut:@"No face detected"image:nil];
                    
                }];
                [alertController addAction:okAction];
                [self presentViewController:alertController animated:YES completion:nil];
            }
            return;
        }
        
        NSString *text = [NSString stringWithFormat:@"Recognition times：%d\nPicture Clarity Score：%d", self.time, laplace];
        if (laplace > laplacian_threshold) {
            text = [text stringByAppendingFormat:@"\nliveness detection score：%f", score];
        }
        self.resultLabel.text = text;
        
    });
}

#pragma mark - AVCaptureVideoDataOutputSampleBufferDelegate
- (void)captureOutput:(AVCaptureOutput *)output didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    //    NSLog(@"frameNum : %ld",(long)self.frameNum);
    //    NSLog(@"isHandling: %d",!self.isHandling);
    //    NSLog(@"typre: %i",self.type);
    if (self.frameNum > 15 && !self.isHandling) {
        self.isHandling = YES;
        UIImage *image = [self convertSampleBufferToImage:sampleBuffer];
        [self face:image type:self.type];
    }
    self.frameNum++;
}

-  (void)sendFormDataWithImages:(UIImage *)finalCroppedImage  image2:(UIImage *)regImg {
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            [_activityIndicator startAnimating];
        });
        //   NSString *urlString=@"https://frapp1.cgg.gov.in/api/v1/verification/verify";
        //    NSString *urlString=@"https://faceapp.cgg.gov.in/api/v1/verification/verify";
        
        NSString *urlString=@"https://facialrecognition.cgg.gov.in/Face/Facematch";
        NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init] ;
        [request setURL:[NSURL URLWithString:urlString]];
        [request setHTTPMethod:@"POST"];
        
        NSMutableData *body = [NSMutableData data];
        
        NSString *boundary = @"---------------------------14737809831466499882746641449";
        NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@", boundary];
        [request addValue:contentType forHTTPHeaderField:@"Content-Type"];
        
        // file
        float low_bound = 0;
        float high_bound =5000;
        float rndValue = (((float)arc4random()/0x100000000)*(high_bound-low_bound)+low_bound);//image1
        int intRndValue = (int)(rndValue + 0.5);
        NSString *str_image1 = [@(intRndValue) stringValue];
        
        // UIImage *chosenImage1=[UIImage imageNamed:@"teju.jpg"];
        
        NSData *imageData = UIImageJPEGRepresentation(finalCroppedImage, 0);
        [body appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"source_image\"; filename=\"%@.jpg\"\r\n",str_image1] dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[@"Content-Type: application/octet-stream\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[NSData dataWithData:imageData]];
        [body appendData:[@"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
        
        
        
        // Replace this path with the actual path to your file
        //   NSString *filePath = @"/var/mobile/Containers/Data/Application/6613C022-0454-4A8B-9C9D-F3ECFA60D955/Documents/profile.jpg";
        
        
        if (_profileImageData) {
            // Image data is available, you can use it as needed
            NSLog(@"Success to read image data from file: %@");
            UIImage *image = [UIImage imageWithData:_profileImageData];
            // Now 'image' contains the UIImage representation of the image file
            //  NSData *imageData1 = UIImageJPEGRepresentation(regImg, 0);
            [body appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
            [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"target_image\"; filename=\"%@.jpg\"\r\n",str_image1] dataUsingEncoding:NSUTF8StringEncoding]];
            [body appendData:[@"Content-Type: application/octet-stream\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
            [body appendData:[NSData dataWithData:_profileImageData]];
            [body appendData:[@"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
        } else {
            // Failed to read image data from the file path
            NSLog(@"Failed to read image data from file: %@", _profileImageData);
        }
        //        NSData *imageData1 = UIImageJPEGRepresentation(regImg, 0);
        //        [body appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
        //        [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"target_image\"; filename=\"%@.jpg\"\r\n",str_image1] dataUsingEncoding:NSUTF8StringEncoding]];
        //        [body appendData:[@"Content-Type: application/octet-stream\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
        //        [body appendData:[NSData dataWithData:imageData1]];
        //        [body appendData:[@"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
        
        
        NSDictionary *headers = @{
            @"x-api-key": @"7e37e740-ab21-47c1-8431-b1b69ac21d25", // Replace with your actual access token
        };
        //        NSDictionary *headers = @{
        //            @"x-api-key": @"c359dd17-0389-4704-8365-3845a9012bed", // Replace with your actual access token
        //        };
        //
        
        for (NSString *key in headers.allKeys) {
            [request setValue:headers[key] forHTTPHeaderField:key];
        }
        // close form
        [body appendData:[[NSString stringWithFormat:@"--%@--\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
        // set request body
        [request setHTTPBody:body];
        //return and test
        NSData *returnData = [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:nil];
        NSString *returnString = [[NSString alloc] initWithData:returnData encoding:NSUTF8StringEncoding];
        NSLog(@"%@1234", returnString);
        [self.session stopRunning];
        // Stop the activity indicator when the API call is complete
        dispatch_async(dispatch_get_main_queue(), ^{
            [_activityIndicator stopAnimating];
        });
        // Convert the response string to NSData
        NSData *responseData = [returnString dataUsingEncoding:NSUTF8StringEncoding];
        NSError *error = nil;
        NSDictionary *responseDict = [NSJSONSerialization JSONObjectWithData:responseData options:kNilOptions error:&error];
        id result = responseDict[@"result"];
        
        if ([responseDict isKindOfClass:[NSDictionary class]]) {
            NSDictionary *responseDict = (NSDictionary *)responseDict;
            // Check if the "result" field is null
            if ([result isKindOfClass:[NSNull class]]) {
                // Handle the response with null result
                NSString *message = responseDict[@"message"];
                NSString *code = responseDict[@"code"];
                NSLog(@"Null Result - Message: %@, Code: %@", message, code);
                NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
                [userDefaults setObject:code forKey:@"reason"];
                
                //   NSLog(@" Code: %@", code);
                dispatch_async(dispatch_get_main_queue(), ^{
                    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Virtuo"
                                                                                             message:@"Server not responding, Please try again"
                                                                                      preferredStyle:UIAlertControllerStyleAlert];
                    
                    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK"
                                                                       style:UIAlertActionStyleDefault
                                                                     handler:^(UIAlertAction * _Nonnull action) {
                        // Handle OK action here
                        // NSLog(@"OK button tapped");
                        //  [self performOKAction]; // Call your custom method here
                        [self dismissViewControllerAnimated:YES completion:^{
                            //                            [self.delegateForgotPunchOut didReceiveDataForgotPunchOut:@"face not matched"image:finalCroppedImage];
                        }];
                    }];
                    [alertController addAction:okAction];
                    [self presentViewController:alertController animated:YES completion:nil];
                });
            } else if ([result isKindOfClass:[NSArray class]]){
                NSLog(@"resilttttttttt");
                // NSArray *resultArray = responseDict[@"result"];
                NSArray *resultArray = result;
                if (resultArray.count > 0) {
                    NSDictionary *firstResult = resultArray[0];
                    NSArray *faceMatches = firstResult[@"face_matches"];
                    if (faceMatches.count > 0) {
                        NSDictionary *firstFaceMatch = faceMatches[0];
                        NSNumber *similarity = firstFaceMatch[@"similarity"];
                        float similarityValue = [similarity floatValue];
                        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
                        [userDefaults setFloat:similarityValue forKey:@"similarityValue"];
                        [userDefaults setObject:@"face matched" forKey:@"reason"];
                        // Multiply by 100
                        float similarityPercentage = similarityValue * 100;
                        //float similarityPercentage = 40.00;
                        // Create an NSNumberFormatter to format the similarity percentage value
                        NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
                        [numberFormatter setNumberStyle:NSNumberFormatterDecimalStyle];
                        [numberFormatter setMaximumFractionDigits:2]; // Set maximum fraction digits to 2
                        NSString *formattedSimilarity = [numberFormatter stringFromNumber:@(similarityPercentage)];
                        
                        NSLog(@"Similarity: %@%%", formattedSimilarity);
                        if (similarityPercentage > 85.00){
                            dispatch_async(dispatch_get_main_queue(), ^{
                                [self dismissViewControllerAnimated:YES completion:^{
                                    
                                    if (self.PunchInresultHandler) {
                                        _resultData= @{
                                            @"result": @"face Matched",
                                            @"status" : @"punchIn"
                                        };
                                        
                                        self.PunchInresultHandler(self.resultData);
                                        [self.session stopRunning];
                                        [self dismissViewControllerAnimated:YES completion:nil];
                                    }
                                    if (self.PunchOutresultHandler) {
                                        _resultData= @{
                                            @"result": @"face Matched",
                                            @"status" : @"punchOut"
                                            
                                        };
                                        self.PunchOutresultHandler(self.resultData);
                                        [self.session stopRunning];
                                        [self dismissViewControllerAnimated:YES completion:nil];
                                    }
                                    if (self.ForgotPunchOutresultHandler) {
                                        _resultData= @{
                                            @"result": @"face Matched",
                                            @"status" : @"forgotPunchOut"
                                            
                                        };
                                        self.ForgotPunchOutresultHandler(self.resultData);
                                        [self.session stopRunning];
                                        [self dismissViewControllerAnimated:YES completion:nil];
                                    }
                                    // Example: Accessing resultData
                                    NSLog(@"Result Data ios xcode: %@", self.resultData);
                                    //                                    if (self->_punchInCalled == true){
                                    //                                        [self.delegateIn didReceiveDataPunchIn:@"Data from Objective-C"image:finalCroppedImage];
                                    //                                    } else if (self->_punchOutCalled == true){
                                    //                                        [self.delegateOut didReceiveDataPunchOut:@"Data from Objective-C"image:finalCroppedImage];
                                    //                                    } else if  (self->_fotgotPunchOutCalled == true) {
                                    //                                        [self.delegateForgotPunchOut didReceiveDataForgotPunchOut:@"forgot punchout true "image:finalCroppedImage];
                                    //                                    }
                                }];
                                
                            });
                            
                        } else {
                            dispatch_async(dispatch_get_main_queue(), ^{
                                UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Virtuo"
                                                                                                         message:@"face not matched,Please try again"
                                                                                                  preferredStyle:UIAlertControllerStyleAlert];
                                
                                UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK"
                                                                                   style:UIAlertActionStyleDefault
                                                                                 handler:^(UIAlertAction * _Nonnull action) {
                                    // Handle OK action here
                                    // NSLog(@"OK button tapped");
                                    //   [self performOKAction];
                                    
                                    if (self.PunchInresultHandler) {
                                        _resultData= @{
                                            @"result": @"face Not Matched",
                                            @"status" : @"punchIn"
                                            
                                        };
                                        self.PunchInresultHandler(self.resultData);
                                        [self.session stopRunning];
                                        [self dismissViewControllerAnimated:YES completion:nil];
                                    }
                                    if (self.PunchOutresultHandler) {
                                        _resultData= @{
                                            @"result": @"face Not Matched",
                                            @"status" : @"punchOut"
                                            
                                        };
                                        self.PunchOutresultHandler(self.resultData);
                                        [self.session stopRunning];
                                        [self dismissViewControllerAnimated:YES completion:nil];
                                    }
                                    if (self.ForgotPunchOutresultHandler) {
                                        _resultData= @{
                                            @"result": @"face Not Matched",
                                            @"status" : @"forgotPunchOut"
                                            
                                        };
                                        self.ForgotPunchOutresultHandler(self.resultData);
                                        [self.session stopRunning];
                                        [self dismissViewControllerAnimated:YES completion:nil];
                                    }
                                    [self dismissViewControllerAnimated:YES completion:^{
                                        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
                                        [userDefaults setObject:@"face not matched" forKey:@"reason"];
                                        //                                        [self.delegateForgotPunchOut didReceiveDataForgotPunchOut:@"face not matched"image:finalCroppedImage];
                                        
                                    }];// Call your custom method here
                                }];
                                [alertController addAction:okAction];
                                [self presentViewController:alertController animated:YES completion:nil];
                            });
                        }
                    }
                }
            } else {
                if (error) {
                    NSLog(@"Error parsing JSON: %@", error);
                    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
                    [userDefaults setObject:error.localizedDescription forKey:@"reason"];
                    dispatch_async(dispatch_get_main_queue(), ^{
                        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Virtuo"
                                                                                                 message:@"Server not responding, Please try again"
                                                                                          preferredStyle:UIAlertControllerStyleAlert];
                        
                        UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK"
                                                                           style:UIAlertActionStyleDefault
                                                                         handler:^(UIAlertAction * _Nonnull action) {
                            // Handle OK action here
                            // NSLog(@"OK button tapped");
                            //   [self performOKAction]; // Call your custom method here
                            [self dismissViewControllerAnimated:YES completion:^{
                                //                                [self.delegateForgotPunchOut didReceiveDataForgotPunchOut:@"face not matched"image:finalCroppedImage];
                                
                            }];
                        }];
                        [alertController addAction:okAction];
                        [self presentViewController:alertController animated:YES completion:nil];
                    });
                }
            }
            
            
        }
        
    }
}
- (void)performOKAction {
    NSLog(@"_finalImage: %@",_finalImage);
    
    [self dismissViewControllerAnimated:YES completion:^{
        /*  [self.delegateForgotPunchOut didReceiveDataForgotPunchOut:@"face not matched"image:self->_finalImage]*/;
        
    }];
}

// Define a completion block to handle the downloaded image data
typedef void (^ImageDataCompletionHandler)(NSData * _Nullable imageData, NSError * _Nullable error);

// Function to fetch image data from a URL
- (void)fetchImageDataFromURL:(NSURL *)imageUrl completionHandler:(ImageDataCompletionHandler)completionHandler {
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLRequest *request = [NSURLRequest requestWithURL:imageUrl];
    
    NSURLSessionDataTask *dataTask = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (error) {
            NSLog(@"Error fetching image data: %@", error.localizedDescription);
            completionHandler(nil, error);
            return;
        }
        
        if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
            NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
            if (httpResponse.statusCode == 200) {
                // Successfully fetched the image data
                completionHandler(data, nil);
            } else {
                // Received a non-200 HTTP status code
                NSError *statusError = [NSError errorWithDomain:@"HTTPError" code:httpResponse.statusCode userInfo:nil];
                completionHandler(nil, statusError);
            }
        }
    }];
    
    [dataTask resume];
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
