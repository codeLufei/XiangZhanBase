//
//  TYJsonModel.h
//  TuiYa
//
//  Created by jessy on 15/6/14.
//  Copyright (c) 2015年 tuweia. All rights reserved.
//

#import <JSONModel/JSONModel.h>

@interface XZJsonModel : JSONModel

/**
 *  通过字典创建Model
 *
 *  @param aDict 字典
 *
 *  @return model
 */
+ (instancetype)modelWithDict:(NSDictionary *)aDict;

@end
