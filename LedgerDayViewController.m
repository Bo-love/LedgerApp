// LedgerDayViewController.m
// 日记账页面 - 支持按天/按周浏览，带收支汇总和记录列表

#import "LedgerDayViewController.h"
#import "LedgerStore.h"
#import "LedgerAddViewController.h"

// ── 颜色 ─────────────────────────────────────────────
#define COLOR_BG         [UIColor colorWithRed:.98 green:.97 blue:.94 alpha:1]
#define COLOR_CARD       [UIColor whiteColor]
#define COLOR_INCOME     [UIColor colorWithRed:.06 green:.43 blue:.34 alpha:1]
#define COLOR_INCOME_BG  [UIColor colorWithRed:.88 green:.96 blue:.93 alpha:1]
#define COLOR_EXPENSE    [UIColor colorWithRed:.60 green:.24 blue:.11 alpha:1]
#define COLOR_EXPENSE_BG [UIColor colorWithRed:.98 green:.93 blue:.91 alpha:1]
#define COLOR_TEXT       [UIColor colorWithRed:.17 green:.17 blue:.16 alpha:1]
#define COLOR_TEXT2      [UIColor colorWithRed:.37 green:.37 blue:.35 alpha:1]
#define COLOR_TEXT3      [UIColor colorWithRed:.53 green:.53 blue:.50 alpha:1]
#define COLOR_BORDER     [UIColor colorWithRed:0 green:0 blue:0 alpha:.10]

// ── Record Cell ─────────────────────────────────────
@interface LedgerRecordCell : UITableViewCell
- (void)configureWithRecord:(LedgerRecord *)record;
@end
@implementation LedgerRecordCell {
    UILabel *_iconLabel, *_titleLabel, *_metaLabel, *_amountLabel;
}
- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)ri {
    self = [super initWithStyle:style reuseIdentifier:ri];
    self.backgroundColor = UIColor.whiteColor;
    self.selectionStyle  = UITableViewCellSelectionStyleDefault;
    
    UIView *iconBG = [[UIView alloc] initWithFrame:CGRectMake(16,10,40,40)];
    iconBG.layer.cornerRadius = 20;
    iconBG.tag = 10;
    [self.contentView addSubview:iconBG];
    
    _iconLabel = [[UILabel alloc] initWithFrame:CGRectMake(0,0,40,40)];
    _iconLabel.textAlignment = NSTextAlignmentCenter;
    _iconLabel.font = [UIFont systemFontOfSize:20];
    [iconBG addSubview:_iconLabel];
    
    _titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(68,8,200,20)];
    _titleLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightMedium];
    _titleLabel.textColor = COLOR_TEXT;
    [self.contentView addSubview:_titleLabel];
    
    _metaLabel = [[UILabel alloc] initWithFrame:CGRectMake(68,30,200,16)];
    _metaLabel.font = [UIFont systemFontOfSize:11];
    _metaLabel.textColor = COLOR_TEXT3;
    [self.contentView addSubview:_metaLabel];
    
    _amountLabel = [[UILabel alloc] initWithFrame:CGRectMake(0,0,100,20)];
    _amountLabel.textAlignment = NSTextAlignmentRight;
    _amountLabel.font = [UIFont systemFontOfSize:15 weight:UIFontWeightMedium];
    [self.contentView addSubview:_amountLabel];
    
    return self;
}
- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat W = self.contentView.bounds.size.width;
    _amountLabel.frame = CGRectMake(W-120, 18, 104, 22);
    _titleLabel.frame  = CGRectMake(68, 9, W-188, 20);
    _metaLabel.frame   = CGRectMake(68, 30, W-188, 16);
}
- (void)configureWithRecord:(LedgerRecord *)r {
    BOOL isInc = r.type == LedgerTypeIncome;
    UIView *iconBG = [self.contentView viewWithTag:10];
    iconBG.backgroundColor = isInc ? COLOR_INCOME_BG : COLOR_EXPENSE_BG;
    _iconLabel.text  = [LedgerRecord iconForCategory:r.category];
    NSString *catName = [LedgerRecord nameForCategory:r.category];
    _titleLabel.text = r.note.length ? [NSString stringWithFormat:@"%@ · %@", catName, r.note] : catName;
    _metaLabel.text  = r.dateString;
    _amountLabel.text  = [NSString stringWithFormat:@"%@¥%.2f", isInc ? @"+" : @"-", r.amount];
    _amountLabel.textColor = isInc ? COLOR_INCOME : COLOR_EXPENSE;
}
@end

