// LedgerRootViewController.m
// TabBar root — 日账、月汇总、年报表、统计分析

#import "LedgerRootViewController.h"
#import "LedgerDayViewController.h"
#import "LedgerMonthViewController.h"
#import "LedgerYearViewController.h"
#import "LedgerStatsViewController.h"

@implementation LedgerRootViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    LedgerDayViewController   *dayVC   = [[LedgerDayViewController alloc] init];
    LedgerMonthViewController *monthVC = [[LedgerMonthViewController alloc] init];
    LedgerYearViewController  *yearVC  = [[LedgerYearViewController alloc] init];
    LedgerStatsViewController *statsVC = [[LedgerStatsViewController alloc] init];
    
    UINavigationController *dayNav   = [[UINavigationController alloc] initWithRootViewController:dayVC];
    UINavigationController *monthNav = [[UINavigationController alloc] initWithRootViewController:monthVC];
    UINavigationController *yearNav  = [[UINavigationController alloc] initWithRootViewController:yearVC];
    UINavigationController *statsNav = [[UINavigationController alloc] initWithRootViewController:statsVC];
    
    // TabBar Items
    dayNav.tabBarItem   = [[UITabBarItem alloc] initWithTitle:@"日记账"  image:[UIImage systemImageNamed:@"list.bullet"]        tag:0];
    monthNav.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"月汇总"  image:[UIImage systemImageNamed:@"calendar"]           tag:1];
    yearNav.tabBarItem  = [[UITabBarItem alloc] initWithTitle:@"年报表"  image:[UIImage systemImageNamed:@"chart.bar"]          tag:2];
    statsNav.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"统计"    image:[UIImage systemImageNamed:@"chart.pie"]          tag:3];
    
    self.viewControllers = @[dayNav, monthNav, yearNav, statsNav];
    
    // TabBar 颜色
    if (@available(iOS 15.0, *)) {
        UITabBarAppearance *app = [[UITabBarAppearance alloc] init];
        [app configureWithDefaultBackground];
        self.tabBar.standardAppearance   = app;
        self.tabBar.scrollEdgeAppearance = app;
    }
    self.tabBar.tintColor = [UIColor colorWithRed:.06 green:.43 blue:.34 alpha:1];
}

@end
