// LedgerStore.m

#import "LedgerStore.h"

static NSString * const kStoreKey = @"LedgerRecords_v1";

@interface LedgerStore ()
@property (nonatomic, strong) NSMutableArray<LedgerRecord *> *records;
@end

@implementation LedgerStore

+ (instancetype)shared {
    static LedgerStore *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{ instance = [[LedgerStore alloc] init]; });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) { [self loadFromDisk]; }
    return self;
}

#pragma mark - Persistence

- (void)loadFromDisk {
    NSData *data = [[NSUserDefaults standardUserDefaults] dataForKey:kStoreKey];
    if (data) {
        NSError *err = nil;
        NSSet *classes = [NSSet setWithObjects:[NSArray class], [LedgerRecord class], nil];
        NSArray *arr = [NSKeyedUnarchiver unarchivedObjectOfClasses:classes
                                                           fromData:data
                                                              error:&err];
        _records = arr ? [arr mutableCopy] : [NSMutableArray array];
    } else {
        _records = [NSMutableArray array];
        [self seedDemoData];
    }
}

- (void)saveToDisk {
    NSError *err = nil;
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:_records
                                        requiringSecureCoding:NO
                                                        error:&err];
    if (data) {
        [[NSUserDefaults standardUserDefaults] setObject:data forKey:kStoreKey];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}

#pragma mark - Demo Data

- (void)seedDemoData {
    NSDateFormatter *fmt = [[NSDateFormatter alloc] init];
    fmt.dateFormat = @"yyyy-MM-dd";
    NSDate *today = [NSDate date];
    
    NSCalendar *cal = [NSCalendar currentCalendar];
    NSDate *(^offset)(NSInteger) = ^(NSInteger days) {
        return [cal dateByAddingUnit:NSCalendarUnitDay value:days toDate:today options:0];
    };
    
    NSArray *seeds = @[
        @{@"type":@(LedgerTypeIncome),  @"cat":@"salary",    @"amount":@8500,  @"note":@"本月工资",    @"offset":@0},
        @{@"type":@(LedgerTypeExpense), @"cat":@"food",      @"amount":@38.5,  @"note":@"午餐外卖",    @"offset":@(-1)},
        @{@"type":@(LedgerTypeExpense), @"cat":@"food",      @"amount":@12,    @"note":@"早餐",        @"offset":@(-1)},
        @{@"type":@(LedgerTypeExpense), @"cat":@"transport", @"amount":@25,    @"note":@"地铁月票",    @"offset":@(-2)},
        @{@"type":@(LedgerTypeExpense), @"cat":@"shop",      @"amount":@299,   @"note":@"T恤",         @"offset":@(-3)},
        @{@"type":@(LedgerTypeIncome),  @"cat":@"freelance", @"amount":@1200,  @"note":@"设计稿报酬",  @"offset":@(-5)},
        @{@"type":@(LedgerTypeExpense), @"cat":@"food",      @"amount":@85,    @"note":@"朋友聚餐",    @"offset":@(-5)},
        @{@"type":@(LedgerTypeExpense), @"cat":@"medical",   @"amount":@56,    @"note":@"感冒药",      @"offset":@(-7)},
        @{@"type":@(LedgerTypeExpense), @"cat":@"entertain", @"amount":@30,    @"note":@"视频会员",    @"offset":@(-10)},
        @{@"type":@(LedgerTypeExpense), @"cat":@"edu",       @"amount":@199,   @"note":@"在线课程",    @"offset":@(-12)},
        @{@"type":@(LedgerTypeIncome),  @"cat":@"bonus",     @"amount":@2000,  @"note":@"季度奖金",    @"offset":@(-15)},
        @{@"type":@(LedgerTypeExpense), @"cat":@"house",     @"amount":@2800,  @"note":@"房租",        @"offset":@(-20)},
    ];
    
    for (NSDictionary *s in seeds) {
        NSDate *d = offset([s[@"offset"] integerValue]);
        LedgerRecord *r = [LedgerRecord recordWithType:[s[@"type"] integerValue]
                                                amount:[s[@"amount"] doubleValue]
                                              category:s[@"cat"]
                                            dateString:[fmt stringFromDate:d]
                                                  note:s[@"note"]];
        [_records addObject:r];
    }
    [self saveToDisk];
}

#pragma mark - CRUD

- (void)addRecord:(LedgerRecord *)record {
    [_records addObject:record];
    [self saveToDisk];
}

- (void)updateRecord:(LedgerRecord *)record {
    for (NSUInteger i = 0; i < _records.count; i++) {
        if ([_records[i].recordID isEqualToString:record.recordID]) {
            _records[i] = record;
            break;
        }
    }
    [self saveToDisk];
}

- (void)deleteRecord:(NSString *)recordID {
    [_records filterUsingPredicate:[NSPredicate predicateWithFormat:@"recordID != %@", recordID]];
    [self saveToDisk];
}

- (NSArray<LedgerRecord *> *)allRecords {
    return [_records copy];
}

#pragma mark - Query

- (NSArray<LedgerRecord *> *)recordsForDate:(NSString *)dateString {
    return [_records filteredArrayUsingPredicate:
            [NSPredicate predicateWithFormat:@"dateString == %@", dateString]];
}

- (NSArray<LedgerRecord *> *)recordsForMonth:(NSString *)monthString {
    return [_records filteredArrayUsingPredicate:
            [NSPredicate predicateWithFormat:@"dateString BEGINSWITH %@", monthString]];
}

- (NSArray<LedgerRecord *> *)recordsForYear:(NSInteger)year {
    NSString *prefix = [NSString stringWithFormat:@"%ld", (long)year];
    return [_records filteredArrayUsingPredicate:
            [NSPredicate predicateWithFormat:@"dateString BEGINSWITH %@", prefix]];
}

#pragma mark - Stats

- (double)incomeForRecords:(NSArray<LedgerRecord *> *)records {
    double total = 0;
    for (LedgerRecord *r in records) {
        if (r.type == LedgerTypeIncome) total += r.amount;
    }
    return total;
}

- (double)expenseForRecords:(NSArray<LedgerRecord *> *)records {
    double total = 0;
    for (LedgerRecord *r in records) {
        if (r.type == LedgerTypeExpense) total += r.amount;
    }
    return total;
}

@end
