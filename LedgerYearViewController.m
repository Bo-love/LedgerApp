// LedgerYearViewController.m
// 年报表：12个月卡片 + 年度收支汇总，点击月份跳转月汇总

#import "LedgerYearViewController.h"
#import "LedgerStore.h"
#import "LedgerMonthViewController.h"

#define COLOR_BG         [UIColor colorWithRed:.98 green:.97 blue:.94 alpha:1]
#define COLOR_CARD       [UIColor whiteColor]
#define COLOR_INCOME     [UIColor colorWithRed:.06 green:.43 blue:.34 alpha:1]
#define COLOR_INCOME_BG  [UIColor colorWithRed:.88 green:.96 blue:.93 alpha:1]
#define COLOR_EXPENSE    [UIColor colorWithRed:.60 green:.24 blue:.11 alpha:1]
#define COLOR_TEXT       [UIColor colorWithRed:.17 green:.17 blue:.16 alpha:1]
#define COLOR_TEXT2      [UIColor colorWithRed:.37 green:.37 blue:.35 alpha:1]
#define COLOR_TEXT3      [UIColor colorWithRed:.53 green:.53 blue:.50 alpha:1]

// ── Month Card Cell ──────────────────────────────────────
@interface LYearMonthCell : UICollectionViewCell
- (void)configureWithMonth:(NSInteger)month income:(double)inc expense:(double)exp maxExpense:(double)maxExp;
@end
@implementation LYearMonthCell {
    UILabel *_monthLabel, *_incLabel, *_expLabel;
    UIView  *_barBG, *_barFill;
}
- (instancetype)initWithFrame:(CGRect)f {
    self = [super initWithFrame:f];
    self.contentView.backgroundColor = COLOR_CARD;
    self.contentView.layer.cornerRadius = 12;
    self.contentView.layer.borderWidth  = 0.5;
    self.contentView.layer.borderColor  = [UIColor colorWithRed:0 green:0 blue:0 alpha:.08].CGColor;
    
    _monthLabel = [[UILabel alloc] initWithFrame:CGRectMake(10,8,60,18)];
    _monthLabel.font = [UIFont systemFontOfSize:13 weight:UIFontWeightMedium];
    _monthLabel.textColor = COLOR_TEXT;
    [self.contentView addSubview:_monthLabel];
    
    _incLabel = [[UILabel alloc] initWithFrame:CGRectMake(10,28,self.bounds.size.width-20,14)];
    _incLabel.font = [UIFont systemFontOfSize:11];
    _incLabel.textColor = COLOR_INCOME;
    _incLabel.adjustsFontSizeToFitWidth = YES;
    [self.contentView addSubview:_incLabel];
    
    _expLabel = [[UILabel alloc] initWithFrame:CGRectMake(10,44,self.bounds.size.width-20,14)];
    _expLabel.font = [UIFont systemFontOfSize:11];
    _expLabel.textColor = COLOR_EXPENSE;
    _expLabel.adjustsFontSizeToFitWidth = YES;
    [self.contentView addSubview:_expLabel];
    
    _barBG = [[UIView alloc] initWithFrame:CGRectMake(10,62,self.bounds.size.width-20,4)];
    _barBG.backgroundColor = [UIColor colorWithRed:.93 green:.92 blue:.88 alpha:1];
    _barBG.layer.cornerRadius = 2;
    _barBG.clipsToBounds = YES;
    [self.contentView addSubview:_barBG];
    
    _barFill = [[UIView alloc] initWithFrame:CGRectMake(0,0,0,4)];
    _barFill.backgroundColor = COLOR_INCOME;
    _barFill.layer.cornerRadius = 2;
    [_barBG addSubview:_barFill];
    
    return self;
}
- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat W = self.contentView.bounds.size.width;
    _incLabel.frame  = CGRectMake(10,28,W-20,14);
    _expLabel.frame  = CGRectMake(10,44,W-20,14);
    _barBG.frame     = CGRectMake(10,62,W-20,4);
}
- (void)configureWithMonth:(NSInteger)month income:(double)inc expense:(double)exp maxExpense:(double)maxExp {
    _monthLabel.text = [NSString stringWithFormat:@"%ld月", (long)month];
    _incLabel.text   = inc>0  ? [NSString stringWithFormat:@"收 ¥%.0f", inc]  : @"";
    _expLabel.text   = exp>0  ? [NSString stringWithFormat:@"支 ¥%.0f", exp]  : @"";
    if (!inc && !exp) { _incLabel.text = @"无记录"; }
    CGFloat pct = maxExp > 0 ? exp/maxExp : 0;
    _barFill.frame = CGRectMake(0,0,_barBG.bounds.size.width*pct,4);
}
@end

