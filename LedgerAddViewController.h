// LedgerAddViewController.h
// 添加 / 编辑记录弹窗控制器

#import <UIKit/UIKit.h>
#import "LedgerRecord.h"

@class LedgerAddViewController;

@protocol LedgerAddViewControllerDelegate <NSObject>
- (void)ledgerAddVC:(LedgerAddViewController *)vc didSaveRecord:(LedgerRecord *)record isNew:(BOOL)isNew;
@end

@interface LedgerAddViewController : UIViewController

@property (nonatomic, weak) id<LedgerAddViewControllerDelegate> delegate;

/// 传入 nil = 新建；传入已有记录 = 编辑
- (instancetype)initWithRecord:(LedgerRecord *)record defaultDate:(NSString *)dateString;

@end
