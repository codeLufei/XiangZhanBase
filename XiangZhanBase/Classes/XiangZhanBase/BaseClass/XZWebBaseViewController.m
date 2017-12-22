//
//  TYWebBaseViewController.m
//  TuiYa
//
//  Created by jessy on 15/7/26.
//  Copyright (c) 2015年 tuweia. All rights reserved.
//

#import "XZWebBaseViewController.h"
#import "XZNavigationController.h"
#import "UIColor+addition.h"
#import "XZFunctionDefine.h"
#import "UIWebView+addition.h"
#import "BaseNotifDefine.h"
#import "NSArray+safe.h"
#import "BaseFileManager.h"
#import "AFHTTPSessionManager.h"
#import "NSString+addition.h"
#import "XiangZhanBaseHead.h"
#import "HTMLCache.h"
#import "XZOrderModel.h"
#import "RNCachingURLProtocol.h"
#import "Reachability.h"
#import "UIView+AutoLayout.h"
#import "EGOCache.h"
#import "MJRefresh.h"
#import "Masonry.h"
#define ScreenWidth [UIScreen mainScreen].bounds.size.width
#define iOS11Later ([UIDevice currentDevice].systemVersion.floatValue >= 11.0f)
#define kDevice_Is_iPhoneX ([UIScreen instancesRespondToSelector:@selector(currentMode)] ? CGSizeEqualToSize(CGSizeMake(1125, 2436), [[UIScreen mainScreen] currentMode].size) : NO)

@interface XZWebBaseViewController () <UIWebViewDelegate,UIScrollViewDelegate>
{
    __block int timeout; //倒计时时间
}
@property (strong, nonatomic) NSString *htmlStr;
@property (strong, nonatomic) NSString *appsourceBasePath;
@property (strong, nonatomic) UIButton *networkNoteBt;
@property (strong, nonatomic) UIView *networkNoteView;

@property (strong,nonatomic)UIActivityIndicatorView *activityIndicatorView;
/** 上次选中的索引(或者控制器) */
@property (nonatomic, assign) NSInteger lastSelectedIndex;
@property (nonatomic, assign) BOOL isLoading;
@property (nonatomic, assign) BOOL isActive;
@property (nonatomic, strong) dispatch_source_t timer;

@end

@implementation XZWebBaseViewController
- (UIWebView *)webView {
    if (_webView == nil) {
        _webView = [[UIWebView alloc] init];
        [_webView setDelegate:self];
        _webView.scrollView.delegate = self;
        _webView.scrollView.scrollsToTop = YES;
        _webView.scrollView.showsVerticalScrollIndicator = NO;
        _webView.scrollView.showsHorizontalScrollIndicator = NO;
        _webView.scrollView.bounces = YES;
        //设置滑动速度
        _webView.scrollView.decelerationRate = UIScrollViewDecelerationRateNormal;
    }
    return _webView;
}
- (UIView *)networkNoteView {
    if (_networkNoteView == nil) {
        _networkNoteView = [[UIView alloc]initWithFrame:CGRectMake(0, 20, ScreenWidth, 44)];
        _networkNoteView.backgroundColor = [UIColor colorWithHexString:
                                            [[NSUserDefaults standardUserDefaults] objectForKey:@"StatusBarBackgroundColor"]];
    }
    return _networkNoteView;
}
- (UIActivityIndicatorView *)activityIndicatorView {
    if (_activityIndicatorView == nil) {
        _activityIndicatorView = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(0, 0, 50, 50)];
        [_activityIndicatorView setCenter:self.view.center];
        [_activityIndicatorView setActivityIndicatorViewStyle:UIActivityIndicatorViewStyleGray];    }
    return _activityIndicatorView;
}
- (void)dealloc
{
    self.webView.delegate = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)addNotifi {
    WEAK_SELF;
    //RefreshAllVCNotif 下载成功以后刷新所有页面
    [[NSNotificationCenter defaultCenter] addObserverForName:@"RefreshAllVCNotif" object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification * _Nonnull note) {
        STRONG_SELF;
        UIViewController *vc = note.object;
        [[HTMLCache sharedCache] removeObjectForKey:self.webViewDomain];
        [self downloadHtmlBodyWithUrl:self.webViewDomain needLoadPage:NO complete:^{
            [self domainOperate];
        }];
    }];
    
    //RefreshAllVCNotif 客户端登陆成功或者退出成功以后刷新其他页面
    [[NSNotificationCenter defaultCenter] addObserverForName:@"RefreshOtherAllVCNotif" object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification * _Nonnull note) {
        STRONG_SELF;
        UIViewController *vc = note.object;
        if (self == vc) {
            return ;
        }
        [[HTMLCache sharedCache] removeObjectForKey:self.webViewDomain];
        [self downloadHtmlBodyWithUrl:self.webViewDomain needLoadPage:NO complete:^{
            [self domainOperate];
        }];
    }];
#pragma mark ---CFJ新加
    [[NSNotificationCenter defaultCenter] addObserverForName:@"refreshCurrentViewController" object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification * _Nonnull note) {
        STRONG_SELF;
        if (self.lastSelectedIndex == self.tabBarController.selectedIndex && [self isShowingOnKeyWindow] && self.isWebViewLoading)  {
            if ([Reachability reachabilityForInternetConnection].currentReachabilityStatus == NotReachable) {
                return;
            }
            if ([self.webView.scrollView.mj_header isRefreshing]) {
                [self.webView.scrollView.mj_header endRefreshing];
            }
            [self.webView.scrollView.mj_header beginRefreshing];
        }
        // 记录这一次选中的索引
        self.lastSelectedIndex = self.tabBarController.selectedIndex;
    }];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    if (iOS11Later) {
        self.webView.scrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    }
    else {
        self.automaticallyAdjustsScrollViewInsets =  NO;
    }
    __weak UIScrollView *scrollView = self.webView.scrollView;
    MJRefreshNormalHeader *header = [MJRefreshNormalHeader headerWithRefreshingTarget:self refreshingAction:@selector(loadNewData)];
    //    // 添加下拉刷新控件
    //    scrollView.mj_header= [MJRefreshNormalHeader headerWithRefreshingBlock:^{
    //            if ([Reachability reachabilityForInternetConnection].currentReachabilityStatus == NotReachable) {
    //                return;
    //            }
    //            [[HTMLCache sharedCache] removeObjectForKey:self.webViewDomain];
    //            [self domainOperate];
    //            [[NSNotificationCenter defaultCenter]postNotificationName:@"reloadMessage" object:nil];
    //    }];
    // 设置回调（一旦进入刷新状态，就调用target的action，也就是调用self的loadNewData方法）
    //    MJChiBaoZiHeader *header = [MJChiBaoZiHeader headerWithRefreshingTarget:self refreshingAction:@selector(loadNewData)];
    //    // 隐藏时间
    header.lastUpdatedTimeLabel.hidden = YES;
    //    // 隐藏状态
    //    header.stateLabel.hidden = YES;
    //    // 添加下拉刷新控件
    scrollView.mj_header= header;
    self.navigationController.interactivePopGestureRecognizer.enabled = YES;
    [self addNotifi];
    [self addWebView];
    [self.view addSubview:self.activityIndicatorView];
    [_activityIndicatorView startAnimating];
    [NSURLProtocol registerClass:[RNCachingURLProtocol class]];
    [self netWorkButton];
}
- (void)loadNewData{
    if ([Reachability reachabilityForInternetConnection].currentReachabilityStatus == NotReachable) {
        if ([self.webView.scrollView.mj_header isRefreshing]) {
            [self.webView.scrollView.mj_header endRefreshing];
        }
        return;
    }
    [[HTMLCache sharedCache] removeObjectForKey:self.webViewDomain];
    [self domainOperate];
}
//添加断网,或者网络问题导致页面加载失败的按钮处理
- (void)netWorkButton {
    self.networkNoteBt = [UIButton buttonWithType:UIButtonTypeCustom];
    self.networkNoteBt.frame = CGRectMake(0, 64, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height - 64);
    [self.networkNoteBt setImage:[UIImage imageNamed:@"network_1242_2016"] forState:UIControlStateNormal];
    [self.networkNoteBt setImage:[UIImage imageNamed:@"network_1242_2016"] forState:UIControlStateHighlighted];
    [self.networkNoteBt addTarget:self action:@selector(networkNoteBtClick) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.networkNoteBt];
    [self.view addSubview:self.networkNoteView];
    self.networkNoteBt.hidden = YES;
    self.networkNoteView.hidden = YES;
}
- (void)networkNoteBtClick {
    if ([Reachability reachabilityForInternetConnection].currentReachabilityStatus == NotReachable) {
        return ;
    }
    [self.view addSubview:self.activityIndicatorView];
    [_activityIndicatorView startAnimating];
    self.networkNoteBt.hidden = YES;
    self.networkNoteView.hidden = YES;
    [self downloadHtmlBodyWithUrl:self.webViewDomain needLoadPage:YES complete:^{
        [self domainOperate];
    }];
    
}


