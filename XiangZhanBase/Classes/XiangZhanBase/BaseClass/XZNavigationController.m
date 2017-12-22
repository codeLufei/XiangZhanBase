//
//  TYNavigationController.m
//  TuiYa
//
//  Created by jessy on 15/6/14.
//  Copyright (c) 2015年 tuweia. All rights reserved.
//

#import "XZNavigationController.h"

@implementation XZNavigationController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.navigationBar.backgroundColor = [UIColor whiteColor];
    self.navigationBar.barTintColor = [UIColor whiteColor];
    self.navigationBar.tintColor = [UIColor whiteColor];
    
    self.interactivePopGestureRecognizer.delegate = self;
    self.interactivePopGestureRecognizer.enabled = YES;

    self.delegate = self;
}


- (void)pushViewController:(UIViewController *)viewController animated:(BOOL)animated {
    if ([self respondsToSelector:@selector(interactivePopGestureRecognizer)]) {
        self.interactivePopGestureRecognizer.enabled = NO;
    }
    [super pushViewController:viewController animated:animated];
}

- (void)navigationController:(UINavigationController *)navigationController didShowViewController:(UIViewController *)viewController animated:(BOOL)animated {
    if ([self respondsToSelector:@selector(interactivePopGestureRecognizer)] && self.viewControllers.count > 1) {
        self.interactivePopGestureRecognizer.enabled = YES;
    }
    else {
        self.interactivePopGestureRecognizer.enabled = NO;
    }
}

- (UIViewController *)popViewControllerAnimated:(BOOL)animated {
    return [super popViewControllerAnimated:animated];
}


- (BOOL)shouldAutorotate

{
    
    return [self.topViewController shouldAutorotate];
    
}


- (UIInterfaceOrientationMask)supportedInterfaceOrientations

{
    
    return [self.topViewController supportedInterfaceOrientations];
    
}


- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation

{
    
    return [self.topViewController preferredInterfaceOrientationForPresentation];
    
}
@end