// ── Main VC ─────────────────────────────────────────────
@interface LedgerDayViewController () <UITableViewDataSource, UITableViewDelegate,
                                       LedgerAddViewControllerDelegate>
@property (nonatomic, strong) UISegmentedControl *viewModeSegment;  // 日 / 周
@property (nonatomic, strong) UIButton *prevBtn, *nextBtn;
@property (nonatomic, strong) UILabel  *periodLabel;
@property (nonatomic, strong) UILabel  *incomeLabel, *expenseLabel, *balanceLabel;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSArray<LedgerRecord *> *displayRecords;
@property (nonatomic, assign) NSInteger dayOffset;    // 0=今天
@property (nonatomic, assign) BOOL      isWeekMode;
@end

@implementation LedgerDayViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"日记账";
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

#pragma mark - Build UI

- (void)buildUI {
    CGFloat W = self.view.bounds.size.width;
    
    // 顶部控制栏
    UIView *topBar = [[UIView alloc] initWithFrame:CGRectMake(0, 0, W, 100)];
    topBar.backgroundColor = COLOR_CARD;
    topBar.layer.shadowColor = [UIColor blackColor].CGColor;
    topBar.layer.shadowOpacity = .04;
    topBar.layer.shadowOffset = CGSizeMake(0,2);
    [self.view addSubview:topBar];
    
    // 日/周 切换
    _viewModeSegment = [[UISegmentedControl alloc] initWithItems:@[@"按日", @"按周"]];
    _viewModeSegment.frame = CGRectMake(16, 12, 120, 30);
    _viewModeSegment.selectedSegmentIndex = 0;
    if (@available(iOS 13.0, *)) { _viewModeSegment.selectedSegmentTintColor = COLOR_INCOME; }
    [_viewModeSegment addTarget:self action:@selector(viewModeChanged:) forControlEvents:UIControlEventValueChanged];
    [topBar addSubview:_viewModeSegment];
    
    // 翻页
    _prevBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    _prevBtn.frame = CGRectMake(W/2-100, 10, 40, 34);
    [_prevBtn setTitle:@"‹" forState:UIControlStateNormal];
    _prevBtn.titleLabel.font = [UIFont systemFontOfSize:28];
    _prevBtn.tintColor = COLOR_TEXT2;
    [_prevBtn addTarget:self action:@selector(prevPeriod) forControlEvents:UIControlEventTouchUpInside];
    [topBar addSubview:_prevBtn];
    
    _periodLabel = [[UILabel alloc] initWithFrame:CGRectMake(W/2-60, 14, 120, 26)];
    _periodLabel.textAlignment = NSTextAlignmentCenter;
    _periodLabel.font = [UIFont systemFontOfSize:15 weight:UIFontWeightMedium];
    _periodLabel.textColor = COLOR_TEXT;
    [topBar addSubview:_periodLabel];
    
    _nextBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    _nextBtn.frame = CGRectMake(W/2+60, 10, 40, 34);
    [_nextBtn setTitle:@"›" forState:UIControlStateNormal];
    _nextBtn.titleLabel.font = [UIFont systemFontOfSize:28];
    _nextBtn.tintColor = COLOR_TEXT2;
    [_nextBtn addTarget:self action:@selector(nextPeriod) forControlEvents:UIControlEventTouchUpInside];
    [topBar addSubview:_nextBtn];
    
    // 汇总卡片行
    CGFloat cardW = (W - 48) / 3.0;
    NSArray *cards = @[@[@"收入", @"income"], @[@"支出", @"expense"], @[@"结余", @"balance"]];
    NSInteger tags[] = {300, 301, 302};
    for (NSInteger i = 0; i < 3; i++) {
        UIView *card = [[UIView alloc] initWithFrame:CGRectMake(16 + i*(cardW+8), 54, cardW, 38)];
        card.backgroundColor = [UIColor colorWithRed:.96 green:.95 blue:.92 alpha:1];
        card.layer.cornerRadius = 8;
        [topBar addSubview:card];
        
        UILabel *tl = [[UILabel alloc] initWithFrame:CGRectMake(6, 2, cardW-12, 14)];
        tl.text = cards[i][0];
        tl.font = [UIFont systemFontOfSize:11];
        tl.textColor = COLOR_TEXT3;
        [card addSubview:tl];
        
        UILabel *vl = [[UILabel alloc] initWithFrame:CGRectMake(4, 16, cardW-8, 18)];
        vl.font = [UIFont systemFontOfSize:13 weight:UIFontWeightMedium];
        vl.tag = tags[i];
        vl.adjustsFontSizeToFitWidth = YES;
        if (i == 0) { vl.textColor = COLOR_INCOME; _incomeLabel = vl; }
        else if (i == 1) { vl.textColor = COLOR_EXPENSE; _expenseLabel = vl; }
        else { _balanceLabel = vl; }
        [card addSubview:vl];
    }
    
    // TableView
    _tableView = [[UITableView alloc] initWithFrame:CGRectMake(0,100,W,self.view.bounds.size.height-100-self.tabBarController.tabBar.frame.size.height)
                                              style:UITableViewStyleGrouped];
    _tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _tableView.backgroundColor = COLOR_BG;
    _tableView.separatorInset  = UIEdgeInsetsMake(0, 68, 0, 0);
    _tableView.dataSource = self;
    _tableView.delegate   = self;
    _tableView.rowHeight  = 60;
    [_tableView registerClass:[LedgerRecordCell class] forCellReuseIdentifier:@"RecordCell"];
    [self.view addSubview:_tableView];
}