- (void)viewWillAppear:(BOOL)animated {
    if (self.isExist) {
        NSDictionary *dataDic = @{@"result":@"success"};
        NSDictionary *callJsDic = [UIWebView objcCallJsWithFn:@"currentPage" data:nil];
        [self objcCallJs:callJsDic];
    }
    self.isExist = YES;
    self.isActive = YES;
    self.navigationController.navigationBarHidden = YES;
    
}
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    // 记录这一次选中的索引
    self.lastSelectedIndex = self.tabBarController.selectedIndex;
    [self listenToTimer];
}
- (void)viewWillDisappear:(BOOL)animated {
    self.isActive = NO;
    self.lastSelectedIndex = 100;
    if (self.timer) {
        dispatch_source_cancel(self.timer);
        self.timer = nil;
    }
    if ([self.webView.scrollView.mj_header isRefreshing]) {
        [self.webView.scrollView.mj_header endRefreshing];
    }
}
- (void)listenToTimer {
    self.isActive = YES;
    if(self.networkNoteView.hidden) {
        if (self.timer) {
            dispatch_source_cancel(self.timer);
            self.timer = nil;
        }
        dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
        self.timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0,queue);
        dispatch_source_set_timer(_timer,dispatch_walltime(NULL, 0),1.0*NSEC_PER_SEC, 0); //每秒执行
        timeout = 6;
        dispatch_source_set_event_handler(_timer, ^{
            if(timeout<=0){ //倒计时结束，关闭
                if (self.isLoading) {
                    dispatch_source_cancel(_timer);
                }
                else {
                    WEAK_SELF;
                    dispatch_async(dispatch_get_main_queue(), ^{
                        STRONG_SELF;
                        if ([Reachability reachabilityForInternetConnection].currentReachabilityStatus == NotReachable) {
                            return;
                        }
                        [[HTMLCache sharedCache] removeObjectForKey:self.webViewDomain];
                        [self domainOperate];
                    });
                }
            }
            else{
                if (self.isLoading) {
                    dispatch_source_cancel(_timer);
                }
                else {
                    timeout--;
                }
            }
        });
        dispatch_resume(_timer);
    }
    else {
        dispatch_source_cancel(self.timer);
        self.timer = nil;
    }
}

- (void)addWebView {
    self.statusView = [[UIView alloc] init];
    [self.view addSubview:self.statusView];
    [self.statusView autoPinEdgeToSuperviewEdge:ALEdgeLeft withInset:0];
    [self.statusView autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:0];
    [self.statusView autoPinEdgeToSuperviewEdge:ALEdgeRight withInset:0];
    [self.statusView autoSetDimension:ALDimensionHeight toSize:kDevice_Is_iPhoneX ? 44 : 20];
    
    NSString *statusBarBackgroundColor = [[NSUserDefaults standardUserDefaults] objectForKey:@"StatusBarBackgroundColor"];
    NSString *statusBarTextColor = [[NSUserDefaults standardUserDefaults] objectForKey:@"StatusBarTextColor"];
    NSNumber *statusBarStatus = [[NSUserDefaults standardUserDefaults] objectForKey:@"StatusBarStatus"];
    self.statusView.backgroundColor = [UIColor colorWithHexString:statusBarBackgroundColor];
    
    if ([statusBarTextColor isEqualToString:@"#000000"] || [statusBarTextColor isEqualToString:@"black"]) {
        [UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleDefault;
    }
    else {
        [UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleLightContent;
    }
    
    if (statusBarStatus.integerValue == 1) {
        self.statusView.hidden = NO;
        [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationNone];
    }
    else {
        self.statusView.hidden = YES;
        [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationNone];
    }
    
    [self.view insertSubview:self.webView belowSubview:self.navBar];
    //    self.webViewLeftConstraint = [self.webView autoPinEdgeToSuperviewEdge:ALEdgeLeft withInset:0];
    //    self.webViewHeightConstraint = [self.webView autoSetDimension:ALDimensionHeight toSize:[UIScreen mainScreen].bounds.size.height - (kDevice_Is_iPhoneX ? 78 : 20)];
    //    self.webViewRightConstraint = [self.webView autoPinEdgeToSuperviewEdge:ALEdgeRight withInset:0];
    //    [self.webView autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:kDevice_Is_iPhoneX ? 44 : 20];
    if (self.navigationController.viewControllers.count > 1 && kDevice_Is_iPhoneX) {
        [self.webView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self.view);
            make.right.equalTo(self.view);
            make.bottom.mas_equalTo(self.view.mas_bottom).offset(-34);
            make.top.equalTo(self.statusView.mas_bottom);
        }];
    }
    else {
        if ([[NSUserDefaults standardUserDefaults] boolForKey:@"NoTabBar"]) {
            [self.webView mas_makeConstraints:^(MASConstraintMaker *make) {
                make.left.equalTo(self.view);
                make.right.equalTo(self.view);
                make.bottom.equalTo(self.view).offset(49);
                make.top.equalTo(self.statusView.mas_bottom);
            }];
        }
        else {
            [self.webView mas_makeConstraints:^(MASConstraintMaker *make) {
                make.left.equalTo(self.view);
                make.right.equalTo(self.view);
                make.bottom.equalTo(self.view);
                make.top.equalTo(self.statusView.mas_bottom);
            }];
        }
        
    }
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    self.statusView.frame = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, 20);
}


