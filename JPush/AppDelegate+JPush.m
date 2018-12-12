//
//  AppDelegate+JPush.m
//  Integration
//
//  Created by survivors on 2018/7/20.
//  Copyright © 2018年 survivors. All rights reserved.
//

#import "AppDelegate+JPush.h"
#import <JPUSHService.h>
// iOS10注册APNs所需头文件
#ifdef NSFoundationVersionNumber_iOS_9_x_Max
#import <UserNotifications/UserNotifications.h>
#endif
// 如果需要使用idfa功能所需要引入的头文件（可选）
#import <AdSupport/AdSupport.h>

#ifdef DEBUG
#define Push_Key        @"对应的 appkey 参数"
#define Push_Channel    @"App Store"
#else
#define Push_Key        @"对应的 appkey 参数"
#define Push_Channel    @"App Store"
#endif

@interface AppDelegate () <JPUSHRegisterDelegate>

@end

@implementation AppDelegate (JPush) 

/**
 注册推送 - JPush

 @param launchOptions 启动项
 */
- (void)registerJPush:(NSDictionary *)launchOptions {
    //Required
    //notice: 3.0.0及以后版本注册可以这样写，也可以继续用之前的注册方式
    JPUSHRegisterEntity * entity = [[JPUSHRegisterEntity alloc] init];
    entity.types = JPAuthorizationOptionAlert|JPAuthorizationOptionBadge|JPAuthorizationOptionSound;
    if ([[UIDevice currentDevice].systemVersion floatValue] >= 8.0) {
        // 可以添加自定义categories
        // NSSet<UNNotificationCategory *> *categories for iOS10 or later
        // NSSet<UIUserNotificationCategory *> *categories for iOS8 and iOS9
    }
    [JPUSHService registerForRemoteNotificationConfig:entity delegate:self];
    
    // Optional
    // 获取IDFA
    // 如需使用IDFA功能请添加此代码并在初始化方法的advertisingIdentifier参数中填写对应值
    NSString *advertisingId = [[[ASIdentifierManager sharedManager] advertisingIdentifier] UUIDString];
    
    BOOL isProduction;
#ifdef DEBUG
    isProduction = 0;
#else
    isProduction = 1;
#endif
    
    // Required
    // init Push
    // notice: 2.1.5版本的SDK新增的注册方法，改成可上报IDFA，如果没有使用IDFA直接传nil
    // 如需继续使用pushConfig.plist文件声明appKey等配置内容，请依旧使用[JPUSHService setupWithOption:launchOptions]方式初始化。
    [JPUSHService setupWithOption:launchOptions
                           appKey:Push_Key
                          channel:Push_Channel
                 apsForProduction:isProduction
            advertisingIdentifier:nil];
    
    // 自定义消息相关
    NSNotificationCenter *defaultCenter = [NSNotificationCenter defaultCenter];
    [defaultCenter addObserver:self
                      selector:@selector(networkDidReceiveMessage:)
                          name:kJPFNetworkDidReceiveMessageNotification
                        object:nil];
    
    [JPUSHService setDebugMode];// 注:debug 开启,打包时关闭
    [JPUSHService registrationIDCompletionHandler:^(int resCode, NSString *registrationID) {
        NSLog(@"JPush --- resCode : %d,registrationID: %@",resCode,registrationID);
    }];
}



/**
 Required - 注册 DeviceToken

 注:
 JPush 3.0.9 之前的版本，必须调用此接口，注册 token 之后才可以登录极光，使用通知和自定义消息功能。
 从 JPush 3.0.9 版本开始，不调用此方法也可以登录极光。但是不能使用APNs通知功能，只可以使用JPush自定义消息。
 
 @param application 应用
 @param deviceToken 标识
 */
- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    [JPUSHService registerDeviceToken:deviceToken];
}



- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
    // Required,For systems with less than or equal to iOS6

    [JPUSHService handleRemoteNotification:userInfo];
    NSLog(@"JPush - Receive notice\n%@", userInfo);
    
    [self resetApplicationIconBadgeNumberWith:application];
}

/**
 重置 App 角标

 @param application 应用程序
 */
- (void)resetApplicationIconBadgeNumberWith:(UIApplication *)application {
    // iOS badge 清0
    application.applicationIconBadgeNumber = 0;
    [JPUSHService setBadge:0];
}



- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {
    // Required, iOS 7 Support
    [JPUSHService handleRemoteNotification:userInfo];
    
    NSLog(@"JPush - Receive notice\n%@", userInfo);
    
    // 取得 APNs 标准信息内容
    NSDictionary *aps = [userInfo valueForKey:@"aps"];// 消息集合
    NSString *content = [aps valueForKey:@"alert"]; //推送显示的内容
    NSInteger badge = [[aps valueForKey:@"badge"] integerValue]; //badge数量
    NSString *sound = [aps valueForKey:@"sound"]; //播放的声音
    // 取得Extras字段内容
    NSString *customizeField1 = [userInfo valueForKey:@"customizeExtras"]; //服务端中Extras字段，key是自己定义的
    NSLog(@"JPush\ncontent =[%@], badge=[%ld], sound=[%@], customize field  =[%@]",content,(long)badge,sound,customizeField1);
    
    // block 回调
    completionHandler(UIBackgroundFetchResultNewData);
}



