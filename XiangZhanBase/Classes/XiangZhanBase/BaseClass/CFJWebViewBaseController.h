//
//  CFJWebViewBaseController.h
//  XiangZhanBase
//
//  Created by cuifengju on 2017/10/13.
//  Copyright © 2017年 TuWeiA. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WebViewJavascriptBridge.h"

typedef void(^DownloadBodyFinish)();
@interface CFJWebViewBaseController : UIViewController
@property (strong, nonatomic) WebViewJavascriptBridge* bridge;
@property (strong, nonatomic) UIWebView *webView;
@property (strong, nonatomic) NSString *webViewDomain;
@property (copy, nonatomic) WVJBResponseCallback webviewBackCallBack;
@property (assign, nonatomic) BOOL isWebViewLoading;
@property (strong, nonatomic) id requestData;
//判断页面是否已经存在
@property (assign, nonatomic) BOOL isExist;
@property (nonatomic,copy) NSString *Type;
//是否横屏
@property (nonatomic, assign) BOOL LandscapeRight;

@property (strong, nonatomic) NSLayoutConstraint *webViewLeftConstraint;
@property (strong, nonatomic) NSLayoutConstraint *webViewRightConstraint;
@property (strong, nonatomic) NSLayoutConstraint *webViewHeightConstraint;
@property (strong, nonatomic) NSLayoutConstraint *webViewWidthConstraint;

@property (assign, nonatomic) BOOL isCreat;//是否创建通知
///导航条配置字典
@property (nonatomic, strong) NSDictionary *navDic;
///js 调用 objc 方法
- (void)jsCallObjc:(id)jsData jsCallBack:(WVJBResponseCallback)jsCallBack;

///objc 调用 js 方法
- (void)objcCallJs:(NSDictionary *)dic;

- (void)domainOperate;

- (void)loadHtml;

- (void)loadWebBridge;


- (void)downloadHtmlBodyWithUrl:(NSString *)urlStr needLoadPage:(BOOL)loadPage complete:(DownloadBodyFinish)callBack;
@end