//加载html 响站全部用app.phtml 客户端全部用page.phtml
- (void)loadHtml{
    [self replaceHtmlPhpString];
    if (self.htmlStr) {
        NSString *headerHtml = nil;
        headerHtml = [HTMLCache sharedCache].pageHtml;
        NSString *allHtmlStr = [headerHtml stringByReplacingOccurrencesOfString:@"<!--body-->" withString:self.htmlStr];
        [self.webView loadHTMLString:allHtmlStr baseURL:[HTMLCache sharedCache].htmlBaseUrl];
        //注意，一个webview bridge只能有一次，否则失败
        if (!self.bridge) {
            [self loadWebBridge];
        }
        self.isWebViewLoading = NO;
    }
}

- (void)loadWebBridge
{
#ifdef DEBUG
    [WebViewJavascriptBridge enableLogging];
#endif
    
    WEAK_SELF;
    //    self.bridge = [WebViewJavascriptBridge bridgeForWebView:self.webView webViewDelegate:self handler:^(id data, WVJBResponseCallback responseCallback) {
    //    }];
    
    self.bridge = [WebViewJavascriptBridge bridgeForWebView:self.webView];
    [self.bridge setWebViewDelegate:self];
    //注册方法，h5页面可以调用
    [self.bridge registerHandler:@"xzBridge" handler:^(id data, WVJBResponseCallback responseCallback) {
        STRONG_SELF;
        if ([data isKindOfClass:[NSDictionary class]]) {
            [self jsCallObjc:data jsCallBack:responseCallback];
        }
    }];
}

- (void)domainOperate {
    self.isLoading = NO;
    [self listenToTimer];
    if (kIsDebug) {
        self.webViewDomain = [self.webViewDomain stringByReplacingOccurrencesOfString:@"xiangzhan" withString:@"tuweile"];
    }
    
    NSString *urlWithoutHttp = [[self.webViewDomain componentsSeparatedByString:@"://"] safeObjectAtIndex:1];
    NSString *host = [[urlWithoutHttp componentsSeparatedByString:@"/"] safeObjectAtIndex:0];
    NSArray *domainAry = [host componentsSeparatedByString:@"."];
    NSString *domain = [NSString stringWithFormat:@"%@.%@",[domainAry safeObjectAtIndex:domainAry.count - 2],[domainAry safeObjectAtIndex:domainAry.count - 1]];
    
    if ([self.webViewDomain rangeOfString:@"://"].length <= 0) {
        [self loadTemplateHtml];
        return;
    }
    
    if ([domain isEqualToString:MainDomain] || ([host rangeOfString:AppMainDomain].length > 0)) {
        
        NSString *filePath = nil;
        if ([host rangeOfString:AppMainDomain].length > 0) {
            NSArray *urlAry = [self.webViewDomain componentsSeparatedByString:@"://"];
            NSString *appUrl = [urlAry safeObjectAtIndex:1];
            NSArray *appAry = [appUrl componentsSeparatedByString:@"."];
            NSString *appName = [appAry safeObjectAtIndex:0];
            
            //获取html地址
            NSArray *h5Ary = [appUrl componentsSeparatedByString:@"/"];
            NSString *h5Name = h5Ary.count > 2 ? [h5Ary safeObjectAtIndex:2] : @"index";
            NSString *appsourcePath = [NSString stringWithFormat:@"%@/manifest/appsources",[BaseFileManager appDocPath]];
            filePath = [NSString stringWithFormat:@"%@/%@/%@/%@.phtml",appsourcePath,appName,[h5Ary safeObjectAtIndex:1],h5Name];
            self.appsourceBasePath = [NSString stringWithFormat:@"%@/%@",appsourcePath,appName];
        }
        else if ([domain isEqualToString:MainDomain]) {
            NSString *domainStr = [[urlWithoutHttp componentsSeparatedByString:@"?"] safeObjectAtIndex:0];
            NSArray *urlAry = [domainStr componentsSeparatedByString:@"/"];
            filePath = [NSString stringWithFormat:@"%@/template/%@/%@.phtml",[BaseFileManager appH5ManifesPath],[urlAry safeObjectAtIndex:1],[urlAry safeObjectAtIndex:2]];
        }
        
        if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
            self.htmlStr = [NSString stringWithContentsOfURL:[NSURL fileURLWithPath:filePath] encoding:NSUTF8StringEncoding error:nil];
            [self loadHtml];
        }
        else {
            [self downloadHtmlBodyWithUrl:self.webViewDomain needLoadPage:YES];
        }
        return;
    }
    else {
        [self downloadHtmlBodyWithUrl:self.webViewDomain needLoadPage:YES];
    }
}

