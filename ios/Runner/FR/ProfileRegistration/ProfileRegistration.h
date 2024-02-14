//
//  ProfileRegistration.h
//  Runner
//
//  Created by CGG on 06/02/24.
//


#ifndef ProfileRegistration_h
#define ProfileRegistration_h


#endif /* ProfileRegistration_h */

 
#import <UIKit/UIKit.h>
#import "MTCNN.h"
#import "FaceAntiSpoofing.h"
#import "MobileFaceNet.h"
#import <AFNetworking.h>
#import <Vision/Vision.h>


 
NS_ASSUME_NONNULL_BEGIN
 
@interface ProfileRegistration : UIViewController
 
@property (assign, nonatomic) int type;
@property (strong, nonatomic) MobileFaceNet *mfn;
@property (strong, nonatomic) FaceAntiSpoofing *fas;
@property (strong, nonatomic) MTCNN *mtcnn;
@property (strong, nonatomic) NSString *profileUrl;
@property (strong, nonatomic) UIImage* registredProfilePhoto;
@property (nonatomic) BOOL isAlertPresented;
@property (nonatomic) BOOL isNofaceAlertPresented;
@property (nonatomic, assign) BOOL punchInCalled;
@property (nonatomic, assign) BOOL punchOutCalled;
@property (nonatomic, assign) BOOL fotgotPunchOutCalled;
@property (assign, nonatomic) NSString *pictureClarityScore;
@property (assign, nonatomic) NSString *empId;
@property (assign, nonatomic) NSString *empName;
@property (nonatomic, copy) void (^ProfileRegistrationHandler)(NSDictionary *resultDataProfile);

 
 
 
 
//@property (nonatomic, weak) id<PunchInDelegate> delegateIn;
//@property (nonatomic, weak) id<PunchOutDelegate> delegateOut;
//@property (nonatomic, weak) id<forgotPunchOutDelegate> delegateForgotPunchOut;
//@property (nonatomic, weak) id<FaceNotDetctedDelegate> delegateFaceNotDetcted;
//@property (nonatomic, weak) id<FaceNotMatchedDelegate> delegateFaceNotMatched;
 
 
 
@end
 
NS_ASSUME_NONNULL_END
