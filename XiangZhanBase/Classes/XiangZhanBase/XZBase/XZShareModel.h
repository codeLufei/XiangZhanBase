//
//  XZShareModel.h
//  XiangZhan
//
//  Created by tuweia on 15/11/17.
//  Copyright © 2015年 tuweia. All rights reserved.
//

//#import <XiangZhanBase/XZJsonModel.h>
#import "XZJsonModel.h"
#import <UIKit/UIKit.h>

@interface XZShareModel : XZJsonModel

@property (nonatomic,strong) NSString *imgUrl;      //图片地址
@property (nonatomic,strong) NSString *title;       //标题
@property (nonatomic,strong) NSString *content;     //内容
@property (nonatomic,strong) NSString *link;        //链接
@property (nonatomic,strong) NSData   *imagedata;   //图片二进制
@property (nonatomic,strong) UIImage  *image;       //图片

@end