#pragma mark - Data

- (void)reloadData {
    LedgerStore *store = [LedgerStore shared];
    NSDateFormatter *fmt = [[NSDateFormatter alloc] init];
    fmt.dateFormat = @"yyyy-MM-dd";
    
    NSCalendar *cal = [NSCalendar currentCalendar];
    NSDate *base = [cal dateByAddingUnit:NSCalendarUnitDay value:_dayOffset toDate:[NSDate date] options:0];
    
    if (!_isWeekMode) {
        NSString *ds = [fmt stringFromDate:base];
        _displayRecords = [[store recordsForDate:ds] sortedArrayUsingComparator:^(LedgerRecord *a, LedgerRecord *b){
            return [b.recordID compare:a.recordID];
        }];
        // Label
        NSDateComponents *comp = [cal components:NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay|NSCalendarUnitWeekday fromDate:base];
        NSArray *wn = @[@"日",@"一",@"二",@"三",@"四",@"五",@"六"];
        NSInteger relDay = _dayOffset;
        NSString *relLabel = relDay==0?@"今天":relDay==-1?@"昨天":relDay==1?@"明天":
            [NSString stringWithFormat:@"%ld月%ld日", (long)comp.month, (long)comp.day];
        _periodLabel.text = [NSString stringWithFormat:@"%@ 周%@", relLabel, wn[comp.weekday-1]];
    } else {
        // 找本周周一到周日
        NSDateComponents *wComp = [cal components:NSCalendarUnitWeekday fromDate:base];
        NSInteger weekday = wComp.weekday; // 1=Sun
        NSInteger daysToMon = (weekday == 1) ? -6 : -(weekday - 2);
        NSDate *monDate = [cal dateByAddingUnit:NSCalendarUnitDay value:daysToMon toDate:base options:0];
        NSDate *sunDate = [cal dateByAddingUnit:NSCalendarUnitDay value:6 toDate:monDate options:0];
        NSString *monStr = [fmt stringFromDate:monDate];
        NSString *sunStr = [fmt stringFromDate:sunDate];
        _displayRecords = [[store allRecords] filteredArrayUsingPredicate:
            [NSPredicate predicateWithFormat:@"dateString >= %@ AND dateString <= %@", monStr, sunStr]];
        _displayRecords = [_displayRecords sortedArrayUsingComparator:^(LedgerRecord *a, LedgerRecord *b){
            NSComparisonResult r = [b.dateString compare:a.dateString];
            return r != NSOrderedSame ? r : [b.recordID compare:a.recordID];
        }];
        NSDateComponents *mc = [cal components:NSCalendarUnitMonth|NSCalendarUnitDay fromDate:monDate];
        NSDateComponents *sc = [cal components:NSCalendarUnitMonth|NSCalendarUnitDay fromDate:sunDate];
        _periodLabel.text = [NSString stringWithFormat:@"%ld/%ld - %ld/%ld",
            (long)mc.month,(long)mc.day,(long)sc.month,(long)sc.day];
    }
    
    double inc = [store incomeForRecords:_displayRecords];
    double exp = [store expenseForRecords:_displayRecords];
    double bal = inc - exp;
    _incomeLabel.text   = [NSString stringWithFormat:@"¥%.2f", inc];
    _expenseLabel.text  = [NSString stringWithFormat:@"¥%.2f", exp];
    _balanceLabel.text  = [NSString stringWithFormat:@"¥%.2f", bal];
    _balanceLabel.textColor = bal >= 0 ? COLOR_INCOME : COLOR_EXPENSE;
    
    [_tableView reloadData];
}