- (void)jsCallObjc:(id)jsData jsCallBack:(WVJBResponseCallback)jsCallBack {
    
    NSLog(@"****jscallobjc : %@",jsData);
    NSDictionary *jsDic = (NSDictionary *)jsData;
    NSString *function = [jsDic objectForKey:@"action"];
    NSDictionary *dataDic = [jsDic objectForKey:@"data"];
    
    if ([function isEqualToString:@"cookie"]) {
        [UIWebView cookieJSOperateCookie:dataDic path:self.webViewDomain];
    }
    
    if ([function isEqualToString:@"rpc"]) {
        NSString *deviceTokenStr = [[NSUserDefaults standardUserDefaults] objectForKey:@"User_ChannelId"];
        deviceTokenStr = deviceTokenStr ? deviceTokenStr : @"";
        
        NSString *newSiteId = [[NSUserDefaults standardUserDefaults] objectForKey:@"User_OpenedWebSiteID"] ? [[NSUserDefaults standardUserDefaults] objectForKey:@"User_OpenedWebSiteID"] : @"";
        
        
        if ([[dataDic objectForKey:@"requestUrl"] isEqualToString:@"/user/mobileLogin"]) {
            NSMutableDictionary *requestDataDic = [[dataDic objectForKey:@"requestData"] mutableCopy];
            NSString *password = [requestDataDic objectForKey:@"password"];
            password = [password encryptUserPassword];
            [requestDataDic setObject:password forKey:@"password"];
            [requestDataDic setObject:deviceTokenStr forKey:@"channel"];
            NSMutableDictionary *mutableDataDic = [dataDic mutableCopy];
            [mutableDataDic setObject:requestDataDic forKey:@"requestData"];
            [self rpcRequestWithJsDic:mutableDataDic jsCallBack:jsCallBack];
            NSDictionary *newSiteDic = @{
                                         @"siteIdNew" : newSiteId,
                                         @"siteIdOld" : @"",
                                         @"channel" : deviceTokenStr
                                         };
            [self requestOpenSite:newSiteDic];
            return;
        }
        if ([[dataDic objectForKey:@"requestUrl"] isEqualToString:@"/my/updateUserPassword"]) {
            NSMutableDictionary *mutableDataDic = dataDic.mutableCopy;
            NSDictionary *requestData = [dataDic objectForKey:@"requestData"];
            NSMutableDictionary *mutableRequestData = requestData.mutableCopy;
            [mutableRequestData setObject:deviceTokenStr forKey:@"channel"];
            [mutableRequestData setObject:[[requestData objectForKey:@"oldpassword"] encryptUserPassword] forKey:@"oldpassword"];
            [mutableRequestData setObject:[[requestData objectForKey:@"newpassword"] encryptUserPassword] forKey:@"newpassword"];
            [mutableDataDic setObject:mutableRequestData forKey:@"requestData"];
            [self rpcRequestWithJsDic:mutableDataDic jsCallBack:jsCallBack];
            NSDictionary *newSiteDic = @{
                                         @"siteIdNew" : newSiteId,
                                         @"siteIdOld" : @"",
                                         @"channel" : deviceTokenStr
                                         };
            [self requestOpenSite:newSiteDic];
            return;
        }
        if ([[dataDic objectForKey:@"requestUrl"] isEqualToString:@"/user/mobileReg"]) {
            NSMutableDictionary *mutableDataDic = dataDic.mutableCopy;
            NSDictionary *requestData = [dataDic objectForKey:@"requestData"];
            NSMutableDictionary *mutableRequestData = requestData.mutableCopy;
            [mutableRequestData setObject:deviceTokenStr forKey:@"channel"];
            [mutableRequestData setObject:[[requestData objectForKey:@"password"] encryptUserPassword] forKey:@"password"];
            [mutableDataDic setObject:mutableRequestData forKey:@"requestData"];
            [self rpcRequestWithJsDic:mutableDataDic jsCallBack:jsCallBack];
            NSDictionary *newSiteDic = @{
                                         @"siteIdNew" : newSiteId,
                                         @"siteIdOld" : @"",
                                         @"channel" : deviceTokenStr
                                         };
            [self requestOpenSite:newSiteDic];
            return;
        }
        
        //忘记密码
        if ([[dataDic objectForKey:@"requestUrl"] isEqualToString:@"/user/forgotUserPassword"]) {
            NSMutableDictionary *mutableDataDic = dataDic.mutableCopy;
            NSDictionary *requestData = [dataDic objectForKey:@"requestData"];
            NSMutableDictionary *mutableRequestData = requestData.mutableCopy;
            [mutableRequestData setObject:[[requestData objectForKey:@"password"] encryptUserPassword] forKey:@"password"];
            [mutableDataDic setObject:mutableRequestData forKey:@"requestData"];
            [self rpcRequestWithJsDic:mutableDataDic jsCallBack:jsCallBack];
            NSDictionary *newSiteDic = @{
                                         @"siteIdNew" : newSiteId,
                                         @"siteIdOld" : @"",
                                         @"channel" : deviceTokenStr
                                         };
            [self requestOpenSite:newSiteDic];
            return;
            
        }
        //客户端登录
        if ([[dataDic objectForKey:@"requestUrl"] isEqualToString:@"/appmodule/user/api/signIn"]) {
            NSMutableDictionary *requestDataDic = [[dataDic objectForKey:@"requestData"] mutableCopy];
            NSString *password = [requestDataDic objectForKey:@"password"];
            password = [password encryptUserPassword];
            [requestDataDic setObject:password forKey:@"password"];
            [requestDataDic setObject:deviceTokenStr forKey:@"channel"];
            NSMutableDictionary *mutableDataDic = [dataDic mutableCopy];
            [mutableDataDic setObject:requestDataDic forKey:@"requestData"];
            [self rpcRequestWithJsDic:mutableDataDic jsCallBack:jsCallBack];
            return;
        }
        //客户端注册
        if ([[dataDic objectForKey:@"requestUrl"] isEqualToString:@"/appmodule/user/api/signUp"]) {
            NSMutableDictionary *requestDataDic = [[dataDic objectForKey:@"requestData"] mutableCopy];
            NSString *password = [requestDataDic objectForKey:@"password"];
            password = [password encryptUserPassword];
            [requestDataDic setObject:password forKey:@"password"];
            [requestDataDic setObject:deviceTokenStr forKey:@"channel"];
            NSMutableDictionary *mutableDataDic = [dataDic mutableCopy];
            [mutableDataDic setObject:requestDataDic forKey:@"requestData"];
            [self rpcRequestWithJsDic:mutableDataDic jsCallBack:jsCallBack];
            return;
        }
        //客户端修改密码
        if ([[dataDic objectForKey:@"requestUrl"] isEqualToString:@"/appmodule/user/api/editUserPwd"]) {
            NSMutableDictionary *mutableDataDic = dataDic.mutableCopy;
            NSDictionary *requestData = [dataDic objectForKey:@"requestData"];
            NSMutableDictionary *mutableRequestData = requestData.mutableCopy;
            [mutableRequestData setObject:deviceTokenStr forKey:@"channel"];
            [mutableRequestData setObject:[[requestData objectForKey:@"wornPwd"] encryptUserPassword] forKey:@"wornPwd"];
            [mutableRequestData setObject:[[requestData objectForKey:@"newPwd"] encryptUserPassword] forKey:@"newPwd"];
            [mutableDataDic setObject:mutableRequestData forKey:@"requestData"];
            [self rpcRequestWithJsDic:mutableDataDic jsCallBack:jsCallBack];
            return;
        }
        //客户端找回密码
        if ([[dataDic objectForKey:@"requestUrl"] isEqualToString:@"/appmodule/user/api/findPwd"]) {
            NSMutableDictionary *mutableDataDic = dataDic.mutableCopy;
            NSDictionary *requestData = [dataDic objectForKey:@"requestData"];
            NSMutableDictionary *mutableRequestData = requestData.mutableCopy;
            [mutableRequestData setObject:deviceTokenStr forKey:@"channel"];
            [mutableRequestData setObject:[[requestData objectForKey:@"password"] encryptUserPassword] forKey:@"password"];
            [mutableRequestData setObject:[mutableRequestData objectForKey:@"password"] forKey:@"password1"];
            [mutableDataDic setObject:mutableRequestData forKey:@"requestData"];
            [self rpcRequestWithJsDic:mutableDataDic jsCallBack:jsCallBack];
            return;
        }
        [self rpcRequestWithJsDic:dataDic jsCallBack:jsCallBack];
    }
    
    if ([function isEqualToString:@"freshView"]) {
        
    }
    
    //响站打开站点方法
    if ([function isEqualToString:@"openSite"]) {
        //        opensite以后操作
        //        1.刷新首页
        //        2.关闭所有已经打开的页面
        //        3，刷新侧边栏
        //        4，更新存储的siteid
        //        5.刷新聊天界面
        NSString *newSiteId = [dataDic objectForKey:@"siteId"];
        NSString *oldSiteId = [[NSUserDefaults standardUserDefaults] objectForKey:@"User_OpenedWebSiteID"] ? [[NSUserDefaults standardUserDefaults] objectForKey:@"User_OpenedWebSiteID"] : @"";
        if ([newSiteId isEqualToString:oldSiteId]) return;
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"User_OpenedWebSite"];
        [[NSUserDefaults standardUserDefaults] setObject:newSiteId forKey:@"User_OpenedWebSiteID"];
        [[NSUserDefaults standardUserDefaults] setObject:[dataDic objectForKey:@"siteName"] forKey:@"User_OpenedWebSiteName"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        [self dismissViewControllerAnimated:YES completion:nil];
        [self.navigationController popToRootViewControllerAnimated:YES];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"Notif_RefreshHome" object:nil];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"refreshSlideH5Notif" object:nil];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"refreshIMH5Notif" object:nil];
        
        //存储 站点id cookie
        NSDictionary *usertokenOptionDic = @{
                                             @"domain" : [NSString stringWithFormat:@".%@",MainDomain],
                                             @"path" : @"/",
                                             @"expires" : @(90)
                                             };
        NSDictionary *usertokenCookieDic = @{
                                             @"name" : @"xzSiteId",
                                             @"value" : newSiteId,
                                             @"options" : usertokenOptionDic
                                             };
        [UIWebView cookieJSOperateCookie:usertokenCookieDic path:nil];
        
        NSString *deviceToken = [[NSUserDefaults standardUserDefaults] objectForKey:@"User_ChannelId"] ? [[NSUserDefaults standardUserDefaults] objectForKey:@"User_ChannelId"] : @"";
        NSDictionary *newSiteDic = @{
                                     @"siteIdNew" : newSiteId,
                                     @"siteIdOld" : oldSiteId,
                                     @"channel" : deviceToken
                                     };
        [self requestOpenSite:newSiteDic];
    }
    
    //刷新侧边栏
    if ([function isEqualToString:@"freshLeftSide"]) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"refreshSlideH5Notif" object:nil];
    }
    
    if ([function isEqualToString:@"backAndFresh"]) {
        XZWebBaseViewController *vc = [self.navigationController.viewControllers safeObjectAtIndex:self.navigationController.viewControllers.count - 2];
        [[HTMLCache sharedCache] removeObjectForKey:vc.webViewDomain];
        [vc domainOperate];
        if (self.navigationController.viewControllers.count >= 2) {
            [self.navigationController popViewControllerAnimated:YES];
        }
        else {
            [self dismissViewControllerAnimated:YES completion:nil];
        }
    }
    
    if ([function isEqualToString:@"backAndCall"]) {
        
        XZWebBaseViewController *vc = [self.navigationController.viewControllers safeObjectAtIndex:self.navigationController.viewControllers.count - 2];
        NSDictionary *callJsDic = [UIWebView objcCallJsWithFn:[dataDic objectForKey:@"action"] data:[dataDic objectForKey:@"data"]];
        [vc objcCallJs:callJsDic];
        if (self.navigationController.viewControllers.count >= 2) {
            [self.navigationController popViewControllerAnimated:YES];
        }
        else {
            [self dismissViewControllerAnimated:YES completion:nil];
        }
    }
    
    if ([function isEqualToString:@"backTab"]) {
        if (self.navigationController.viewControllers.count >= 2) {
            [self.navigationController popViewControllerAnimated:YES];
        }
        else {
            [self dismissViewControllerAnimated:YES completion:nil];
        }
    }
    
    if ([function isEqualToString:@"reload"]) {
        if ([Reachability reachabilityForInternetConnection].currentReachabilityStatus == NotReachable) {
            return;
        }
        [[HTMLCache sharedCache] removeObjectForKey:self.webViewDomain];
        [self domainOperate];
    }
    
    if ([function isEqualToString:@"pay"]) {
        self.webviewBackCallBack = jsCallBack;
        [self payRequest:dataDic];
    }
    
    if ([function isEqualToString:@"preloadPages"]) {
        //如果网络不畅通，不缓存；
        if ([Reachability reachabilityForInternetConnection].currentReachabilityStatus == NotReachable) {
            return;
        }
        //TODO 处理预加载
        NSArray *urls = [dataDic objectForKey:@"urls"];
        for (NSString *url in urls) {
            //如果缓存中有，取得缓存数据，不再从网络加载
            NSString *htmlStr = [[HTMLCache sharedCache] objectForKey:url];
            if (htmlStr) {
                continue;
            }
            else if ([Reachability reachabilityForInternetConnection].currentReachabilityStatus == ReachableViaWiFi) {
                WEAK_SELF;
                dispatch_async(dispatch_get_global_queue(0, 0), ^(void) {
                    STRONG_SELF;
                    [self preloadHtmlBodyWithUrl:url :htmlStr];
                });
            }
            else {
                continue;
            }
        }
    }
    
    if ([function isEqualToString:@"userSignin"]) {
        //刷新其他页面
        [[HTMLCache sharedCache] removeAllCache];
        NSString *portrait = [NSString stringWithFormat:@"%@%@",@"http://okgo.top/",[dataDic objectForKey:@"portrait"]];
        [[NSUserDefaults standardUserDefaults] setObject:dataDic[@"userid"] forKey:@"login_website_uid"];
        [[NSUserDefaults standardUserDefaults] setObject:portrait forKey:@"avatarURLPath"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"RefreshOtherAllVCNotif" object:self];
    }
    if ([function isEqualToString:@"pageReady"]) {
        self.isLoading = YES;
        if ([self.webView.scrollView.mj_header isRefreshing]) {
            [self.webView.scrollView.mj_header endRefreshing];
        }    }
    if ([function isEqualToString:@"userSignout"]) {
        //清除cookie、刷新其他页面
        [[HTMLCache sharedCache] removeAllCache];
        [UIWebView cookieDeleteAllCookie];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"RefreshOtherAllVCNotif" object:self];
        
        //退出后firstLoadMessageWindow标志设为no 并且杀掉聊天页面
        [[NSNotificationCenter defaultCenter] postNotificationName:@"stopImH5ViewController" object:nil];
    }
    
    //显示消息框
    if ([function isEqualToString:@"showMessageBox"]) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"jsShowMessageBox" object:nil];
    }
    
    //隐藏消息框
    //    if ([function isEqualToString:@"hideMessageBox"]) {
    //        [[NSNotificationCenter defaultCenter] postNotificationName:@"jsHideMessageBox" object:nil];
    //    }
    
    ///显示隐藏左右侧边栏
    if ([function isEqualToString:@"showLeftSide"]) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"showLeftSideNotif" object:nil];
    }
    
    if ([function isEqualToString:@"hideLeftSide"]) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"hideLeftSideNotif" object:nil];
    }
    
    if ([function isEqualToString:@"showRightSide"]) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"showRightSideNotif" object:nil];
    }
    
    if ([function isEqualToString:@"hideRightSide"]) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"hideRightSideNotif" object:nil];
    }
    
    ///显示隐藏底部tabbar
    if ([function isEqualToString:@"hideBottomNavbar"]) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"HideTabBarNotif" object:nil];
    }
    
    if ([function isEqualToString:@"showBottomNavbar"]) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"ShowTabBarNotif" object:nil];
    }
    
    //设置消息数字
    if ([function isEqualToString:@"setMessageNum"]) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"setMessageNum" object:dataDic];
    }
    
    //打开消息窗口
    if ([function isEqualToString:@"openMessageWindow"]) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"openMessageWindow" object:nil];
    }
    
    //关闭消息窗口
    if ([function isEqualToString:@"closeMessageWindow"]) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"closeMessageWindow" object:nil];
    }
    
    //清除缓存
    if ([function isEqualToString:@"clearCache"]) {
        [[HTMLCache sharedCache] removeAllCache];
        jsCallBack(@{@"result":@"success"});
    }
    
    //复制发送的内容
    if ([function isEqualToString:@"copy"]) {
        [NSString copyLink:[dataDic objectForKey:@"content"]];
        jsCallBack(@{@"result":@"success"});
    }
    
    if ([function isEqualToString:@"loadMessageWindow"]) {
        BOOL firstLoadMessageWindow = [[NSUserDefaults standardUserDefaults] boolForKey:@"firstLoadMessageWindow"];
        if (!firstLoadMessageWindow) {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"loadMessageWindow" object:nil];
        }
    }
}

