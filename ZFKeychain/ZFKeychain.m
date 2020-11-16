//
//  ZFKeychain.m
//  encharge_shopManager
//
//  Created by LYPC on 2020/6/24.
//  Copyright © 2020 张飞出行. All rights reserved.
//

#import "ZFKeychain.h"

NSString* const ZFDeviceSoleService = @"com.zhangfeichongdian.ios.deviceSole";

static NSString* const keychainErrorDomain = @"com.zhangfeichongdian.ios.keychain.errorDomain";
/** 传入的部分参数无效  */
static NSInteger const kErrorCodeKeychainSomeArgumentsInvalid = 1000;

@implementation ZFKeychain

/* 使用演示
 // sole是后台返回的该用户的设备标识
 NSString *sole = @"987653487658496";
 if (ISEMPTY(sole)) {
     // 还没绑定设备 存一下
     [ZFKeychain saveKeychainWithService:ZFDeviceSoleService content:@"987653487658496"];
 }else {
     // 查询本地存的 是否和后台返回的对应
     NSError *keychainError = [ZFKeychain queryKeychainWithService:ZFDeviceSoleService content:sole];
     if (keychainError.code == errSecSuccess) {
         NSLog(@"%@", [keychainError.userInfo valueForKey:NSLocalizedDescriptionKey]);
     }else {
         NSLog(@"%@", @"设备不匹配 联系后台重置设备");
     }
 }
 
 */


+ (NSError *)saveKeychainWithService:(NSString *)service
                             content:(NSString *)content {
    if (!content || !service) {
        NSError *error = [self errorWithErrorCode:kErrorCodeKeychainSomeArgumentsInvalid];
        return error;
    }
    
    NSError *queryError = [self queryKeychainWithService:service content:content];
    if (queryError.code == errSecSuccess) {
        // update
        return [self updateKeychainWithService:service content:content];
    }
    
    NSData *data = [content dataUsingEncoding:NSUTF8StringEncoding];
    // save
    NSDictionary *saveSecItems = @{(id)kSecClass: (id)kSecClassGenericPassword,
                                   (id)kSecAttrService: service,
                                   (id)kSecAttrAccount: content,
                                   (id)kSecValueData: data
                                  };
    OSStatus saveStatus = SecItemAdd((CFDictionaryRef)saveSecItems, NULL);
    return [self errorWithErrorCode:saveStatus];
}

+ (NSError *)deleteWithService:(NSString *)service
                       content:(NSString *)content {
    if (!service || !content) {
        return [self errorWithErrorCode:kErrorCodeKeychainSomeArgumentsInvalid];
    }
    NSDictionary *deleteSecItems = @{
                                    (id)kSecClass: (id)kSecClassGenericPassword,
                                    (id)kSecAttrService: service,
                                    (id)kSecAttrAccount: content
                                    };
    OSStatus errorCode = SecItemDelete((CFDictionaryRef)deleteSecItems);
    return [self errorWithErrorCode:errorCode];
}

+ (NSError *)queryKeychainWithService:(NSString *)service
                              content:(NSString *)content {
    if (!service || !content) {
        return [self errorWithErrorCode:kErrorCodeKeychainSomeArgumentsInvalid];
    }
    NSDictionary *matchSecItems = @{
                                    (id)kSecClass: (id)kSecClassGenericPassword,
                                    (id)kSecAttrService: service,
                                    (id)kSecAttrAccount: content,
                                    (id)kSecMatchLimit: (id)kSecMatchLimitOne,
                                    (id)kSecReturnData: @(YES)
                                    };
    CFTypeRef dataRef = nil;
    OSStatus errorCode = SecItemCopyMatching((CFDictionaryRef)matchSecItems, (CFTypeRef *)&dataRef);
    if (errorCode == errSecSuccess) {
        NSString *result = [[NSString alloc] initWithData:CFBridgingRelease(dataRef) encoding:NSUTF8StringEncoding];
        return [self errorWithErrorCode:errSecSuccess errorMessage:result];
    }
    return [self errorWithErrorCode:errorCode];
}

+ (NSError *)updateKeychainWithService:(NSString *)service
                               content:(NSString *)content {
    if (!content || !service) {
        NSError *error = [self errorWithErrorCode:kErrorCodeKeychainSomeArgumentsInvalid];
        return error;
    }
    NSDictionary *queryItems = @{(id)kSecClass: (id)kSecClassGenericPassword,
                                 (id)kSecAttrService: service,
                                 (id)kSecAttrAccount: content
                               };
    NSData *data = [content dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *updatedItems = @{
                                   (id)kSecValueData: data,
                                   };
    OSStatus updateStatus = SecItemUpdate((CFDictionaryRef)queryItems, (CFDictionaryRef)updatedItems);
    return [self errorWithErrorCode:updateStatus];
}

+ (NSError *)errorWithErrorCode:(OSStatus)errorCode {
    
    NSString *errorMsg = nil;
    switch (errorCode) {
        case errSecSuccess: {
            return nil;
            break;
        }
        case kErrorCodeKeychainSomeArgumentsInvalid:
            errorMsg = NSLocalizedString(@"参数无效", nil);
            break;
        case errSecDuplicateItem: // -25299
            errorMsg = NSLocalizedString(@"The specified item already exists in the keychain. ", nil);
            break;
        case errSecItemNotFound: // -25300
            errorMsg = NSLocalizedString(@"The specified item could not be found in the keychain. ", nil);
            break;
        default: {
            if (@available(iOS 11.3, *)) {
                errorMsg = (__bridge_transfer NSString *)SecCopyErrorMessageString(errorCode, NULL);
            }
            break;
        }
    }
    NSDictionary *errorUserInfo = nil;
    if (errorMsg) {
        errorUserInfo = @{NSLocalizedDescriptionKey: errorMsg};
    }
    return [NSError errorWithDomain:keychainErrorDomain code:kErrorCodeKeychainSomeArgumentsInvalid userInfo:errorUserInfo];
}

+ (NSError *)errorWithErrorCode:(OSStatus)errCode errorMessage:(NSString *)errorMsg {
    
    if (errCode == errSecSuccess && errorMsg) {
        return [NSError errorWithDomain:keychainErrorDomain code:errSecSuccess userInfo:@{NSLocalizedDescriptionKey: errorMsg}];
    } else {
        return [self errorWithErrorCode:errCode];
    }
}

@end
