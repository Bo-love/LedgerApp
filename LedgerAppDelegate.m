// LedgerAppDelegate.m
#import "LedgerAppDelegate.h"
#import "LedgerRootViewController.h"

@implementation LedgerAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    
    LedgerRootViewController *root = [[LedgerRootViewController alloc] init];
    self.window.rootViewController = root;
    
    // 统一导航栏外观
    if (@available(iOS 15.0, *)) {
        UINavigationBarAppearance *app = [[UINavigationBarAppearance alloc] init];
        [app configureWithDefaultBackground];
        [UINavigationBar appearance].standardAppearance   = app;
        [UINavigationBar appearance].scrollEdgeAppearance = app;
    }
    
    [self.window makeKeyAndVisible];
    return YES;
}

@end