// ── Main VC ─────────────────────────────────────────────
@interface LedgerYearViewController () <UICollectionViewDataSource, UICollectionViewDelegate>
@property (nonatomic, strong) UILabel *periodLabel;
@property (nonatomic, strong) UILabel *incomeLabel, *expenseLabel, *balanceLabel;
@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, assign) NSInteger year;
@property (nonatomic, strong) NSArray *monthData; // 12 items: {inc, exp}
@end

@implementation LedgerYearViewController

- (instancetype)init {
    self = [super init];
    if (self) {
        _year = [[NSCalendar currentCalendar] components:NSCalendarUnitYear fromDate:[NSDate date]].year;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"年报表";
    self.view.backgroundColor = COLOR_BG;
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
    topBar.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:topBar];
    
    UIButton *prev = [UIButton buttonWithType:UIButtonTypeSystem];
    prev.frame=CGRectMake(W/2-90,8,40,34);
    [prev setTitle:@"‹" forState:UIControlStateNormal];
    prev.titleLabel.font=[UIFont systemFontOfSize:28];
    prev.tintColor=COLOR_TEXT2;
    [prev addTarget:self action:@selector(prevYear) forControlEvents:UIControlEventTouchUpInside];
    [topBar addSubview:prev];
    
    _periodLabel=[[UILabel alloc] initWithFrame:CGRectMake(W/2-50,12,100,26)];
    _periodLabel.textAlignment=NSTextAlignmentCenter;
    _periodLabel.font=[UIFont systemFontOfSize:15 weight:UIFontWeightMedium];
    _periodLabel.textColor=COLOR_TEXT;
    [topBar addSubview:_periodLabel];
    
    UIButton *next = [UIButton buttonWithType:UIButtonTypeSystem];
    next.frame=CGRectMake(W/2+50,8,40,34);
    [next setTitle:@"›" forState:UIControlStateNormal];
    next.titleLabel.font=[UIFont systemFontOfSize:28];
    next.tintColor=COLOR_TEXT2;
    [next addTarget:self action:@selector(nextYear) forControlEvents:UIControlEventTouchUpInside];
    [topBar addSubview:next];
    
    CGFloat cW=(W-48)/3.0;
    NSInteger tags[]={300,301,302};
    NSArray *labels=@[@"全年收入",@"全年支出",@"全年结余"];
    for(NSInteger i=0;i<3;i++){
        UIView *card=[[UIView alloc] initWithFrame:CGRectMake(16+i*(cW+8),50,cW,42)];
        card.backgroundColor=[UIColor colorWithRed:.96 green:.95 blue:.92 alpha:1];
        card.layer.cornerRadius=8;
        [topBar addSubview:card];
        UILabel *tl=[[UILabel alloc] initWithFrame:CGRectMake(4,2,cW-8,13)];
        tl.text=labels[i]; tl.font=[UIFont systemFontOfSize:10]; tl.textColor=COLOR_TEXT3;
        tl.adjustsFontSizeToFitWidth=YES;
        [card addSubview:tl];
        UILabel *vl=[[UILabel alloc] initWithFrame:CGRectMake(4,16,cW-8,20)];
        vl.font=[UIFont systemFontOfSize:13 weight:UIFontWeightMedium];
        vl.tag=tags[i]; vl.adjustsFontSizeToFitWidth=YES;
        if(i==0){vl.textColor=COLOR_INCOME;_incomeLabel=vl;}
        else if(i==1){vl.textColor=COLOR_EXPENSE;_expenseLabel=vl;}
        else{_balanceLabel=vl;}
        [card addSubview:vl];
    }
    
    UICollectionViewFlowLayout *layout=[[UICollectionViewFlowLayout alloc] init];
    CGFloat itemW=(W-48)/3.0;
    layout.itemSize=CGSizeMake(itemW,80);
    layout.minimumInteritemSpacing=8;
    layout.minimumLineSpacing=10;
    layout.sectionInset=UIEdgeInsetsMake(16,16,16,16);
    
    _collectionView=[[UICollectionView alloc] initWithFrame:CGRectMake(0,100,W,self.view.bounds.size.height-100)
                                          collectionViewLayout:layout];
    _collectionView.autoresizingMask=UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    _collectionView.backgroundColor=COLOR_BG;
    _collectionView.dataSource=self;
    _collectionView.delegate=self;
    [_collectionView registerClass:[LYearMonthCell class] forCellWithReuseIdentifier:@"YCell"];
    [self.view addSubview:_collectionView];
}

