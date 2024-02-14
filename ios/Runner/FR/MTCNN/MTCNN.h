//
//  MTCNN.h
//  Virtuo
//
//  Created by deep chandan on 13/09/23.
//  Copyright © 2023 CGG. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Box.h"
NS_ASSUME_NONNULL_BEGIN

@interface MTCNN : NSObject
- (NSArray<Box *> *)detectFaces:(UIImage *)image minFaceSize:(int)minFaceSize;

@end

NS_ASSUME_NONNULL_END
