#ifndef MobileFaceNet_h
#define MobileFaceNet_h
 
#import <UIKit/UIKit.h>
 
static float mfn_threshold = 0.8f; // 设置一个阙值，大于这个值认为是同一个人
 
NS_ASSUME_NONNULL_BEGIN
 
@interface MobileFaceNet : NSObject
 
/**
比较两张人脸图片
*/
- (float)compare:(UIImage *)image1 with:(UIImage *)image2;
 
@end
 
NS_ASSUME_NONNULL_END
 
#endif /* MobileFaceNet_h */