- (void)reloadData {
    _periodLabel.text=[NSString stringWithFormat:@"%ld年",(long)_year];
    NSArray *allYear=[[LedgerStore shared] recordsForYear:_year];
    
    double totalInc=0, totalExp=0, maxExp=0;
    NSMutableArray *data=[NSMutableArray array];
    for(NSInteger m=1;m<=12;m++){
        NSString *ym=[NSString stringWithFormat:@"%04ld-%02ld",(long)_year,(long)m];
        NSArray *ml=[[LedgerStore shared] recordsForMonth:ym];
        double inc=[[LedgerStore shared] incomeForRecords:ml];
        double exp=[[LedgerStore shared] expenseForRecords:ml];
        totalInc+=inc; totalExp+=exp;
        if(exp>maxExp) maxExp=exp;
        [data addObject:@{@"inc":@(inc),@"exp":@(exp),@"month":@(m)}];
    }
    _monthData=data;
    
    double bal=totalInc-totalExp;
    _incomeLabel.text=[NSString stringWithFormat:@"¥%.2f",totalInc];
    _expenseLabel.text=[NSString stringWithFormat:@"¥%.2f",totalExp];
    _balanceLabel.text=[NSString stringWithFormat:@"¥%.2f",bal];
    _balanceLabel.textColor=bal>=0?COLOR_INCOME:COLOR_EXPENSE;
    
    // 存 maxExp 供 cell 使用
    objc_setAssociatedObject(self, "maxExp", @(maxExp), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    [_collectionView reloadData];
}

- (void)prevYear { _year--; [self reloadData]; }
- (void)nextYear { _year++; [self reloadData]; }

- (NSInteger)collectionView:(UICollectionView *)cv numberOfItemsInSection:(NSInteger)s { return 12; }
- (UICollectionViewCell *)collectionView:(UICollectionView *)cv cellForItemAtIndexPath:(NSIndexPath *)ip {
    LYearMonthCell *cell=[cv dequeueReusableCellWithReuseIdentifier:@"YCell" forIndexPath:ip];
    NSDictionary *d=_monthData[ip.item];
    double maxExp=[objc_getAssociatedObject(self,"maxExp") doubleValue];
    [cell configureWithMonth:[d[@"month"] integerValue]
                      income:[d[@"inc"] doubleValue]
                     expense:[d[@"exp"] doubleValue]
                  maxExpense:maxExp];
    return cell;
}
- (void)collectionView:(UICollectionView *)cv didSelectItemAtIndexPath:(NSIndexPath *)ip {
    NSInteger m=[_monthData[ip.item][@"month"] integerValue];
    // 跳转到 Month tab
    UITabBarController *tab=self.tabBarController;
    UINavigationController *monthNav=(UINavigationController *)tab.viewControllers[1];
    LedgerMonthViewController *monthVC=(LedgerMonthViewController *)monthNav.viewControllers[0];
    [monthVC jumpToYear:_year month:m];
    tab.selectedIndex=1;
}

#import <objc/runtime.h>
@end
