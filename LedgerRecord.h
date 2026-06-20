// LedgerRecord.h
// 记账记录数据模型

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, LedgerType) {
    LedgerTypeExpense = 0,  // 支出
    LedgerTypeIncome  = 1,  // 收入
};

@interface LedgerRecord : NSObject <NSCoding>

@property (nonatomic, copy)   NSString   *recordID;    // 唯一ID
@property (nonatomic, assign) LedgerType  type;        // 收入/支出
@property (nonatomic, assign) double      amount;      // 金额
@property (nonatomic, copy)   NSString   *category;   // 分类key
@property (nonatomic, copy)   NSString   *dateString;  // yyyy-MM-dd
@property (nonatomic, copy)   NSString   *note;        // 备注

+ (instancetype)recordWithType:(LedgerType)type
                        amount:(double)amount
                      category:(NSString *)category
                    dateString:(NSString *)dateString
                          note:(NSString *)note;

// 分类辅助
+ (NSArray<NSString *> *)expenseCategoryKeys;
+ (NSArray<NSString *> *)incomeCategoryKeys;
+ (NSString *)iconForCategory:(NSString *)key;
+ (NSString *)nameForCategory:(NSString *)key;

@end
