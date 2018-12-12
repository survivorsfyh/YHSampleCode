//
//  FYHPushManager.m
//  Integration
//
//  Created by survivors on 2018/11/5.
//  Copyright © 2018年 survivors. All rights reserved.
//

#import "FYHPushManager.h"
#import "FYHBaseTabBarController.h"
// Jump VC
#import "FYHBaseWebVC.h"
#import "YTHIntegrationVC.h"

@implementation FYHPushManager

/**
 获取当前视图

 @return 当前视图
 */
+ (UIViewController *)getCurrentVC
{
    UIViewController *result = nil;
    UIWindow * window = [[UIApplication sharedApplication] keyWindow];
    // app 默认 windowLevel 是 UIWindowLevelNormal,如果不是,找到 UIWindowLevelNormal 的
    if (window.windowLevel != UIWindowLevelNormal)
    {
        NSArray *windows = [[UIApplication sharedApplication] windows];
        for(UIWindow * tmpWin in windows)
        {
            if (tmpWin.windowLevel == UIWindowLevelNormal)
            {
                window = tmpWin;
                break;
            }
        }
    }
    id  nextResponder = nil;
    UIViewController *appRootVC=window.rootViewController;
    // 如果是 present 上来的 appRootVC.presentedViewController 不为nil
    if (appRootVC.presentedViewController) {
        nextResponder = appRootVC.presentedViewController;
    }else{
        
        NSLog(@"getCurrentVC === %@",[window subviews]);
        UIView *frontView = [[window subviews] objectAtIndex:0];
        nextResponder = [frontView nextResponder];
    }
    
    if ([nextResponder isKindOfClass:[UITabBarController class]]){
        UITabBarController * tabbar = (UITabBarController *)nextResponder;
        UINavigationController * nav = (UINavigationController *)tabbar.viewControllers[tabbar.selectedIndex];
//        UINavigationController * nav = tabbar.selectedViewController ; 上下两种写法都行
        result=nav.childViewControllers.lastObject;
        
    }else if ([nextResponder isKindOfClass:[UINavigationController class]]){
        UIViewController * nav = (UIViewController *)nextResponder;
        result = nav.childViewControllers.lastObject;
    }else{
        result = nextResponder;
    }
    return result;
}


/**
 推送跳转当前 VC 展示

 @param userInfo 推送消息数据源
 */
+ (void)pushViewControllerWithDictionary:(NSDictionary *)userInfo {
    FYHBaseTabBarController *tabBar = (FYHBaseTabBarController *)kKeyWindow.rootViewController;
    UIViewController *topmostVC = [self getCurrentVC];
    
    // 防止崩溃 就不做操作了
    if (topmostVC.navigationController == nil) {// [topmostVC isKindOfClass:[UIWindow class]] || topmostVC.navigationController == nil
        return;
    }
    
    // 这个判断很重要 区别程序是否杀死 如果程序被杀死 那tab并不存在,不会继续做操作
    if (![tabBar isKindOfClass:[FYHBaseTabBarController class]]) {
        return;
    }
    
    // 若当前用户未登录或登录失效,不执行相关操作
    if (![UserTableOperation getCurrentUserWithToken]) {
        return;
    }
    
#pragma mark - 推送相关逻辑处理
    NSString *content = [userInfo valueForKey:@"content"];// 推送的内容
    NSString *messageID = [userInfo valueForKey:@"_j_msgid"];// 推送的消息 id, 即 _j_msgid
    NSDictionary *extras = [userInfo valueForKey:@"extras"];// 获取用户自定义参数
    NSString *customizeField1 = [extras valueForKey:@"customizeField1"]; // 服务端传递的 Extras 附加字段，key 是自己定义的
    NSLog(@"****************  FYHPushManager ****************\nMessageID: %@\nContent: %@\nExtras: %@\nCustomizeField1: %@", messageID, content, extras, customizeField1);
    
    /** 收到通知处理相关事项 --- 消息类型(1.系统公告 & 2.活动相关 & 3.公告通知 & 4.资源分享 & 5.系统提醒)*/
    NSString *fType = [NSString stringWithFormat:@"%@", [extras valueForKey:@"fType"]];
    if (kStringIsEmpty(fType)) {
        fType = [NSString stringWithFormat:@"%@", [userInfo valueForKey:@"fType"]];
    }
    /** 活动页 URL*/
    NSString *fFunPageUrl = [NSString stringWithFormat:@"%@", [extras valueForKey:@"fFunPageUrl"]];
    if (kStringIsEmpty(fFunPageUrl)) {
        fFunPageUrl = [NSString stringWithFormat:@"%@", [userInfo valueForKey:@"fFunPageUrl"]];
    }
    NSLog(@"****** Push ******\nfFunPageUrl --- %@", fFunPageUrl);
    
    // 业务处理相关
    if ([fType isEqualToString:@"1"]) {// 系统公告
        // do somethings
    } else if ([fType isEqualToString:@"2"]){// 活动相关
        if (fFunPageUrl != nil) {
            FYHBaseWebVC *webVC = [[FYHBaseWebVC alloc] init];
            webVC.targetURLeeeee = fFunPageUrl;
            webVC.hiddenNavShelf = @"0";
            webVC.hidesBottomBarWhenPushed = YES;
            [topmostVC.navigationController pushViewController:webVC animated:YES];
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

@end
