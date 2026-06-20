// LedgerMonthViewController.m
// 月汇总：月度收支汇总 + 分类支出 + 本月明细

#import "LedgerMonthViewController.h"
#import "LedgerStore.h"
#import "LedgerAddViewController.h"

#define COLOR_BG         [UIColor colorWithRed:.98 green:.97 blue:.94 alpha:1]
#define COLOR_CARD       [UIColor whiteColor]
#define COLOR_INCOME     [UIColor colorWithRed:.06 green:.43 blue:.34 alpha:1]
#define COLOR_INCOME_BG  [UIColor colorWithRed:.88 green:.96 blue:.93 alpha:1]
#define COLOR_EXPENSE    [UIColor colorWithRed:.60 green:.24 blue:.11 alpha:1]
#define COLOR_EXPENSE_BG [UIColor colorWithRed:.98 green:.93 blue:.91 alpha:1]
#define COLOR_TEXT       [UIColor colorWithRed:.17 green:.17 blue:.16 alpha:1]
#define COLOR_TEXT2      [UIColor colorWithRed:.37 green:.37 blue:.35 alpha:1]
#define COLOR_TEXT3      [UIColor colorWithRed:.53 green:.53 blue:.50 alpha:1]

// ── Record Cell (reuse same design) ─────────────────────
@interface LMonthRecordCell : UITableViewCell
- (void)configureWithRecord:(LedgerRecord *)record;
@end
@implementation LMonthRecordCell {
    UILabel *_iconLabel, *_titleLabel, *_metaLabel, *_amountLabel;
}
- (instancetype)initWithStyle:(UITableViewCellStyle)s reuseIdentifier:(NSString *)r {
    self = [super initWithStyle:s reuseIdentifier:r];
    self.backgroundColor = UIColor.whiteColor;
    UIView *bg = [[UIView alloc] initWithFrame:CGRectMake(16,10,40,40)];
    bg.layer.cornerRadius = 20; bg.tag = 10;
    [self.contentView addSubview:bg];
    _iconLabel = [[UILabel alloc] initWithFrame:CGRectMake(0,0,40,40)];
    _iconLabel.textAlignment = NSTextAlignmentCenter;
    _iconLabel.font = [UIFont systemFontOfSize:20];
    [bg addSubview:_iconLabel];
    _titleLabel = [[UILabel alloc] init];
    _titleLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightMedium];
    _titleLabel.textColor = COLOR_TEXT;
    [self.contentView addSubview:_titleLabel];
    _metaLabel = [[UILabel alloc] init];
    _metaLabel.font = [UIFont systemFontOfSize:11];
    _metaLabel.textColor = COLOR_TEXT3;
    [self.contentView addSubview:_metaLabel];
    _amountLabel = [[UILabel alloc] init];
    _amountLabel.textAlignment = NSTextAlignmentRight;
    _amountLabel.font = [UIFont systemFontOfSize:15 weight:UIFontWeightMedium];
    [self.contentView addSubview:_amountLabel];
    return self;
}
- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat W = self.contentView.bounds.size.width;
    _titleLabel.frame  = CGRectMake(68, 9, W-188, 20);
    _metaLabel.frame   = CGRectMake(68, 30, W-188, 16);
    _amountLabel.frame = CGRectMake(W-120, 18, 104, 22);
}
- (void)configureWithRecord:(LedgerRecord *)r {
    BOOL isInc = r.type == LedgerTypeIncome;
    UIView *bg = [self.contentView viewWithTag:10];
    bg.backgroundColor = isInc ? COLOR_INCOME_BG : COLOR_EXPENSE_BG;
    _iconLabel.text = [LedgerRecord iconForCategory:r.category];
    NSString *catName = [LedgerRecord nameForCategory:r.category];
    _titleLabel.text = r.note.length ? [NSString stringWithFormat:@"%@ · %@", catName, r.note] : catName;
    _metaLabel.text  = r.dateString;
    _amountLabel.text  = [NSString stringWithFormat:@"%@¥%.2f", isInc?@"+":@"-", r.amount];
    _amountLabel.textColor = isInc ? COLOR_INCOME : COLOR_EXPENSE;
}
@end