#pragma mark - 自定义消息推送内容相关
/**
 自定义消息推送内容相关

 @param notification 消息推送内容
 */
- (void)networkDidReceiveMessage:(NSNotification *)notification {
    NSDictionary * userInfo = [notification userInfo];
    
    [FYHPushManager pushViewControllerWithDictionary:userInfo];
}

/**
 推送逻辑处理

 @param userInfo 消息推送内容
 */
- (void)pushBusinessLogicProcessingWith:(NSDictionary *)userInfo {
    NSString *content = [userInfo valueForKey:@"content"];// 推送的内容
    NSString *messageID = [userInfo valueForKey:@"_j_msgid"];// 推送的消息 id, 即 _j_msgid
    NSDictionary *extras = [userInfo valueForKey:@"extras"];// 获取用户自定义参数
    NSString *customizeField1 = [extras valueForKey:@"customizeField1"]; // 服务端传递的 Extras 附加字段，key 是自己定义的
    NSLog(@"****************  JPush 自定义消息推送 ****************\nMessageID: %@\nContent: %@\nExtras: %@\nCustomizeField1: %@", messageID, content, extras, customizeField1);
    
    /** 收到通知处理相关事项 --- 消息类型(1.系统公告 & 2.教学活动(住培) & 3.公告通知 & 4.资源分享 & 5.系统提醒)*/
    NSString *fType = [NSString stringWithFormat:@"%@", [extras valueForKey:@"fType"]];
    /** 活动页 URL*/
    NSString *fFunPageUrl = [NSString stringWithFormat:@"%@", [extras valueForKey:@"fFunPageUrl"]];
    
    // 业务处理相关
    if ([fType isEqualToString:@"1"]) {// 系统公告
        // do somethings
    } else if ([fType isEqualToString:@"2"]){// 活动相关
        if (fFunPageUrl != nil) {
            FYHBaseTabBarController *tabBar = [[FYHBaseTabBarController alloc] init];
            tabBar.selectedIndex = 3;// 默认加载页面
            kAppDelegate.window.rootViewController = tabBar;
            
            [kNotificationCenter postNotificationName:@"JPushBusiness"
                                               object:nil
                                             userInfo:userInfo];
        }
    }
    else if ([fType isEqualToString:@"3"]){// 公告通知
        // do somethings
    }
    else if ([fType isEqualToString:@"4"]){// 资源分享
        // do somethings
    }
    else if ([fType isEqualToString:@"5"]){// 系统提醒
        // do somethings
    }
}

/**
 注册 APNs 失败
 
 @param application 应用
 @param error       异常
 */
- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(nonnull NSError *)error {
    //Optional
    NSLog(@"JPush --- did Fail To Register For Remote Notifications With Error: %@\nLocalized Description: %@", error, error.localizedDescription);
}



#pragma mark- JPUSHRegisterDelegate
// iOS 10 Support
- (void)jpushNotificationCenter:(UNUserNotificationCenter *)center willPresentNotification:(UNNotification *)notification withCompletionHandler:(void (^)(NSInteger))completionHandler  API_AVAILABLE(ios(10.0)){
    // Required
    NSDictionary * userInfo = notification.request.content.userInfo;
    
//    [FYHPushManager pushViewControllerWithDictionary:userInfo];
    
    if (@available(iOS 10.0, *)) {
        if([notification.request.trigger isKindOfClass:[UNPushNotificationTrigger class]]) {
            [JPUSHService handleRemoteNotification:userInfo];
        }
    } else {
        // Fallback on earlier versions
    }
    
    if (@available(iOS 10.0, *)) {
        completionHandler(UNNotificationPresentationOptionAlert);// 需要执行这个方法，选择是否提醒用户，有Badge、Sound、Alert三种类型可以选择设置
    } else {
        // Fallback on earlier versions
    }
}

// iOS 10 Support
- (void)jpushNotificationCenter:(UNUserNotificationCenter *)center didReceiveNotificationResponse:(UNNotificationResponse *)response withCompletionHandler:(void (^)(void))completionHandler  API_AVAILABLE(ios(10.0)){
    // Required
    NSDictionary * userInfo = response.notification.request.content.userInfo;
    
    [FYHPushManager pushViewControllerWithDictionary:userInfo];
    
    if (@available(iOS 10.0, *)) {
        if([response.notification.request.trigger isKindOfClass:[UNPushNotificationTrigger class]]) {
            [JPUSHService handleRemoteNotification:userInfo];
        }
    } else {
        // Fallback on earlier versions
    }
    completionHandler();  // 系统要求执行这个方法
}





@end
