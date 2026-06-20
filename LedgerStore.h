// LedgerStore.h
// 本地数据存储（NSUserDefaults + NSKeyedArchiver）

#import <Foundation/Foundation.h>
#import "LedgerRecord.h"

@interface LedgerStore : NSObject

+ (instancetype)shared;

// CRUD
- (void)addRecord:(LedgerRecord *)record;
- (void)updateRecord:(LedgerRecord *)record;
- (void)deleteRecord:(NSString *)recordID;
- (NSArray<LedgerRecord *> *)allRecords;

// 查询
- (NSArray<LedgerRecord *> *)recordsForDate:(NSString *)dateString;         // yyyy-MM-dd
- (NSArray<LedgerRecord *> *)recordsForMonth:(NSString *)monthString;       // yyyy-MM
- (NSArray<LedgerRecord *> *)recordsForYear:(NSInteger)year;

// 统计
- (double)incomeForRecords:(NSArray<LedgerRecord *> *)records;
- (double)expenseForRecords:(NSArray<LedgerRecord *> *)records;

@end