// ─────────────────────────────────────────────────────────
@interface LedgerMonthViewController () <UITableViewDataSource, UITableViewDelegate,
                                         LedgerAddViewControllerDelegate>
@property (nonatomic, strong) UILabel *periodLabel;
@property (nonatomic, strong) UILabel *incomeLabel, *expenseLabel, *balanceLabel;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSArray<LedgerRecord *> *monthRecords;
@property (nonatomic, strong) NSArray<NSDictionary *> *catExpenseItems;  // [{cat, amount}]
@property (nonatomic, assign) NSInteger year;
@property (nonatomic, assign) NSInteger month; // 1~12
@end

@implementation LedgerMonthViewController

- (instancetype)init {
    self = [super init];
    if (self) {
        NSCalendar *cal = [NSCalendar currentCalendar];
        NSDateComponents *c = [cal components:NSCalendarUnitYear|NSCalendarUnitMonth fromDate:[NSDate date]];
        _year  = c.year;
        _month = c.month;
    }
    return self;
}

- (void)jumpToYear:(NSInteger)year month:(NSInteger)month {
    _year = year; _month = month;
    [self reloadData];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"月汇总";
    self.view.backgroundColor = COLOR_BG;
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]
        initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addRecord)];
    self.navigationItem.rightBarButtonItem.tintColor = COLOR_INCOME;
    [self buildUI];
    [self reloadData];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self reloadData];
}

- (void)buildUI {
    CGFloat W = self.view.bounds.size.width;
    
    UIView *topBar = [[UIView alloc] initWithFrame:CGRectMake(0,0,W,100)];
    topBar.backgroundColor = COLOR_CARD;
    [self.view addSubview:topBar];
    
    UIButton *prev = [UIButton buttonWithType:UIButtonTypeSystem];
    prev.frame = CGRectMake(W/2-100,8,40,34);
    [prev setTitle:@"‹" forState:UIControlStateNormal];
    prev.titleLabel.font = [UIFont systemFontOfSize:28];
    prev.tintColor = COLOR_TEXT2;
    [prev addTarget:self action:@selector(prevMonth) forControlEvents:UIControlEventTouchUpInside];
    [topBar addSubview:prev];
    
    _periodLabel = [[UILabel alloc] initWithFrame:CGRectMake(W/2-60,12,120,26)];
    _periodLabel.textAlignment = NSTextAlignmentCenter;
    _periodLabel.font = [UIFont systemFontOfSize:15 weight:UIFontWeightMedium];
    _periodLabel.textColor = COLOR_TEXT;
    [topBar addSubview:_periodLabel];
    
    UIButton *next = [UIButton buttonWithType:UIButtonTypeSystem];
    next.frame = CGRectMake(W/2+60,8,40,34);
    [next setTitle:@"›" forState:UIControlStateNormal];
    next.titleLabel.font = [UIFont systemFontOfSize:28];
    next.tintColor = COLOR_TEXT2;
    [next addTarget:self action:@selector(nextMonth) forControlEvents:UIControlEventTouchUpInside];
    [topBar addSubview:next];
    
    CGFloat cW = (W-48)/3.0;
    NSInteger tags[] = {300,301,302};
    NSArray *labels = @[@"收入",@"支出",@"结余"];
    for (NSInteger i=0;i<3;i++) {
        UIView *card = [[UIView alloc] initWithFrame:CGRectMake(16+i*(cW+8),50,cW,42)];
        card.backgroundColor = [UIColor colorWithRed:.96 green:.95 blue:.92 alpha:1];
        card.layer.cornerRadius = 8;
        [topBar addSubview:card];
        UILabel *tl = [[UILabel alloc] initWithFrame:CGRectMake(6,2,cW-12,14)];
        tl.text = labels[i]; tl.font=[UIFont systemFontOfSize:11]; tl.textColor=COLOR_TEXT3;
        [card addSubview:tl];
        UILabel *vl = [[UILabel alloc] initWithFrame:CGRectMake(4,17,cW-8,20)];
        vl.font=[UIFont systemFontOfSize:13 weight:UIFontWeightMedium];
        vl.tag=tags[i]; vl.adjustsFontSizeToFitWidth=YES;
        if(i==0){vl.textColor=COLOR_INCOME;_incomeLabel=vl;}
        else if(i==1){vl.textColor=COLOR_EXPENSE;_expenseLabel=vl;}
        else{_balanceLabel=vl;}
        [card addSubview:vl];
    }
    
    _tableView = [[UITableView alloc] initWithFrame:CGRectMake(0,100,W,self.view.bounds.size.height-100)
                                              style:UITableViewStyleGrouped];
    _tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    _tableView.backgroundColor = COLOR_BG;
    _tableView.separatorInset = UIEdgeInsetsMake(0,68,0,0);
    _tableView.dataSource = self;
    _tableView.delegate   = self;
    _tableView.rowHeight  = 60;
    [_tableView registerClass:[LMonthRecordCell class] forCellReuseIdentifier:@"MCell"];
    [self.view addSubview:_tableView];
}

