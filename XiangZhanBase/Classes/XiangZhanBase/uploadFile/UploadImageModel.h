//
//  UploadImageModel.h
//  XiangZhanBase
//
//  Created by yiliu on 16/6/2.
//  Copyright © 2016年 TuWeiA. All rights reserved.
//

#import "XZJsonModel.h"
@interface UploadImageModel : XZJsonModel
@property (strong, nonatomic) NSString *appId;
@property (assign, nonatomic) NSInteger count;
@property (strong, nonatomic) NSString *cropper;
@property (strong, nonatomic) NSString *filters;
@property (strong, nonatomic) NSString *folderId;
@property (strong, nonatomic) NSString *maxFiles;
@property (assign, nonatomic) unsigned long long max_size;
@property (strong, nonatomic) NSString *title;
@property (strong, nonatomic) NSString *type;
@property (strong, nonatomic) NSString *userId;
@property (strong, nonatomic) NSString *watermark;
@end
