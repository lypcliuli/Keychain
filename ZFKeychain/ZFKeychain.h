//
//  ZFKeychain.h
//  encharge_shopManager
//
//  Created by LYPC on 2020/6/24.
//  Copyright © 2020 张飞出行. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/** 设备唯一标识（采用userid+时间戳存起来）  */
FOUNDATION_EXTERN NSString* const ZFDeviceSoleService;

@interface ZFKeychain : NSObject

+ (NSError *)saveKeychainWithService:(NSString *)service
                             content:(NSString *)content;

+ (NSError *)deleteWithService:(NSString *)service
                       content:(NSString *)content;

+ (NSError *)queryKeychainWithService:(NSString *)service
                              content:(NSString *)content;

+ (NSError *)updateKeychainWithService:(NSString *)service
                               content:(NSString *)content;

@end

NS_ASSUME_NONNULL_END
