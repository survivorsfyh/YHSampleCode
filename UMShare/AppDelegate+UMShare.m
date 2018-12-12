//
//  AppDelegate+UMShare.m
//  Integration
//
//  Created by survivors on 2018/9/4.
//  Copyright © 2018年 survivors. All rights reserved.
//

#import "AppDelegate+UMShare.h"
#import <UMShare/UMShare.h>
#import <UMCommon/UMCommon.h>
#import <UMCommonLog/UMCommonLogHeaders.h>
#import <UShareUI/UShareUI.h>

@implementation AppDelegate (UMShare)

/**
 UMShare 注册
 
 @param launchOptions 应用程序
 */
- (void)registerUMShare:(NSDictionary *)launchOptions {
    // UMConfigure 通用设置，请参考SDKs集成做统一初始化。
    // 以下仅列出U-Share初始化部分
    [self configUSharePlatforms];
    [self confitUShareSettings];
    
    BOOL isSetLog;
#ifdef DEBUG
    isSetLog = 0;
#else
    isSetLog = 1;
#endif
    // Log
    [UMCommonLogManager setUpUMCommonLogManager];
    [UMConfigure setLogEnabled:isSetLog];
    [UMConfigure initWithAppkey:UMSHARE_APPKEY channel:@"App Store"];
}

/**
 共享平台配置
 */
- (void)configUSharePlatforms {
    /*
     设置微信的 appKey 和 appSecret
     
     AppID:
     AppSecret:
     */
    [[UMSocialManager defaultManager] setPlaform:UMSocialPlatformType_WechatSession
                                          appKey:@"此处填写对应申请的 AppKey"
                                       appSecret:@"此处填写对应申请的 AppSecret"
                                     redirectURL:@"此处填写对应的链接(例如官网)"];
    
    /*
     设置分享到 QQ 互联的 appID
     U-Share SDK为了兼容大部分平台命名，统一用appKey和appSecret进行参数设置，而QQ平台仅需将appID作为U-Share的appKey参数传进即可。
     
     iPhone:
     iPad:
     */
    [[UMSocialManager defaultManager] setPlaform:UMSocialPlatformType_QQ
                                          appKey:@"设置QQ平台的appID"
                                       appSecret:@"QQ平台为appKey"
                                     redirectURL:@"此处填写对应的链接(例如官网)"];
    
    /*
     * 移除相应平台的分享，如微信收藏
     */
//    [[UMSocialManager defaultManager] removePlatformProviderWithPlatformTypes:@[@(UMSocialPlatformType_WechatFavorite)]];
}

/**
 共享平台设置
 */
- (void)confitUShareSettings {
    [UMSocialGlobal shareInstance].isClearCacheWhenGetUserInfo = YES;
    /*
     * 打开图片水印
     */
//    [UMSocialGlobal shareInstance].isUsingWaterMark = YES;
    
    /*
     * 关闭强制验证https，可允许http图片分享，但需要在info.plist设置安全域名
     <key>NSAppTransportSecurity</key>
     <dict>
     <key>NSAllowsArbitraryLoads</key>
     <true/>
     </dict>
     */
//    [UMSocialGlobal shareInstance].isUsingHttpsWhenShareContent = NO;
}



/**
 调用友盟相关方法

 @param controller 当前视图控件
 */
- (void)getUMShareRelevantMethodsWithCurrentViewController:(UIViewController *)controller {
    // 设置预定义平台
    NSArray *sharePlatforms = @[@(UMSocialPlatformType_WechatSession),
                                @(UMSocialPlatformType_WechatTimeLine),
                                @(UMSocialPlatformType_QQ)];
    [UMSocialUIManager setPreDefinePlatforms:sharePlatforms];
    
    kWeakSelf(self);
    // 显示分享面板
    [UMSocialUIManager showShareMenuViewInWindowWithPlatformSelectionBlock:^(UMSocialPlatformType platformType, NSDictionary *userInfo) {
        [weakself shareWebPageToPlatformType:platformType AndCurrentViewController:controller AndShareInfoData:[NSMutableDictionary dictionary]];
        
//        [weakself checkUserInfoForPlatform:platformType AndCurrentViewController:controller];
    }];
}



/**
 调用友盟相关方法(带参)

 @param controller  当前视图控件
 @param dic         参数
 */
- (void)getUMShareRelevantMethodsWithCurrentViewController:(UIViewController *)controller AndParameter:(NSMutableDictionary *)dic {
    // 设置预定义平台
    NSArray *sharePlatforms = @[@(UMSocialPlatformType_WechatSession),
                                @(UMSocialPlatformType_WechatTimeLine),
                                @(UMSocialPlatformType_QQ)];
    [UMSocialUIManager setPreDefinePlatforms:sharePlatforms];
    
    kWeakSelf(self);
    // 显示分享面板
    [UMSocialUIManager showShareMenuViewInWindowWithPlatformSelectionBlock:^(UMSocialPlatformType platformType, NSDictionary *userInfo) {
        [weakself shareWebPageToPlatformType:platformType AndCurrentViewController:controller AndShareInfoData:dic];
        
        //        [weakself checkUserInfoForPlatform:platformType AndCurrentViewController:controller];
    }];
}