#pragma mark - Navigation

- (void)prevPeriod { _dayOffset += _isWeekMode ? -7 : -1; [self reloadData]; }
- (void)nextPeriod { _dayOffset += _isWeekMode ? 7 : 1;  [self reloadData]; }

- (void)viewModeChanged:(UISegmentedControl *)seg {
    _isWeekMode = seg.selectedSegmentIndex == 1;
    [self reloadData];
}

#pragma mark - Add / Edit

- (void)addRecord {
    NSDateFormatter *fmt = [[NSDateFormatter alloc] init];
    fmt.dateFormat = @"yyyy-MM-dd";
    NSCalendar *cal = [NSCalendar currentCalendar];
    NSDate *base = [cal dateByAddingUnit:NSCalendarUnitDay value:_dayOffset toDate:[NSDate date] options:0];
    NSString *dateStr = _isWeekMode ? [fmt stringFromDate:[NSDate date]] : [fmt stringFromDate:base];
    
    LedgerAddViewController *addVC = [[LedgerAddViewController alloc] initWithRecord:nil defaultDate:dateStr];
    addVC.delegate = self;
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:addVC];
    [self presentViewController:nav animated:YES completion:nil];
}

- (void)ledgerAddVC:(LedgerAddViewController *)vc didSaveRecord:(LedgerRecord *)record isNew:(BOOL)isNew {
    if (isNew) {
        [[LedgerStore shared] addRecord:record];
    } else {
        [[LedgerStore shared] updateRecord:record];
    }
    [self reloadData];
}

#pragma mark - UITableView

- (NSInteger)tableView:(UITableView *)tv numberOfRowsInSection:(NSInteger)section {
    return _displayRecords.count > 0 ? _displayRecords.count : 1;
}

- (UITableViewCell *)tableView:(UITableView *)tv cellForRowAtIndexPath:(NSIndexPath *)ip {
    if (_displayRecords.count == 0) {
        UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
        cell.textLabel.text = @"今日暂无记录，点击右上角 + 添加";
        cell.textLabel.textColor = COLOR_TEXT3;
        cell.textLabel.font = [UIFont systemFontOfSize:13];
        cell.textLabel.textAlignment = NSTextAlignmentCenter;
        cell.backgroundColor = UIColor.clearColor;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        return cell;
    }
    LedgerRecordCell *cell = [tv dequeueReusableCellWithIdentifier:@"RecordCell" forIndexPath:ip];
    [cell configureWithRecord:_displayRecords[ip.row]];
    return cell;
}

- (void)tableView:(UITableView *)tv didSelectRowAtIndexPath:(NSIndexPath *)ip {
    [tv deselectRowAtIndexPath:ip animated:YES];
    if (_displayRecords.count == 0) return;
    LedgerRecord *r = _displayRecords[ip.row];
    LedgerAddViewController *addVC = [[LedgerAddViewController alloc] initWithRecord:r defaultDate:r.dateString];
    addVC.delegate = self;
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:addVC];
    [self presentViewController:nav animated:YES completion:nil];
}

- (UISwipeActionsConfiguration *)tableView:(UITableView *)tv
    trailingSwipeActionsConfigurationForRowAtIndexPath:(NSIndexPath *)ip {
    if (_displayRecords.count == 0) return nil;
    LedgerRecord *r = _displayRecords[ip.row];
    UIContextualAction *del = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleDestructive
                                                                       title:@"删除"
                                                                     handler:^(UIContextualAction *action, __kindof UIView *v, void (^completion)(BOOL)) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"确认删除" message:@"删除后无法恢复" preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction *a){ completion(NO); }]];
        [alert addAction:[UIAlertAction actionWithTitle:@"删除" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *a){
            [[LedgerStore shared] deleteRecord:r.recordID];
            [self reloadData];
            completion(YES);
        }]];
        [self presentViewController:alert animated:YES completion:nil];
    }];
    return [UISwipeActionsConfiguration configurationWithActions:@[del]];
}

- (NSString *)tableView:(UITableView *)tv titleForHeaderInSection:(NSInteger)section {
    return _displayRecords.count > 0 ? @"明细记录" : nil;
}

@end
