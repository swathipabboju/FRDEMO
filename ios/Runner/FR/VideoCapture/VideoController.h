//
//  VideoController.h
//  Runner
//
//  Created by CGG on 29/11/23.
//
 
#import <UIKit/UIKit.h>
#import "MTCNN.h"
#import "FaceAntiSpoofing.h"
#import "MobileFaceNet.h"
#import <AFNetworking.h>
//#import "PunchInDelegate.h"
//#import "PunchOutDelegate.h"
//#import "ForgotPunchoutDelegate.h"
//#import "faceNotDetectedDelegate.h"
//#import "FaceNotMatchedDelegate.h"
 
NS_ASSUME_NONNULL_BEGIN
 
@interface VideoController : UIViewController
 
@property (assign, nonatomic) int type;
@property (strong, nonatomic) MobileFaceNet *mfn;
@property (strong, nonatomic) FaceAntiSpoofing *fas;
@property (strong, nonatomic) MTCNN *mtcnn;
@property (strong, nonatomic) NSString *profileUrl;
@property (strong, nonatomic) UIImage* registredProfilePhoto;
@property (nonatomic) BOOL isAlertPresented;
@property (nonatomic, assign) BOOL punchInCalled;
@property (nonatomic, assign) BOOL punchOutCalled;
@property (nonatomic, assign) BOOL fotgotPunchOutCalled;
@property (assign, nonatomic) NSString *pictureClarityScore;
@property (assign, nonatomic) NSString *empId;
@property (assign, nonatomic) NSString *empName;
@property (nonatomic, copy) void (^PunchInresultHandler)(NSDictionary *resultDataIN);
@property (nonatomic, copy) void (^PunchOutresultHandler)(NSDictionary *resultDataOUT);
@property (nonatomic, copy) void (^ForgotPunchOutresultHandler)(NSDictionary *resultDataFORGOTPUNCHIN);
@property (assign, nonatomic) int movements;
@property (nonatomic, strong) NSMutableArray<NSNumber *> *booleanList;
@property (assign, nonatomic) BOOL isSpoofingalertPresented;
@property (assign, nonatomic) BOOL isEyeBlinkalertPresented;


 
 
//@property (nonatomic, weak) id<PunchInDelegate> delegateIn;
//@property (nonatomic, weak) id<PunchOutDelegate> delegateOut;
//@property (nonatomic, weak) id<forgotPunchOutDelegate> delegateForgotPunchOut;
//@property (nonatomic, weak) id<FaceNotDetctedDelegate> delegateFaceNotDetcted;
//@property (nonatomic, weak) id<FaceNotMatchedDelegate> delegateFaceNotMatched;
 
 
 
@end
 
NS_ASSUME_NONNULL_END