/**
 校验用户信息平台

 @param platformType 平台类型
 */
- (void)checkUserInfoForPlatform:(UMSocialPlatformType)platformType AndCurrentViewController:(UIViewController *)controller {
    kWeakSelf(self);
    [[UMSocialManager defaultManager] getUserInfoWithPlatform:platformType currentViewController:nil completion:^(id result, NSError *error) {
        // 当前设备 App 安装检测    [kApplication openURL:[NSURL URLWithString:@"weixin://"]] && [kApplication openURL:[NSURL URLWithString:@"mqq://"]]
        if ([kApplication openURL:[NSURL URLWithString:@"mqq://"]] && [kApplication openURL:[NSURL URLWithString:@"weixin://"]]) {// WeChat    @"weixin://"
            [weakself shareWebPageToPlatformType:platformType AndCurrentViewController:controller AndShareInfoData:[NSMutableDictionary dictionary]];
        }
        else {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"提示"
                                                            message:@"当前设备未安装该程序"
                                                           delegate:nil
                                                  cancelButtonTitle:@"确定"
                                                  otherButtonTitles:nil, nil];
            [alert show];
            return;
        }
    }];
    
}



/**
 分享内容设置(网页)

 @param platformType 平台类型(网页)
 @param controller 当前控件视图
 @param dataSource 分享数据
 */
- (void)shareWebPageToPlatformType:(UMSocialPlatformType)platformType AndCurrentViewController:(UIViewController *)controller AndShareInfoData:(NSMutableDictionary *)dataSource {
    /** 分享类型(base 则分享默认内容)*/
    NSString *shareType = [NSString stringWithFormat:@"%@", [dataSource objectForKey:@"shareType"]];
    
    NSDictionary *infoPlist = [[NSBundle mainBundle] infoDictionary];
    NSString *icon = [[infoPlist valueForKeyPath:@"CFBundleIcons.CFBundlePrimaryIcon.CFBundleIconFiles"] lastObject];// 默认设置为 App 图标
    NSString *strTitle = @"自定义初始标题";
    NSString *strDescr = @"自定义初始说明";
    NSString *strWebpageUrl = @"自定义初始跳转链接";
    
    if ([shareType isEqualToString:@"custom"]) {// 分享类型:自定义
        strTitle = [NSString stringWithFormat:@"%@", [dataSource objectForKey:@"title"]];
        strDescr = [NSString stringWithFormat:@"%@", [dataSource objectForKey:@"descr"]];
        strWebpageUrl = [NSString stringWithFormat:@"%@", [dataSource objectForKey:@"webpageUrl"]];
        icon = [NSString stringWithFormat:@"%@", [dataSource objectForKey:@"imgUrl"]];// 注:该字段必须为 https,详见 confitUShareSettings 方法
        if (kStringIsEmpty(icon)) {
            icon = [[infoPlist valueForKeyPath:@"CFBundleIcons.CFBundlePrimaryIcon.CFBundleIconFiles"] lastObject];
        }
    }
    
    // 创建分享消息对象
    UMSocialMessageObject *messageObj = [UMSocialMessageObject messageObject];
    // 创建网页内容对象
    UIImage *thumImg = [UIImage imageNamed:icon];
    UMShareWebpageObject *shareObj = [UMShareWebpageObject shareObjectWithTitle:strTitle
                                                                          descr:strDescr
                                                                      thumImage:thumImg];
    // 设置网页地址
    shareObj.webpageUrl = strWebpageUrl;
    // 分享消息对象设置分享内容对象
    messageObj.shareObject = shareObj;

    // 调用分享接口
    kWeakSelf(self);
    [[UMSocialManager defaultManager] shareToPlatform:platformType messageObject:messageObj currentViewController:controller completion:^(id result, NSError *error) {
        if (error) {
            NSLog(@"************Share fail with error *********\nError:%@", error);
        }
        else {
            NSLog(@"************UMShare************\nResponse data is:%@", result);
        }

        // Callback
        [weakself callbackAlterStateWithError:error];
    }];
}



/**
 回调分享状态

 @param error 异常
 */
- (void)callbackAlterStateWithError:(NSError *)error {
    NSString *callback = nil;
    if (error) {
        NSString *strError = [self callbackErrorWithErrorCode:error.code];
        if (kStringIsEmpty(strError)) {
            callback = @"分享失败";
        }
        else {
            callback = strError;
        }
        
    }
    else {
        callback = @"分享成功";
    }
    
    // Show
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"欢迎使用【App 名称】"
                                                    message:callback
                                                   delegate:nil
                                          cancelButtonTitle:@"确定"
                                          otherButtonTitles: nil, nil];
    [alert show];
}

