//
//  FYHPushManager.h
//  Integration
//
//  Created by survivors on 2018/11/5.
//  Copyright © 2018年 survivors. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface FYHPushManager : NSObject

//获取当前视图
+ (UIViewController *)getCurrentVC;

+ (void)pushViewControllerWithDictionary:(NSDictionary *)userInfo;

@end

NS_ASSUME_NONNULL_END
