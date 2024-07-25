#import "AppDelegate+FirebaseMessagingPlugin.h"
#import "FirebaseMessagingPlugin.h"
#import <objc/runtime.h>
#import <UIKit/UIKit.h>
#import <UserNotifications/UserNotifications.h>

static char pendingNotificationKey;

@implementation AppDelegate (FirebaseMessagingPlugin)

- (void)setPendingNotification:(NSDictionary *)pendingNotification {
    objc_setAssociatedObject(self, &pendingNotificationKey, pendingNotification, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSDictionary *)pendingNotification {
    return objc_getAssociatedObject(self, &pendingNotificationKey);
}

// Borrowed from http://nshipster.com/method-swizzling/
+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Class class = [self class];

        SEL originalSelector = @selector(application:didFinishLaunchingWithOptions:);
        SEL swizzledSelector = @selector(identity_application:didFinishLaunchingWithOptions:);

        Method originalMethod = class_getInstanceMethod(class, originalSelector);
        Method swizzledMethod = class_getInstanceMethod(class, swizzledSelector);

        BOOL didAddMethod =
        class_addMethod(class,
                        originalSelector,
                        method_getImplementation(swizzledMethod),
                        method_getTypeEncoding(swizzledMethod));

        if (didAddMethod) {
            class_replaceMethod(class,
                                swizzledSelector,
                                method_getImplementation(originalMethod),
                                method_getTypeEncoding(originalMethod));
        } else {
            method_exchangeImplementations(originalMethod, swizzledMethod);
        }
    });
}

- (BOOL)identity_application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // always call original method implementation first
    BOOL handled = [self identity_application:application didFinishLaunchingWithOptions:launchOptions];

//    [UNUserNotificationCenter currentNotificationCenter].delegate = self;
    UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
    // Setting delegate
    center.delegate = self;
    UNAuthorizationOptions options = UNAuthorizationOptionAlert + UNAuthorizationOptionSound;
    [center requestAuthorizationWithOptions:options
     completionHandler:^(BOOL granted, NSError * _Nullable error) {
     if (!granted) {
      NSLog(@"Something went wrong");
     }
    }];
    [center getNotificationSettingsWithCompletionHandler:^(UNNotificationSettings * _Nonnull settings) {
     if (settings.authorizationStatus != UNAuthorizationStatusAuthorized) {
      // Notifications not allowed
     }
    }];
//    if (launchOptions) {
//        NSDictionary *userInfo = launchOptions[UIApplicationLaunchOptionsRemoteNotificationKey];
//        if (userInfo) {
//            [self postNotification:userInfo background:TRUE];
//        }
//    }

    return YES;
}

- (FirebaseMessagingPlugin*) getPluginInstance {
    return [self.viewController getCommandInstance:@"FirebaseMessaging"];
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo
fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {
    FirebaseMessagingPlugin* fcmPlugin = [self getPluginInstance];
        
//    if (application.applicationState == UIApplicationStateBackground) {
    [fcmPlugin sendBackgroundNotification:userInfo];
    self.pendingNotification = userInfo;
//    } else {
//        [fcmPlugin sendNotification:userInfo];
//    }

    completionHandler(UNNotificationPresentationOptionList | UNNotificationPresentationOptionBanner | UNNotificationPresentationOptionSound);
}

- (void)messaging:(FIRMessaging *)messaging didReceiveRegistrationToken:(NSString *)fcmToken {
    FirebaseMessagingPlugin* fcmPlugin = [self getPluginInstance];

    [fcmPlugin sendToken:fcmToken];
}

# pragma mark - UNUserNotificationCenterDelegate
// handle incoming notification messages while app is in the foreground
- (void)userNotificationCenter:(UNUserNotificationCenter *)center
       willPresentNotification:(UNNotification *)notification
         withCompletionHandler:(void (^)(UNNotificationPresentationOptions))completionHandler {
    NSDictionary *userInfo = notification.request.content.userInfo;
    FirebaseMessagingPlugin* fcmPlugin = [self getPluginInstance];

    [fcmPlugin sendNotification:userInfo];
    [fcmPlugin sendBackgroundNotification:userInfo];
    
    completionHandler(UNNotificationPresentationOptionList | UNNotificationPresentationOptionBanner | UNNotificationPresentationOptionSound);
}

// handle notification messages after display notification is tapped by the user
- (void)userNotificationCenter:(UNUserNotificationCenter *)center
didReceiveNotificationResponse:(UNNotificationResponse *)response
         withCompletionHandler:(void (^)(UNNotificationPresentationOptions))completionHandler {
    NSDictionary *userInfo = response.notification.request.content.userInfo;
    
    FirebaseMessagingPlugin* fcmPlugin = [self getPluginInstance];
    [fcmPlugin sendBackgroundNotification:userInfo];

    self.pendingNotification = userInfo;
    [self handlePendingNotification];

    completionHandler(UNNotificationPresentationOptionList | UNNotificationPresentationOptionBanner | UNNotificationPresentationOptionSound);
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    [self handlePendingNotification];
}

- (void)handlePendingNotification {
    NSLog(@"pendingNotification: %@", self.pendingNotification);
    if (self.pendingNotification) {
        NSString *navigateTo = self.pendingNotification[@"navigateTo"];
        NSLog(@"navigateTo: %@", navigateTo);
        if (navigateTo) {
            NSString *jsCommand = [NSString stringWithFormat:@"setTimeout(function() { window.location.href = '#%@'; }, 100);", navigateTo];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                CDVViewController* viewController = (CDVViewController*)self.viewController;
                [viewController.webViewEngine evaluateJavaScript:jsCommand completionHandler:nil];
            });
        }
        self.pendingNotification = nil;
    }
}

@end
