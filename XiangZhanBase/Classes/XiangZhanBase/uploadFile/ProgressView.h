//
//  ProgressView.h
//  XiangZhan
//
//  Created by jessy on 16/4/20.
//  Copyright © 2016年 tuweia. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UIColor+addition.h"

@interface ProgressView : UIView

@property (nonatomic, assign) CGFloat progress;

- (void)drawRectWithProgress:(CGFloat)progress;

@end