- (void)reloadData {
    NSString *ym = [NSString stringWithFormat:@"%04ld-%02ld", (long)_year, (long)_month];
    _monthRecords = [[[LedgerStore shared] recordsForMonth:ym] sortedArrayUsingComparator:^(LedgerRecord *a, LedgerRecord *b){
        NSComparisonResult r = [b.dateString compare:a.dateString];
        return r != NSOrderedSame ? r : [b.recordID compare:a.recordID];
    }];
    
    _periodLabel.text = [NSString stringWithFormat:@"%ld年%ld月", (long)_year, (long)_month];
    
    LedgerStore *s = [LedgerStore shared];
    double inc = [s incomeForRecords:_monthRecords];
    double exp = [s expenseForRecords:_monthRecords];
    double bal = inc - exp;
    _incomeLabel.text  = [NSString stringWithFormat:@"¥%.2f", inc];
    _expenseLabel.text = [NSString stringWithFormat:@"¥%.2f", exp];
    _balanceLabel.text = [NSString stringWithFormat:@"¥%.2f", bal];
    _balanceLabel.textColor = bal>=0?COLOR_INCOME:COLOR_EXPENSE;
    
    // 分类支出统计
    NSMutableDictionary *catMap = [NSMutableDictionary dictionary];
    for (LedgerRecord *r in _monthRecords) {
        if (r.type == LedgerTypeExpense) {
            catMap[r.category] = @([catMap[r.category] doubleValue] + r.amount);
        }
    }
    NSArray *sorted = [[catMap allKeys] sortedArrayUsingComparator:^(NSString *a, NSString *b){
        return [catMap[b] compare:catMap[a]];
    }];
    NSMutableArray *items = [NSMutableArray array];
    double total = exp;
    for (NSString *k in sorted) {
        double amt = [catMap[k] doubleValue];
        NSInteger pct = total > 0 ? (NSInteger)(amt/total*100) : 0;
        [items addObject:@{@"cat":k, @"amount":@(amt), @"pct":@(pct)}];
    }
    _catExpenseItems = items;
    
    [_tableView reloadData];
}

- (void)prevMonth {
    _month--;
    if (_month < 1) { _month = 12; _year--; }
    [self reloadData];
}
- (void)nextMonth {
    _month++;
    if (_month > 12) { _month = 1; _year++; }
    [self reloadData];
}

- (void)addRecord {
    NSString *dateStr = [NSString stringWithFormat:@"%04ld-%02ld-01", (long)_year, (long)_month];
    LedgerAddViewController *vc = [[LedgerAddViewController alloc] initWithRecord:nil defaultDate:dateStr];
    vc.delegate = self;
    [self presentViewController:[[UINavigationController alloc] initWithRootViewController:vc] animated:YES completion:nil];
}
- (void)ledgerAddVC:(LedgerAddViewController *)vc didSaveRecord:(LedgerRecord *)record isNew:(BOOL)isNew {
    if (isNew) [[LedgerStore shared] addRecord:record];
    else [[LedgerStore shared] updateRecord:record];
    [self reloadData];
}

