// LedgerStatsViewController.m
// 统计分析：年度分类收支饼图 + 明细排行（纯 UIKit，无第三方图表库）

#import "LedgerStatsViewController.h"
#import "LedgerStore.h"
#import <objc/runtime.h>

#define COLOR_BG         [UIColor colorWithRed:.98 green:.97 blue:.94 alpha:1]
#define COLOR_CARD       [UIColor whiteColor]
#define COLOR_INCOME     [UIColor colorWithRed:.06 green:.43 blue:.34 alpha:1]
#define COLOR_INCOME_BG  [UIColor colorWithRed:.88 green:.96 blue:.93 alpha:1]
#define COLOR_EXPENSE    [UIColor colorWithRed:.60 green:.24 blue:.11 alpha:1]
#define COLOR_EXPENSE_BG [UIColor colorWithRed:.98 green:.93 blue:.91 alpha:1]
#define COLOR_TEXT       [UIColor colorWithRed:.17 green:.17 blue:.16 alpha:1]
#define COLOR_TEXT2      [UIColor colorWithRed:.37 green:.37 blue:.35 alpha:1]
#define COLOR_TEXT3      [UIColor colorWithRed:.53 green:.53 blue:.50 alpha:1]

// 10色调色板（支出/收入通用）
static UIColor* pieColor(NSInteger idx) {
    NSArray *colors = @[
        [UIColor colorWithRed:.12 green:.62 blue:.46 alpha:1],
        [UIColor colorWithRed:.22 green:.53 blue:.85 alpha:1],
        [UIColor colorWithRed:.73 green:.46 blue:.09 alpha:1],
        [UIColor colorWithRed:.83 green:.33 blue:.49 alpha:1],
        [UIColor colorWithRed:.50 green:.47 blue:.87 alpha:1],
        [UIColor colorWithRed:.85 green:.35 blue:.19 alpha:1],
        [UIColor colorWithRed:.39 green:.60 blue:.13 alpha:1],
        [UIColor colorWithRed:.60 green:.21 blue:.34 alpha:1],
        [UIColor colorWithRed:.33 green:.29 blue:.72 alpha:1],
        [UIColor colorWithRed:.09 green:.37 blue:.65 alpha:1],
    ];
    return colors[idx % colors.count];
}

// ── Pie Chart View ───────────────────────────────────────
@interface LPieChartView : UIView
- (void)setSlices:(NSArray<NSDictionary *> *)slices; // [{color, value}]
@end
@implementation LPieChartView {
    NSArray *_slices;
}
- (void)setSlices:(NSArray<NSDictionary *> *)slices {
    _slices = slices;
    [self setNeedsDisplay];
}
- (void)drawRect:(CGRect)rect {
    CGFloat cx = rect.size.width/2, cy = rect.size.height/2;
    CGFloat r  = MIN(cx, cy) - 6;
    CGFloat innerR = r * 0.55;
    
    double total = 0;
    for (NSDictionary *s in _slices) total += [s[@"value"] doubleValue];
    if (total <= 0) return;
    
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGFloat startAngle = -M_PI_2;
    
    for (NSDictionary *s in _slices) {
        double val = [s[@"value"] doubleValue];
        CGFloat sweep = (CGFloat)(val / total * M_PI * 2);
        CGFloat endAngle = startAngle + sweep;
        
        CGMutablePathRef path = CGPathCreateMutable();
        CGPathMoveToPoint(path, nil, cx, cy);
        CGPathAddArc(path, nil, cx, cy, r, startAngle, endAngle, NO);
        CGPathCloseSubpath(path);
        
        CGContextAddPath(ctx, path);
        [(UIColor *)s[@"color"] setFill];
        CGContextFillPath(ctx);
        CGPathRelease(path);
        
        startAngle = endAngle;
    }
    
    // 中心圆（镂空效果）
    CGContextSetFillColorWithColor(ctx, COLOR_CARD.CGColor);
    CGContextFillEllipseInRect(ctx, CGRectMake(cx-innerR, cy-innerR, innerR*2, innerR*2));
    
    // 边框分隔线
    CGContextSetStrokeColorWithColor(ctx, [UIColor whiteColor].CGColor);
    CGContextSetLineWidth(ctx, 1.5);
    startAngle = -M_PI_2;
    for (NSDictionary *s in _slices) {
        double val = [s[@"value"] doubleValue];
        CGFloat sweep = (CGFloat)(val / total * M_PI * 2);
        CGFloat endAngle = startAngle + sweep;
        CGContextMoveToPoint(ctx, cx, cy);
        CGContextAddLineToPoint(ctx, cx + r * cos(startAngle), cy + r * sin(startAngle));
        CGContextStrokePath(ctx);
        startAngle = endAngle;
    }
}
@end

