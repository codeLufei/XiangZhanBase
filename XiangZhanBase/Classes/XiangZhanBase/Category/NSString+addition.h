//
//  NSString+addition.h
//  TuiYa
//
//  Created by jessy on 15/6/15.
//  Copyright (c) 2015年 tuweia. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface NSString (addition)

+ (NSString *)nowTimeString;

+ (NSString *)randomTimeString;

+ (NSString *)randomImageName;

//获取url key value值
+ (NSDictionary*)dictionaryFromQuery:(NSString*)query usingEncoding:(NSStringEncoding)encoding;

+ (BOOL)checkCellPhoneNumber:(NSString *)phoneNumber;

//对用户密码进行加密
- (NSString *)encryptUserPassword;

+ (CGSize)getStringSize:(NSString *)str andFont:(UIFont *)font andSize:(CGSize)s;

+ (NSString*)urlWithParam:(NSDictionary*)dic andHead:(NSString*)head;

+ (NSString*)encodeString:(NSString*)unencodedString ;

//复制链接
+ (void)copyLink:(NSString *)linkStr;
@end
