//
//  Tools.h
//  Runner
//
//  Created by CGG on 16/11/23.
//
 
#ifndef Tools_h
#define Tools_h
 
#import <UIKit/UIKit.h>
 
NS_ASSUME_NONNULL_BEGIN
 
@interface Tools : NSObject
 
// 获取文件路径
+ (NSString *)filePathForResourceName:(NSString *)name extension:(NSString *)extension;
 
// UIImage和uint8_t互转
+ (UInt8 *)convertUIImageToBitmapRGBA8:(UIImage *)image;
+ (UIImage *)convertBitmapRGBA8ToUIImage:(uint8_t *)buffer withWidth:(int)width withHeight:(int)height;
 
// 缩放图片
+ (UIImage *)scaleImage:(UIImage *)image toSize:(CGSize)size;
+ (UIImage *)scaleImage:(UIImage *)image toScale:(float)scale;
 
// 裁剪图片
+ (UIImage *)cropImage:(UIImage *)image toRect:(CGRect)rect;
 
// UIImage转灰度图
+ (UInt8 *)convertUIImageToBitmapGray:(UIImage *)image;
 
@end
 
NS_ASSUME_NONNULL_END
 
#endif /* Tools_h */