/**
 回调异常提示
 http://dev.umeng.com/wsq/android/errorcode
 
 @param code    异常代码
 @return        异常提示
 */
- (NSString *)callbackErrorWithErrorCode:(NSInteger)code {
    NSString *result = nil;
    if (code == 10002) {
        result = @"用户不存在";
    }
    else if (code == 10003) {
        result = @"用户未登录";
    }
    else if (code == 10004) {
        result = @"用户没有执行操作的权限";
    }
    else if (code == 10005) {
        result = @"用户的id无效";
    }
    else if (code == 10006) {
        result = @"用户已经被创建";
    }
    else if (code == 10007) {
        result = @"已经关注过该用户";
    }
    else if (code == 10008) {
        result = @"注册时用户信息不完整";
    }
    else if (code == 10009) {
        result = @"用户不能关注自己";
    }
    else if (code == 10010) {
        result = @"用户名长度超出范围，用户名为2~20个字符";
    }
    else if (code == 10011) {
        result = @"用户不可用";
    }
    else if (code == 10012) {
        result = @"用户名存在敏感词";
    }
    else if (code == 10013) {
        result = @"用户已经存在";
    }
    else if (code == 10014) {
        result = @"用户自定义字段从长度超出范围";
    }
    else if (code == 10015) {
        result = @"该操作一次只能被一个用户操作";
    }
    else if (code == 10016) {
        result = @"用户名存在非法字符";
    }
    else if (code == 10017) {
        result = @"用户设备在黑名单中";
    }
    else if (code == 10018) {
        result = @"该用户收藏 feed 数量最多50条";
    }
    else if (code == 10019) {
        result = @"该 feed 已经被收藏";
    }
    else if (code == 10020) {
        result = @"该 feed 还未被收藏";
    }
    else {
        result = @"";
    }
    
    return result;
}

/*
 case UMSocialPlatformErrorType_Unknow:
 result = @"未知错误";
 break;
 case UMSocialPlatformErrorType_NotSupport:
 result = @"不支持（url scheme 没配置，或者没有配置-ObjC， 或则SDK版本不支持或则客户端版本不支持";
 break;
 case UMSocialPlatformErrorType_AuthorizeFailed:
 result = @"授权失败";
 break;
 case UMSocialPlatformErrorType_ShareFailed:
 result = @"分享失败";
 break;
 case UMSocialPlatformErrorType_RequestForUserProfileFailed:
 result = @"请求用户信息失败";
 break;
 case UMSocialPlatformErrorType_ShareDataNil:
 result = @"分享内容为空";
 break;
 case UMSocialPlatformErrorType_ShareDataTypeIllegal:
 result = @"分享内容不支持";
 break;
 case UMSocialPlatformErrorType_CheckUrlSchemaFail:
 result = @"schemaurl fail";
 break;
 case UMSocialPlatformErrorType_NotInstall:
 result = @"应用未安装";
 break;
 case UMSocialPlatformErrorType_Cancel:
 result = @"您已取消分享";
 break;
 case UMSocialPlatformErrorType_NotNetWork:
 result = @"网络异常";
 break;
 case UMSocialPlatformErrorType_SourceError:
 result = @"第三方错误";
 break;
 case UMSocialPlatformErrorType_ProtocolNotOverride:
 result = @"对应的    UMSocialPlatformProvider的方法没有实现";
 break;
 default:

 */



#pragma mark - Callback
// 兼容所有 iOS 设备
- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    //注：该方法为建议使用的系统openURL回调，且 新浪 平台仅支持以上回调。还有以下两种回调方式，如果开发者选取以下回调，也请补充相应的函数调用。
    //6.3的新的API调用，是为了兼容国外平台(例如:新版facebookSDK,VK等)的调用[如果用6.2的api调用会没有回调],对国内平台没有影响
    BOOL result = [[UMSocialManager defaultManager] handleOpenURL:url
                                                sourceApplication:sourceApplication
                                                       annotation:annotation];
    if (!result) {
        // 其他如支付等SDK的回调
    }
    
    return result;
}

//仅支持iOS9以上系统，iOS8及以下系统不会回调
- (BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<UIApplicationOpenURLOptionsKey,id> *)options {
    //6.3的新的API调用，是为了兼容国外平台(例如:新版facebookSDK,VK等)的调用[如果用6.2的api调用会没有回调],对国内平台没有影响
    BOOL result = [[UMSocialManager defaultManager]  handleOpenURL:url
                                                           options:options];
    if (!result) {
        // 其他如支付等SDK的回调
    }
    
    return result;
}

- (BOOL)application:(UIApplication *)app handleOpenURL:(nonnull NSURL *)url {
    BOOL result = [[UMSocialManager defaultManager] handleOpenURL:url];
    if (!result) {
        // 其他如支付等SDK的回调
    }
    
    return result;
}



@end
