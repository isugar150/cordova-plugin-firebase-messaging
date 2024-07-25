#import <UIKit/UIKit.h>
#import "AppDelegate.h"

@import UserNotifications;
@import FirebaseMessaging;

//@interface AppDelegate (FirebaseMessagingPlugin) <FIRMessagingDelegate, UNUserNotificationCenterDelegate>
//
//@end


@interface AppDelegate (FirebaseMessagingPlugin)
@property (nonatomic, strong) NSDictionary *pendingNotification;

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler;
- (void)messaging:(FIRMessaging *)messaging didReceiveRegistrationToken:(NSString *)fcmToken;
- (void)applicationDidBecomeActive:(UIApplication *)application;

@end
