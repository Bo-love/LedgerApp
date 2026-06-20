// LedgerRecord.m

#import "LedgerRecord.h"

@implementation LedgerRecord

#pragma mark - Init

+ (instancetype)recordWithType:(LedgerType)type
                        amount:(double)amount
                      category:(NSString *)category
                    dateString:(NSString *)dateString
                          note:(NSString *)note {
    LedgerRecord *r = [[LedgerRecord alloc] init];
    r.recordID   = [[NSUUID UUID] UUIDString];
    r.type       = type;
    r.amount     = amount;
    r.category   = category ?: @"other_e";
    r.dateString = dateString ?: @"";
    r.note       = note ?: @"";
    return r;
}

#pragma mark - NSCoding

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super init];
    if (self) {
        _recordID   = [coder decodeObjectForKey:@"recordID"];
        _type       = [coder decodeIntegerForKey:@"type"];
        _amount     = [coder decodeDoubleForKey:@"amount"];
        _category   = [coder decodeObjectForKey:@"category"];
        _dateString = [coder decodeObjectForKey:@"dateString"];
        _note       = [coder decodeObjectForKey:@"note"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:_recordID   forKey:@"recordID"];
    [coder encodeInteger:_type      forKey:@"type"];
    [coder encodeDouble:_amount     forKey:@"amount"];
    [coder encodeObject:_category   forKey:@"category"];
    [coder encodeObject:_dateString forKey:@"dateString"];
    [coder encodeObject:_note       forKey:@"note"];
}

#pragma mark - Category Info

+ (NSDictionary<NSString*,NSArray*> *)_categoryMap {
    static NSDictionary *map = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        map = @{
            // key : @[icon, name]
            @"food"      : @[@"🍜", @"餐饮"],
            @"shop"      : @[@"🛍", @"购物"],
            @"transport" : @[@"🚌", @"交通"],
            @"house"     : @[@"🏠", @"住房"],
            @"medical"   : @[@"💊", @"医疗"],
            @"entertain" : @[@"🎮", @"娱乐"],
            @"edu"       : @[@"📚", @"教育"],
            @"beauty"    : @[@"💄", @"美容"],
            @"gift"      : @[@"🎁", @"礼物"],
            @"other_e"   : @[@"📦", @"其他"],
            @"salary"    : @[@"💰", @"工资"],
            @"bonus"     : @[@"🎉", @"奖金"],
            @"invest"    : @[@"📈", @"投资"],
            @"freelance" : @[@"💼", @"兼职"],
            @"rent_in"   : @[@"🏘", @"租金"],
            @"other_i"   : @[@"💵", @"其他"],
        };
    });
    return map;
}

+ (NSArray<NSString *> *)expenseCategoryKeys {
    return @[@"food",@"shop",@"transport",@"house",@"medical",@"entertain",@"edu",@"beauty",@"gift",@"other_e"];
}

+ (NSArray<NSString *> *)incomeCategoryKeys {
    return @[@"salary",@"bonus",@"invest",@"freelance",@"rent_in",@"other_i"];
}

+ (NSString *)iconForCategory:(NSString *)key {
    return [self _categoryMap][key][0] ?: @"📝";
}

+ (NSString *)nameForCategory:(NSString *)key {
    return [self _categoryMap][key][1] ?: key;
}

@end