- (void)downloadHtmlBodyWithUrl:(NSString *)urlStr needLoadPage:(BOOL)loadPage {
    [self downloadHtmlBodyWithUrl:urlStr needLoadPage:loadPage complete:nil];
}

- (void)downloadHtmlBodyWithUrl:(NSString *)urlStr needLoadPage:(BOOL)loadPage complete:(DownloadBodyFinish)callBack {
    //如果缓存中有，取得缓存数据，不再从网络加载
    self.htmlStr = [[HTMLCache sharedCache] objectForKey:urlStr];
    if (self.htmlStr) {
        if (loadPage) {
            [self loadHtml];
        }
    }
    else {
        BOOL advertising = [[NSUserDefaults standardUserDefaults] boolForKey:@"hasAdvertising"];
        BOOL guidepage = [[NSUserDefaults standardUserDefaults] boolForKey:@"hasGuidepage"];
        AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
        manager.responseSerializer = [AFHTTPResponseSerializer serializer];
        manager.requestSerializer = [AFHTTPRequestSerializer serializer];
        if(ISIPAD) {
            [manager.requestSerializer setValue:@"iospad" forHTTPHeaderField:@"from"];
        } else {
            [manager.requestSerializer setValue:@"ios" forHTTPHeaderField:@"from"];
        }
        [manager.requestSerializer setValue:[[NSUserDefaults standardUserDefaults]
                                             objectForKey:@"User_Token_String"] forHTTPHeaderField:@"AUTHORIZATION"];
        manager.requestSerializer.timeoutInterval = 5;
        NSLog(@"User_Token_String:%@",[[NSUserDefaults standardUserDefaults] objectForKey:@"User_Token_String"]);
        urlStr = [urlStr stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        if (!urlStr) {
            return;
        }
        NSArray *storageCookieAry = [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookiesForURL:[NSURL URLWithString:urlStr]];
        NSLog(@"请求body__cookie : %@",storageCookieAry);
        [manager GET:urlStr parameters:nil progress:nil success:^(NSURLSessionDataTask *task, id responseObject) {
            
            if (callBack) {
                callBack();
            }
            NSString *newHtmlStr = [[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding];
            if (newHtmlStr && ![self.htmlStr isEqualToString:newHtmlStr]) {
                if (loadPage) {
                    self.htmlStr = newHtmlStr;
                    [self loadHtml];
                }
                [[HTMLCache sharedCache] cacheHtml:self.htmlStr key:urlStr];
            }
            NSArray *storageCookieAry = [NSHTTPCookieStorage sharedHTTPCookieStorage].cookies;
            NSLog(@"storageCookieAry____: %@",storageCookieAry);
            
            if (!advertising && !guidepage) {
                if ([[UIApplication sharedApplication].keyWindow viewWithTag:2001]) {
                    __block UIView *View = [[UIApplication sharedApplication].keyWindow viewWithTag:2001];
                    View.alpha = 1.0;
                    [UIView animateWithDuration:0.5 animations:^{
                        View.alpha = 0.0;
                    } completion:^(BOOL finished) {
                        [View removeFromSuperview];
                        View.alpha = 1.0;
                    }];
                    
                }
            }
            
        } failure:^(NSURLSessionDataTask *task, NSError *error) {
            if (!advertising && !guidepage) {
                if ([[UIApplication sharedApplication].keyWindow viewWithTag:2001]) {
                    __block UIView *View = [[UIApplication sharedApplication].keyWindow viewWithTag:2001];
                    View.alpha = 1.0;
                    [UIView animateWithDuration:0.5 animations:^{
                        View.alpha = 0.0;
                    } completion:^(BOOL finished) {
                        [View removeFromSuperview];
                        View.alpha = 1.0;
                    }];
                    
                }
            }
            if ([self.webView.scrollView.mj_header isRefreshing]) {
                [self.webView.scrollView.mj_header endRefreshing];
            }
            if (!self.htmlStr) {
                self.networkNoteBt.hidden = NO;
                self.networkNoteView.hidden = NO;
                [self.view bringSubviewToFront:self.networkNoteView];
                [self.view bringSubviewToFront:self.networkNoteBt];
                [self.activityIndicatorView stopAnimating];
                [self.activityIndicatorView removeFromSuperview];
                return ;
            }
            [self.webView.scrollView.mj_header endRefreshing];
        }];
        return;
    }
    NSString *keyStr = self.webViewDomain;
    keyStr=[keyStr stringByReplacingOccurrencesOfString:@"/" withString:@"_"];
    keyStr=[keyStr stringByReplacingOccurrencesOfString:@":" withString:@"_"];
    keyStr=[keyStr stringByReplacingOccurrencesOfString:@"." withString:@"_"];
    keyStr=[keyStr stringByReplacingOccurrencesOfString:@"-" withString:@"_"];
    if (![[EGOCache globalCache] hasCacheForKey:keyStr]) {
        BOOL advertising = [[NSUserDefaults standardUserDefaults] boolForKey:@"hasAdvertising"];
        BOOL guidepage = [[NSUserDefaults standardUserDefaults] boolForKey:@"hasGuidepage"];
        AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
        manager.responseSerializer = [AFHTTPResponseSerializer serializer];
        manager.requestSerializer = [AFHTTPRequestSerializer serializer];
        if(ISIPAD) {
            [manager.requestSerializer setValue:@"iospad" forHTTPHeaderField:@"from"];
        } else {
            [manager.requestSerializer setValue:@"ios" forHTTPHeaderField:@"from"];
        }
        manager.requestSerializer.timeoutInterval = 5;
        [manager.requestSerializer setValue:[[NSUserDefaults standardUserDefaults] objectForKey:@"User_Token_String"] forHTTPHeaderField:@"AUTHORIZATION"];
        NSLog(@"User_Token_String:%@",[[NSUserDefaults standardUserDefaults] objectForKey:@"User_Token_String"]);
        urlStr = [urlStr stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        if (!urlStr) {
            return;
        }
        NSArray *storageCookieAry = [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookiesForURL:[NSURL URLWithString:urlStr]];
        NSLog(@"请求body__cookie : %@",storageCookieAry);
        [manager GET:urlStr parameters:nil progress:nil success:^(NSURLSessionDataTask *task, id responseObject) {
            
            if (callBack) {
                callBack();
            }
            NSString *newHtmlStr = [[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding];
            if (newHtmlStr && ![self.htmlStr isEqualToString:newHtmlStr]) {
                self.htmlStr = newHtmlStr;
                [self loadHtml];
                [[HTMLCache sharedCache] cacheHtml:self.htmlStr key:urlStr];
            }
            NSArray *storageCookieAry = [NSHTTPCookieStorage sharedHTTPCookieStorage].cookies;
            NSLog(@"storageCookieAry____: %@",storageCookieAry);
            
            if (!advertising && !guidepage) {
                if ([[UIApplication sharedApplication].keyWindow viewWithTag:2001]) {
                    __block UIView *View = [[UIApplication sharedApplication].keyWindow viewWithTag:2001];
                    View.alpha = 1.0;
                    [UIView animateWithDuration:0.5 animations:^{
                        View.alpha = 0.0;
                    } completion:^(BOOL finished) {
                        [View removeFromSuperview];
                        View.alpha = 1.0;
                    }];
                    
                }
            }
            
        } failure:^(NSURLSessionDataTask *task, NSError *error) {
            if (!advertising && !guidepage) {
                if ([[UIApplication sharedApplication].keyWindow viewWithTag:2001]) {
                    __block UIView *View = [[UIApplication sharedApplication].keyWindow viewWithTag:2001];
                    View.alpha = 1.0;
                    [UIView animateWithDuration:0.5 animations:^{
                        View.alpha = 0.0;
                    } completion:^(BOOL finished) {
                        [View removeFromSuperview];
                        View.alpha = 1.0;
                    }];
                    
                }
            }
            if ([self.webView.scrollView.mj_header isRefreshing]) {
                [self.webView.scrollView.mj_header endRefreshing];
            }
            if (!self.htmlStr) {
                self.networkNoteBt.hidden = NO;
                self.networkNoteView.hidden = NO;
                [self.view bringSubviewToFront:self.networkNoteView];
                [self.view bringSubviewToFront:self.networkNoteBt];
                [self.activityIndicatorView stopAnimating];
                [self.activityIndicatorView removeFromSuperview];
                return ;
            }
        }];
    }
}

#pragma mark -------- 预加载方法
- (void)preloadHtmlBodyWithUrl:(NSString *)url :(NSString *)oldStr {
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    if (self.isActive) {
        manager.responseSerializer = [AFHTTPResponseSerializer serializer];
        manager.requestSerializer = [AFHTTPRequestSerializer serializer];
        if(ISIPAD) {
            [manager.requestSerializer setValue:@"iospad" forHTTPHeaderField:@"from"];
        } else {
            [manager.requestSerializer setValue:@"ios" forHTTPHeaderField:@"from"];
        }
        [manager.requestSerializer setValue:[[NSUserDefaults standardUserDefaults]
                                             objectForKey:@"User_Token_String"] forHTTPHeaderField:@"AUTHORIZATION"];
        manager.requestSerializer.timeoutInterval = 5;
        url = [url stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        if (!url) {
            return;
        }
        [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookiesForURL:[NSURL URLWithString:url]];
        [manager GET:url parameters:nil progress:nil success:^(NSURLSessionDataTask *task, id responseObject) {
            NSString *newHtmlStr = [[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding];
            if (newHtmlStr && ![oldStr isEqualToString:newHtmlStr]) {
                [[HTMLCache sharedCache] cacheHtml:newHtmlStr key:url];
            }
            NSArray *storageCookieAry = [NSHTTPCookieStorage sharedHTTPCookieStorage].cookies;
        } failure:^(NSURLSessionDataTask *task, NSError *error) {
        }];
    }
}

//加载template文件夹下的html
- (void)loadTemplateHtml {
    NSString *domainStr = [[self.webViewDomain componentsSeparatedByString:@"?"] safeObjectAtIndex:0];
    NSArray *urlAry = [domainStr componentsSeparatedByString:@"/"];
    NSString *filePath = [NSString stringWithFormat:@"%@/template/%@/%@.phtml",[BaseFileManager appH5ManifesPath],[urlAry safeObjectAtIndex:1],[urlAry safeObjectAtIndex:2]];
    if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
        NSURL *htmlUrl = [NSURL fileURLWithPath:filePath];
        self.htmlStr = [NSString stringWithContentsOfURL:htmlUrl encoding:NSUTF8StringEncoding error:nil];
        //本地html 全部用 app.pthml
        [self loadHtml];
    }
    else {
        NSString *urlStr = [NSString stringWithFormat:@"http://%@%@",MainDomain,self.webViewDomain];
        [self downloadHtmlBodyWithUrl:urlStr needLoadPage:YES];
    }
}

- (void)replaceHtmlPhpString {
    self.htmlStr = [self.htmlStr stringByReplacingOccurrencesOfString:@"<?php echo static_path?>" withString:@"static"];
    self.htmlStr = [self.htmlStr stringByReplacingOccurrencesOfString:@"<?php echo static_path ?>" withString:@"static"];
    if (self.appsourceBasePath) {
        self.htmlStr = [self.htmlStr stringByReplacingOccurrencesOfString:@"<?php echo STATIC_APP_PATH ?>" withString:[NSString stringWithFormat:@"%@/static",self.appsourceBasePath]];
        self.htmlStr = [self.htmlStr stringByReplacingOccurrencesOfString:@"<?php echo $appurl;?>" withString:@""];
    }
}

#pragma mark - WebViewDelegate -

- (void)webViewDidStartLoad:(UIWebView *)webView {
    
}
- (void)webViewDidFinishLoad:(UIWebView *)webView {
    
    if (!self.isWebViewLoading) {
        id data = self.requestData ? self.requestData : @"";
        NSDictionary *callJsDic = [UIWebView objcCallJsLoadPageParamWithHtml:self.htmlStr url:self.webViewDomain requestData:data];
        [self objcCallJs:callJsDic];
        //首页用tag值标记  当首页加载完成后发通知让TabviewController显示
        //        if (self.view.tag == 222222) {
        if ([[UIApplication sharedApplication].keyWindow viewWithTag:2001] ) {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"showTabviewController" object:self];
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:@"LoadingRemove" object:self];
        
        [self.webView stringByEvaluatingJavaScriptFromString:@"document.documentElement.style.webkitUserSelect='none';"];
        [self.webView stringByEvaluatingJavaScriptFromString:@"document.documentElement.style.webkitTouchCallout='none';"];
        self.isWebViewLoading = YES;
        
    }
    if (_activityIndicatorView) {
        [self.activityIndicatorView stopAnimating];
        [self.activityIndicatorView removeFromSuperview];
    }
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    NSLog(@"webview error delegate : %@",error.description);
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    return YES;
}
#pragma mark - objcCallJs
- (void)objcCallJs:(NSDictionary *)dic {
    [_bridge callHandler:@"xzBridge" data:dic responseCallback:^(id responseData) {
        NSLog(@"WebView和JS交互桥建立: %@", responseData);
    }];
}
#pragma mark - JsCallObjcHttpRequest -
- (void)rpcRequestWithJsDic:(NSDictionary *)dataDic
                 jsCallBack:(WVJBResponseCallback)jsCallBack {
    //解析出请求URL
    NSString *path = [dataDic objectForKey:@"requestUrl"];
    NSArray *pathAry = [path componentsSeparatedByString:@"/"];
    NSString *firstPathStr = [pathAry safeObjectAtIndex:1];
    NSString *requestUrl = nil;
    if ([firstPathStr isEqualToString:@"app"] || [firstPathStr isEqualToString:@"appmodule"]) {
        requestUrl = [NSString stringWithFormat:@"http://%@%@/%@/%@",[pathAry safeObjectAtIndex:2],AppMainDomain,[pathAry safeObjectAtIndex:3],[pathAry safeObjectAtIndex:4]];
    }
    else if ([firstPathStr isEqualToString:@"element"]) {
        requestUrl = [NSString stringWithFormat:@"http://element%@/api/%@",AppMainDomain,[pathAry safeObjectAtIndex:2]];
    }
    else {
        requestUrl = [NSString stringWithFormat:@"%@%@",Domain,path];
    }
    //解析出请求参数
    NSDictionary *requestDataDic = [dataDic objectForKey:@"requestData"];
    NSDictionary *paramDic = nil;
    
    //响站端rpc请求参数生成
    NSString *siteID = [[NSUserDefaults standardUserDefaults] objectForKey:@"User_OpenedWebSiteID"] ? [[NSUserDefaults standardUserDefaults] objectForKey:@"User_OpenedWebSiteID"] : @"";
    NSString *userID = [[NSUserDefaults standardUserDefaults] objectForKey:@"User_UserId"] ? [[NSUserDefaults standardUserDefaults] objectForKey:@"User_UserId"] : @"";
    NSString *userToken = [[NSUserDefaults standardUserDefaults] objectForKey:@"User_UserToken"] ? [[NSUserDefaults standardUserDefaults] objectForKey:@"User_UserToken"] : @"";
    NSString *dataJsonString = @"";
    if ([requestDataDic isKindOfClass:[NSDictionary class]]) {
        NSData *data = [NSJSONSerialization dataWithJSONObject:requestDataDic options:NSJSONWritingPrettyPrinted error:nil];
        dataJsonString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    }
    paramDic = @{
                 @"data" : dataJsonString,
                 @"userid" : userID,
                 @"userToken" : userToken,
                 @"siteId" : siteID
                 };
    
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.responseSerializer = [AFJSONResponseSerializer serializer];
    manager.requestSerializer = [AFHTTPRequestSerializer serializer];
    if(ISIPAD) {
        [manager.requestSerializer setValue:@"iospad" forHTTPHeaderField:@"from"];
    } else {
        [manager.requestSerializer setValue:@"ios" forHTTPHeaderField:@"from"];
    }
    manager.requestSerializer.timeoutInterval = 45;
    NSString *token = [[NSUserDefaults standardUserDefaults] objectForKey:@"User_Token_String"];
    [manager.requestSerializer setValue:token forHTTPHeaderField:@"AUTHORIZATION"];
    NSLog(@"*******rpc requesturl : %@",requestUrl);
    NSLog(@"*******rpc paramdic : %@",paramDic);
    
    if (kIsDebug) {
        requestUrl = [requestUrl stringByReplacingOccurrencesOfString:@"xiangzhan" withString:@"tuweile"];
    }
    
    [manager POST:requestUrl parameters:paramDic progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nonnull responseObject) {
        NSLog(@"task : %@",task.currentRequest.URL.absoluteString);
        NSArray *storageCookieAry = [NSHTTPCookieStorage sharedHTTPCookieStorage].cookies;
        NSLog(@" storageCookieAryrpc____: %@",storageCookieAry);
        NSLog(@"rpc_requesturl: %@      rpc_responseobject: %@",requestUrl,responseObject);
        if (jsCallBack) {
            jsCallBack(responseObject);
        }
    } failure:^(NSURLSessionDataTask * _Nonnull task, NSError * _Nonnull error) {
        NSLog(@"crash_webViewDomain : %@",self.webViewDomain);
        if (jsCallBack) {
            jsCallBack(error.description);
            NSLog(@"%@",error.description);
        }
    }];
}

- (void)titleLableTapped:(UIGestureRecognizer *)gesture {
    [self.webView.scrollView scrollRectToVisible:CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height) animated:YES];
}

//具体支付过程子类中实现
- (void)payRequest:(NSDictionary *)payDic {
}

//通知后台打开站点和切换的新站点，后台站点和推送id一一对应
- (void)requestOpenSite:(NSDictionary *)param {
    NSString *siteID = [[NSUserDefaults standardUserDefaults] objectForKey:@"User_OpenedWebSiteID"] ? [[NSUserDefaults standardUserDefaults] objectForKey:@"User_OpenedWebSiteID"] : @"";
    NSString *userID = [[NSUserDefaults standardUserDefaults] objectForKey:@"User_UserId"] ? [[NSUserDefaults standardUserDefaults] objectForKey:@"User_UserId"] : @"";
    NSString *userToken = [[NSUserDefaults standardUserDefaults] objectForKey:@"User_UserToken"] ? [[NSUserDefaults standardUserDefaults] objectForKey:@"User_UserToken"] : @"";
    NSData *data = [NSJSONSerialization dataWithJSONObject:param
                                                   options:NSJSONWritingPrettyPrinted error:nil];
    NSString *dataJsonStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSDictionary *paramDic = @{
                               @"data" : dataJsonStr,
                               @"userid" : userID,
                               @"userToken" : userToken,
                               @"siteId" : siteID
                               };
    NSString *requestUrl = [NSString stringWithFormat:@"%@%@",Domain,@"/message/appLoginWebsite"];
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    manager.requestSerializer = [AFHTTPRequestSerializer serializer];
    if(ISIPAD) {
        [manager.requestSerializer setValue:@"iospad" forHTTPHeaderField:@"from"];
    } else {
        [manager.requestSerializer setValue:@"ios" forHTTPHeaderField:@"from"];
    }
    manager.requestSerializer.timeoutInterval = 45;
    [manager.requestSerializer setValue:[[NSUserDefaults standardUserDefaults] objectForKey:@"User_Token_String"] forHTTPHeaderField:@"AUTHORIZATION"];
    [manager POST:requestUrl parameters:paramDic progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nonnull responseObject) {
        
        NSString *str = [[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding];
        NSLog(@"responseObject:%@",str);
    } failure:^(NSURLSessionDataTask * _Nonnull task, NSError * _Nonnull error) {
        
    }];
}
/** * 判断一个控件是否真正显示在主窗口 */
- (BOOL)isShowingOnKeyWindow {
    // 主窗口
    UIWindow *keyWindow = [UIApplication sharedApplication].keyWindow;
    // 以主窗口左上角为坐标原点, 计算self的矩形框
    CGRect newFrame = [keyWindow convertRect:self.view.frame fromView:self.view.superview];
    CGRect winBounds = keyWindow.bounds;
    // 主窗口的bounds 和 self的矩形框 是否有重叠
    BOOL intersects = CGRectIntersectsRect(newFrame, winBounds);
    return !self.view.isHidden && self.view.alpha > 0.01 && self.view.window == keyWindow && intersects;
}

@end



