//
//  TYJsonModel.m
//  TuiYa
//
//  Created by jessy on 15/6/14.
//  Copyright (c) 2015年 tuweia. All rights reserved.
//

#import "XZJsonModel.h"

@implementation XZJsonModel

- (instancetype)init
{
    if (self = [super init]) {
        static dispatch_once_t once;
        dispatch_once(&once, ^{
            [JSONModel setGlobalKeyMapper:[[JSONKeyMapper alloc] initWithDictionary:@{@"id": @"tyId"}]];
//            [JSONModel setGlobalKeyMapper:[[JSONKeyMapper alloc] initWithDictionary:@{@"id": @"typeId"}]];
            [JSONModel setGlobalKeyMapper:[[JSONKeyMapper alloc] initWithDictionary:@{@"private": @"tyPrivate"}]];
        });
    }
    return self;
}

/**
 *  重写父类方法，默认所有属性可选
 *
 *  @param propertyName 属性名称
 *
 *  @return bool
 */
+(BOOL)propertyIsOptional:(NSString*)propertyName
{
    return YES;
}

+ (instancetype)modelWithDict:(NSDictionary *)aDict
{
    if (![aDict isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    
    return [[self alloc] initWithDictionary:aDict error:nil];
}
@end
