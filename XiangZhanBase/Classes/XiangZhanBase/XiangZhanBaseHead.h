//
//  XiangZhanBaseHead.h
//  XiangZhanBase
//
//  Created by tuweia on 16/4/26.
//  Copyright © 2016年 TuWeiA. All rights reserved.
//

//测试环境宏定义 测试时为1 正式为0
#define kIsDebug 0
//TODO_RELEASE 把银联支付环境改为正式环境
//银联支付的环境 "00"代表正式环境，"01"代表测试环境
#define kMode_Development @"00"

//TODO 内外网设置
#if kIsDebug==1
#define Domain @"http://192.168.1.178:9002"
#define UploadDomain @"http://tuweile.com"
#define XiangJianAppH5Version @"1.8.3.2"
#define MainDomain @"tuweile.com"
#define AppMainDomain @".app.tuweile.com"
#else

#define Domain @"http://api.suishidao.net"
#define UploadDomain @"http://admin.suishidao.net"
#define XiangJianAppH5Version @"1.8.3.2"
#define MainDomain @"suishidao.net"
#define AppMainDomain @".app.suishidao.net"
#endif

#import "XZTableViewCell.h"
#import "BaseNotifDefine.h"
#import "XZWebBaseViewController.h"
#import "PublicSettingModel.h"