#pragma mark - TableView

// Section 0: 分类支出  Section 1: 明细
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tv { return 2; }
- (NSInteger)tableView:(UITableView *)tv numberOfRowsInSection:(NSInteger)section {
    if (section == 0) return MAX(_catExpenseItems.count, 1);
    return MAX(_monthRecords.count, 1);
}
- (NSString *)tableView:(UITableView *)tv titleForHeaderInSection:(NSInteger)section {
    return section == 0 ? @"支出分类" : @"本月明细";
}
- (CGFloat)tableView:(UITableView *)tv heightForRowAtIndexPath:(NSIndexPath *)ip {
    return ip.section == 0 ? 44 : 60;
}
- (UITableViewCell *)tableView:(UITableView *)tv cellForRowAtIndexPath:(NSIndexPath *)ip {
    if (ip.section == 0) {
        UITableViewCell *cell = [tv dequeueReusableCellWithIdentifier:@"CatCell"];
        if (!cell) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"CatCell"];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        if (_catExpenseItems.count == 0) {
            cell.textLabel.text = @"本月无支出";
            cell.textLabel.textColor = COLOR_TEXT3;
            cell.detailTextLabel.text = @"";
            cell.imageView.image = nil;
            return cell;
        }
        NSDictionary *item = _catExpenseItems[ip.row];
        NSString *cat = item[@"cat"];
        cell.textLabel.text = [NSString stringWithFormat:@"%@ %@  %ld%%",
            [LedgerRecord iconForCategory:cat],
            [LedgerRecord nameForCategory:cat],
            (long)[item[@"pct"] integerValue]];
        cell.textLabel.font = [UIFont systemFontOfSize:13];
        cell.detailTextLabel.text = [NSString stringWithFormat:@"-¥%.2f", [item[@"amount"] doubleValue]];
        cell.detailTextLabel.textColor = COLOR_EXPENSE;
        return cell;
    } else {
        LMonthRecordCell *cell = [tv dequeueReusableCellWithIdentifier:@"MCell" forIndexPath:ip];
        if (_monthRecords.count == 0) {
            UITableViewCell *empty = [[UITableViewCell alloc] init];
            empty.textLabel.text = @"本月暂无记录";
            empty.textLabel.textColor = COLOR_TEXT3;
            empty.textLabel.font = [UIFont systemFontOfSize:13];
            empty.textLabel.textAlignment = NSTextAlignmentCenter;
            empty.backgroundColor = UIColor.clearColor;
            empty.selectionStyle = UITableViewCellSelectionStyleNone;
            return empty;
        }
        [cell configureWithRecord:_monthRecords[ip.row]];
        return cell;
    }
}
- (void)tableView:(UITableView *)tv didSelectRowAtIndexPath:(NSIndexPath *)ip {
    [tv deselectRowAtIndexPath:ip animated:YES];
    if (ip.section != 1 || _monthRecords.count == 0) return;
    LedgerRecord *r = _monthRecords[ip.row];
    LedgerAddViewController *vc = [[LedgerAddViewController alloc] initWithRecord:r defaultDate:r.dateString];
    vc.delegate = self;
    [self presentViewController:[[UINavigationController alloc] initWithRootViewController:vc] animated:YES completion:nil];
}
- (UISwipeActionsConfiguration *)tableView:(UITableView *)tv
    trailingSwipeActionsConfigurationForRowAtIndexPath:(NSIndexPath *)ip {
    if (ip.section != 1 || _monthRecords.count == 0) return nil;
    LedgerRecord *r = _monthRecords[ip.row];
    UIContextualAction *del = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleDestructive title:@"删除"
        handler:^(UIContextualAction *a, UIView *v, void(^c)(BOOL)){
        [[LedgerStore shared] deleteRecord:r.recordID];
        [self reloadData]; c(YES);
    }];
    return [UISwipeActionsConfiguration configurationWithActions:@[del]];
}

@end
