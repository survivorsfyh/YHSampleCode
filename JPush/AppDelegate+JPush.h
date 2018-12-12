//
//  AppDelegate+JPush.h
//  Integration
//
//  Created by survivors on 2018/7/20.
//  Copyright © 2018年 survivors. All rights reserved.
//

#import "AppDelegate.h"

@interface AppDelegate (JPush)

/**
 JPush 注册

 @param launchOptions 应用程序
 */
- (void)registerJPush:(NSDictionary *)launchOptions;

@end
