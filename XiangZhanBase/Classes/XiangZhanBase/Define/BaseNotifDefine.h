//
//  BaseNotifDefine.h
//  XiangZhanBase
//
//  Created by jessy on 16/4/29.
//  Copyright © 2016年 TuWeiA. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

/*
    注意事项：Base里定义的通知，客户端和响站都应该能通用，否则放到具体工程里。
            添加的时候具体考量，是否客户端和响站都接收本通知
 */

UIKIT_EXTERN NSString *const Notif_LogOut; //退出登录通知

//聊天
UIKIT_EXTERN NSString *const IM_showMessageBox;  //显示消息框

UIKIT_EXTERN NSString *const IM_hideMessageBox;  //隐藏消息框

UIKIT_EXTERN NSString *const IM_openMessageWindow; //打开消息窗口

UIKIT_EXTERN NSString *const IM_closeMessageWindow; //关闭消息窗口

UIKIT_EXTERN NSString *const IM_setMessageNum; //设置消息数