// ── Main VC ─────────────────────────────────────────────
@interface LedgerStatsViewController () <UITableViewDataSource>
@property (nonatomic, strong) UISegmentedControl *typeSegment;
@property (nonatomic, strong) UIPickerView       *yearPicker;
@property (nonatomic, strong) UIButton           *yearButton;
@property (nonatomic, strong) LPieChartView      *pieView;
@property (nonatomic, strong) UILabel            *centerLabel;
@property (nonatomic, strong) UITableView        *tableView;
@property (nonatomic, strong) NSArray            *catItems;  // sorted [{cat, amount, pct, color}]
@property (nonatomic, strong) NSArray<NSNumber*> *availableYears;
@property (nonatomic, assign) NSInteger           selectedYear;
@property (nonatomic, assign) LedgerType          selectedType;
@end

@implementation LedgerStatsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"统计分析";
    self.view.backgroundColor = COLOR_BG;
    
    _selectedType = LedgerTypeExpense;
    _selectedYear = [[NSCalendar currentCalendar] components:NSCalendarUnitYear fromDate:[NSDate date]].year;
    
    [self buildUI];
    [self reloadData];
}
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self reloadData];
}

- (void)buildUI {
    CGFloat W = self.view.bounds.size.width;
    UIScrollView *sv = [[UIScrollView alloc] initWithFrame:self.view.bounds];
    sv.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    sv.alwaysBounceVertical = YES;
    [self.view addSubview:sv];
    
    CGFloat pad = 16, y = 16;
    
    // ── 控制栏 ──
    UIView *ctrlCard = [[UIView alloc] initWithFrame:CGRectMake(pad,y,W-pad*2,56)];
    ctrlCard.backgroundColor = COLOR_CARD;
    ctrlCard.layer.cornerRadius = 12;
    [sv addSubview:ctrlCard];
    
    // 年份按钮
    _yearButton = [UIButton buttonWithType:UIButtonTypeSystem];
    _yearButton.frame = CGRectMake(12, 12, 100, 32);
    _yearButton.tintColor = COLOR_TEXT;
    _yearButton.titleLabel.font = [UIFont systemFontOfSize:15 weight:UIFontWeightMedium];
    [_yearButton setTitle:[NSString stringWithFormat:@"%ld年 ▾", (long)_selectedYear]
                forState:UIControlStateNormal];
    [_yearButton addTarget:self action:@selector(pickYear) forControlEvents:UIControlEventTouchUpInside];
    [ctrlCard addSubview:_yearButton];
    
    // 收支切换
    _typeSegment = [[UISegmentedControl alloc] initWithItems:@[@"支出", @"收入"]];
    _typeSegment.frame = CGRectMake(ctrlCard.bounds.size.width-150, 12, 138, 32);
    _typeSegment.selectedSegmentIndex = 0;
    if (@available(iOS 13.0, *)) { _typeSegment.selectedSegmentTintColor = COLOR_INCOME; }
    [_typeSegment addTarget:self action:@selector(typeChanged:) forControlEvents:UIControlEventValueChanged];
    [ctrlCard addSubview:_typeSegment];
    y += 64;
    
    // ── 饼图卡片 ──
    UIView *pieCard = [[UIView alloc] initWithFrame:CGRectMake(pad,y,W-pad*2,220)];
    pieCard.backgroundColor = COLOR_CARD;
    pieCard.layer.cornerRadius = 12;
    pieCard.layer.borderWidth = 0.5;
    pieCard.layer.borderColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:.08].CGColor;
    [sv addSubview:pieCard];
    
    _pieView = [[LPieChartView alloc] initWithFrame:CGRectMake(pieCard.bounds.size.width/2-90,10,180,180)];
    _pieView.backgroundColor = UIColor.clearColor;
    [pieCard addSubview:_pieView];
    
    _centerLabel = [[UILabel alloc] initWithFrame:CGRectMake(0,0,120,40)];
    _centerLabel.center = CGPointMake(pieCard.bounds.size.width/2, 100);
    _centerLabel.textAlignment = NSTextAlignmentCenter;
    _centerLabel.numberOfLines = 2;
    _centerLabel.font = [UIFont systemFontOfSize:11];
    _centerLabel.textColor = COLOR_TEXT2;
    [pieCard addSubview:_centerLabel];
    y += 228;
    
    // ── 排行表 ──
    UILabel *rankTitle = [[UILabel alloc] initWithFrame:CGRectMake(pad,y,200,18)];
    rankTitle.text = @"分类排行";
    rankTitle.font = [UIFont systemFontOfSize:12];
    rankTitle.textColor = COLOR_TEXT3;
    [sv addSubview:rankTitle];
    y += 24;
    
    _tableView = [[UITableView alloc] initWithFrame:CGRectMake(0,y,W,0) style:UITableViewStylePlain];
    _tableView.backgroundColor = UIColor.clearColor;
    _tableView.scrollEnabled   = NO;
    _tableView.separatorInset  = UIEdgeInsetsMake(0,56,0,0);
    _tableView.dataSource      = self;
    _tableView.rowHeight       = 52;
    _tableView.layer.cornerRadius = 12;
    _tableView.clipsToBounds   = YES;
    [sv addSubview:_tableView];
    
    objc_setAssociatedObject(self, "sv", sv, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    objc_setAssociatedObject(self, "tableY", @(y), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)reloadData {
    // 可用年份
    NSArray *all = [[LedgerStore shared] allRecords];
    NSMutableSet *ys = [NSMutableSet set];
    for (LedgerRecord *r in all) [ys addObject:@([r.dateString substringToIndex:4].integerValue)];
    NSInteger curY = [[NSCalendar currentCalendar] components:NSCalendarUnitYear fromDate:[NSDate date]].year;
    [ys addObject:@(curY)];
    _availableYears = [[ys allObjects] sortedArrayUsingComparator:^(NSNumber *a, NSNumber *b){ return [b compare:a]; }];
    
    [_yearButton setTitle:[NSString stringWithFormat:@"%ld年 ▾",(long)_selectedYear] forState:UIControlStateNormal];
    
    // 分类统计
    NSArray *yearRecords = [[LedgerStore shared] recordsForYear:_selectedYear];
    NSMutableDictionary *catMap = [NSMutableDictionary dictionary];
    for (LedgerRecord *r in yearRecords) {
        if (r.type == _selectedType) {
            catMap[r.category] = @([catMap[r.category] doubleValue] + r.amount);
        }
    }
    NSArray *sortedKeys = [[catMap allKeys] sortedArrayUsingComparator:^(NSString *a, NSString *b){
        return [catMap[b] compare:catMap[a]];
    }];
    double total = 0;
    for (NSNumber *v in catMap.allValues) total += v.doubleValue;
    
    NSMutableArray *items = [NSMutableArray array];
    NSMutableArray *slices = [NSMutableArray array];
    for (NSInteger i=0; i<sortedKeys.count; i++) {
        NSString *k = sortedKeys[i];
        double amt = [catMap[k] doubleValue];
        NSInteger pct = total>0 ? (NSInteger)(amt/total*100) : 0;
        UIColor *c = pieColor(i);
        [items addObject:@{@"cat":k, @"amount":@(amt), @"pct":@(pct), @"color":c}];
        [slices addObject:@{@"value":@(amt), @"color":c}];
    }
    _catItems = items;
    
    [_pieView setSlices:slices];
    
    NSString *typeStr = _selectedType == LedgerTypeExpense ? @"总支出" : @"总收入";
    _centerLabel.text = [NSString stringWithFormat:@"%@\n¥%.2f", typeStr, total];
    
    [_tableView reloadData];
    
    // 更新 tableView 高度和 scrollView contentSize
    CGFloat tableH = _catItems.count * 52.0 + 1;
    if (_catItems.count == 0) tableH = 60;
    UIScrollView *sv = objc_getAssociatedObject(self, "sv");
    CGFloat tableY = [objc_getAssociatedObject(self,"tableY") floatValue];
    _tableView.frame = CGRectMake(16, tableY, self.view.bounds.size.width-32, tableH);
    sv.contentSize = CGSizeMake(self.view.bounds.size.width, tableY + tableH + 30);
}

- (void)typeChanged:(UISegmentedControl *)seg {
    _selectedType = seg.selectedSegmentIndex;
    [self reloadData];
}

- (void)pickYear {
    UIAlertController *sheet = [UIAlertController alertControllerWithTitle:@"选择年份"
                                                                    message:nil
                                                             preferredStyle:UIAlertControllerStyleActionSheet];
    for (NSNumber *y in _availableYears) {
        [sheet addAction:[UIAlertAction actionWithTitle:[NSString stringWithFormat:@"%ld年",(long)y.integerValue]
                                                  style:UIAlertActionStyleDefault
                                                handler:^(UIAlertAction *a){
            self->_selectedYear = y.integerValue;
            [self reloadData];
        }]];
    }
    [sheet addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:sheet animated:YES completion:nil];
}

#pragma mark - UITableView DataSource

- (NSInteger)tableView:(UITableView *)tv numberOfRowsInSection:(NSInteger)s {
    return MAX(_catItems.count, 1);
}
- (UITableViewCell *)tableView:(UITableView *)tv cellForRowAtIndexPath:(NSIndexPath *)ip {
    UITableViewCell *cell = [tv dequeueReusableCellWithIdentifier:@"SCell"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"SCell"];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.backgroundColor = UIColor.whiteColor;
    }
    if (_catItems.count == 0) {
        cell.textLabel.text = [NSString stringWithFormat:@"暂无%@记录", _selectedType==LedgerTypeExpense?@"支出":@"收入"];
        cell.textLabel.textColor = COLOR_TEXT3;
        cell.textLabel.font = [UIFont systemFontOfSize:13];
        cell.detailTextLabel.text = @"";
        cell.imageView.image = nil;
        return cell;
    }
    NSDictionary *item = _catItems[ip.row];
    UIColor *c = item[@"color"];
    
    // 色块
    UIView *dot = [[UIView alloc] initWithFrame:CGRectMake(0,0,10,10)];
    dot.backgroundColor = c;
    dot.layer.cornerRadius = 5;
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(36,36), NO, 0);
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(ctx, c.CGColor);
    CGContextFillEllipseInRect(ctx, CGRectMake(8,8,20,20));
    UIImage *img = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    cell.imageView.image = img;
    
    NSString *cat = item[@"cat"];
    cell.textLabel.text = [NSString stringWithFormat:@"%@ %@ · %ld%%",
        [LedgerRecord iconForCategory:cat],
        [LedgerRecord nameForCategory:cat],
        (long)[item[@"pct"] integerValue]];
    cell.textLabel.font = [UIFont systemFontOfSize:13];
    cell.textLabel.textColor = COLOR_TEXT;
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%@¥%.2f",
        _selectedType==LedgerTypeExpense?@"-":@"+",
        [item[@"amount"] doubleValue]];
    cell.detailTextLabel.textColor = _selectedType==LedgerTypeExpense?COLOR_EXPENSE:COLOR_INCOME;
    cell.detailTextLabel.font = [UIFont systemFontOfSize:13 weight:UIFontWeightMedium];
    return cell;
}

@end
