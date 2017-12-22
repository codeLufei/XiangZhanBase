//
//  BaseFileManager.h
//  XiangZhanBase
//
//  Created by jessy on 16/4/27.
//  Copyright © 2016年 TuWeiA. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BaseFileManager : NSObject
/**
 *  获得app文档目录
 *
 *  @return 目录地址
 */
+ (NSString *)appDocPath;

/**
 *  获得app的lib目录
 *
 *  @return lib目录地址
 */
+ (NSString *)appLibPath;

/**
 *  获得app文档目录
 *
 *  @return 目录地址
 */
+ (NSString *)appCachePath;

/**
 *  获得app临时文件夹目录
 *  用于存放临时文件，保存应用程序再次启动过程中不需要的信息
 *
 *  @return 目录地址
 */
+ (NSString *)appTmpPath;

/**
 *  h5下载路径
 *
 *  @return 目录地址
 */
+ (NSString *)appH5ManifesPath;

/**
 *  h5 appsources下载路径
 *
 *  @return 目录地址
 */
+ (NSString *)appH5AppSourcesPath;
@end
