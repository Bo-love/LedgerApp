// LedgerAddViewController.m
// 添加 / 编辑记录 - 全代码 UIKit，无 XIB / Storyboard

#import "LedgerAddViewController.h"

// ── 颜色常量 ──────────────────────────────────────────
#define COLOR_BG          [UIColor colorWithRed:.98 green:.97 blue:.94 alpha:1]
#define COLOR_CARD        [UIColor whiteColor]
#define COLOR_INCOME      [UIColor colorWithRed:.06 green:.43 blue:.34 alpha:1]
#define COLOR_INCOME_BG   [UIColor colorWithRed:.88 green:.96 blue:.93 alpha:1]
#define COLOR_EXPENSE     [UIColor colorWithRed:.60 green:.24 blue:.11 alpha:1]
#define COLOR_EXPENSE_BG  [UIColor colorWithRed:.98 green:.93 blue:.91 alpha:1]
#define COLOR_TEXT        [UIColor colorWithRed:.17 green:.17 blue:.16 alpha:1]
#define COLOR_TEXT2       [UIColor colorWithRed:.37 green:.37 blue:.35 alpha:1]
#define COLOR_TEXT3       [UIColor colorWithRed:.53 green:.53 blue:.50 alpha:1]
#define COLOR_BORDER      [UIColor colorWithRed:0 green:0 blue:0 alpha:.10]

@interface LedgerAddViewController () <UITextFieldDelegate, UITextViewDelegate>

@property (nonatomic, strong) LedgerRecord *editRecord;
@property (nonatomic, copy)   NSString     *defaultDate;

// UI
@property (nonatomic, strong) UIScrollView   *scrollView;
@property (nonatomic, strong) UISegmentedControl *typeSegment;  // 支出 / 收入
@property (nonatomic, strong) UITextField    *amountField;
@property (nonatomic, strong) UILabel        *amountPrefixLabel;
@property (nonatomic, strong) UICollectionView *catCollectionView;
@property (nonatomic, strong) UITextField    *dateField;
@property (nonatomic, strong) UIDatePicker   *datePicker;
@property (nonatomic, strong) UITextView     *noteField;
@property (nonatomic, strong) UIButton       *saveButton;

@property (nonatomic, strong) NSArray<NSString *> *currentCategoryKeys;
@property (nonatomic, copy)   NSString *selectedCat;
@property (nonatomic, assign) LedgerType selectedType;

@end

// ── Category Cell ───────────────────────────────────────
@interface LedgerCatCell : UICollectionViewCell
@property (nonatomic, strong) UILabel *iconLabel;
@property (nonatomic, strong) UILabel *nameLabel;
@end
@implementation LedgerCatCell
- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    _iconLabel = [[UILabel alloc] init];
    _iconLabel.font = [UIFont systemFontOfSize:22];
    _iconLabel.textAlignment = NSTextAlignmentCenter;
    _nameLabel = [[UILabel alloc] init];
    _nameLabel.font = [UIFont systemFontOfSize:10];
    _nameLabel.textAlignment = NSTextAlignmentCenter;
    _nameLabel.textColor = [UIColor colorWithRed:.37 green:.37 blue:.35 alpha:1];
    _nameLabel.adjustsFontSizeToFitWidth = YES;
    self.contentView.layer.cornerRadius = 8;
    self.contentView.layer.borderWidth  = 0.5;
    self.contentView.layer.borderColor  = [UIColor colorWithRed:0 green:0 blue:0 alpha:.10].CGColor;
    self.contentView.backgroundColor    = UIColor.whiteColor;
    [self.contentView addSubview:_iconLabel];
    [self.contentView addSubview:_nameLabel];
    return self;
}
- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat w = self.contentView.bounds.size.width;
    CGFloat h = self.contentView.bounds.size.height;
    _iconLabel.frame = CGRectMake(0, 4, w, h*0.55);
    _nameLabel.frame = CGRectMake(2, h*0.60, w-4, h*0.35);
}
- (void)setSelected:(BOOL)selected {
    [super setSelected:selected];
    self.contentView.backgroundColor = selected ?
        [UIColor colorWithRed:.88 green:.96 blue:.93 alpha:1] : UIColor.whiteColor;
    self.contentView.layer.borderColor = selected ?
        [UIColor colorWithRed:.06 green:.43 blue:.34 alpha:1].CGColor :
        [UIColor colorWithRed:0 green:0 blue:0 alpha:.10].CGColor;
}
@end

// ── Main VC ─────────────────────────────────────────────
@implementation LedgerAddViewController

- (instancetype)initWithRecord:(LedgerRecord *)record defaultDate:(NSString *)dateString {
    self = [super init];
    if (self) {
        _editRecord  = record;
        _defaultDate = dateString ?: [self todayString];
        _selectedType = record ? record.type : LedgerTypeExpense;
        _selectedCat  = record ? record.category : @"food";
    }
    return self;
}

- (NSString *)todayString {
    NSDateFormatter *f = [[NSDateFormatter alloc] init];
    f.dateFormat = @"yyyy-MM-dd";
    return [f stringFromDate:[NSDate date]];
}

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = _editRecord ? @"编辑记录" : @"添加记录";
    self.view.backgroundColor = COLOR_BG;
    
    // 导航按钮
    self.navigationItem.leftBarButtonItem  = [[UIBarButtonItem alloc]
        initWithTitle:@"取消" style:UIBarButtonItemStylePlain target:self action:@selector(cancel)];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]
        initWithTitle:@"保存" style:UIBarButtonItemStyleDone  target:self action:@selector(save)];
    self.navigationItem.rightBarButtonItem.tintColor = COLOR_INCOME;
    
    [self buildUI];
    [self refreshForType:_selectedType];
    [self fillFromRecord];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification object:nil];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Build UI

- (void)buildUI {
    // ScrollView
    _scrollView = [[UIScrollView alloc] initWithFrame:self.view.bounds];
    _scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _scrollView.alwaysBounceVertical = YES;
    [self.view addSubview:_scrollView];
    
    CGFloat W = self.view.bounds.size.width;
    CGFloat pad = 16;
    CGFloat y = 20;
    
    // ── 类型切换 ──
    _typeSegment = [[UISegmentedControl alloc] initWithItems:@[@"支出", @"收入"]];
    _typeSegment.frame = CGRectMake(pad, y, W - pad*2, 36);
    _typeSegment.selectedSegmentIndex = _selectedType;
    _typeSegment.tintColor = COLOR_INCOME;
    if (@available(iOS 13.0, *)) {
        [_typeSegment setTitleTextAttributes:@{NSForegroundColorAttributeName: COLOR_EXPENSE} forState:UIControlStateNormal];
        [_typeSegment setTitleTextAttributes:@{NSForegroundColorAttributeName: UIColor.whiteColor} forState:UIControlStateSelected];
        _typeSegment.selectedSegmentTintColor = COLOR_INCOME;
    }
    [_typeSegment addTarget:self action:@selector(typeChanged:) forControlEvents:UIControlEventValueChanged];
    [_scrollView addSubview:_typeSegment];
    y += 44;
    
    // ── 金额卡片 ──
    UIView *amtCard = [self cardViewWithFrame:CGRectMake(pad, y, W-pad*2, 70)];
    [_scrollView addSubview:amtCard];
    
    UILabel *amtLabel = [self sectionLabel:@"金额（元）" frame:CGRectMake(12, 8, 200, 18)];
    [amtCard addSubview:amtLabel];
    
    _amountPrefixLabel = [[UILabel alloc] initWithFrame:CGRectMake(12, 32, 20, 28)];
    _amountPrefixLabel.text = @"¥";
    _amountPrefixLabel.font = [UIFont systemFontOfSize:20 weight:UIFontWeightMedium];
    _amountPrefixLabel.textColor = COLOR_EXPENSE;
    [amtCard addSubview:_amountPrefixLabel];
    
    _amountField = [[UITextField alloc] initWithFrame:CGRectMake(34, 30, amtCard.bounds.size.width-46, 32)];
    _amountField.placeholder = @"0.00";
    _amountField.keyboardType = UIKeyboardTypeDecimalPad;
    _amountField.font = [UIFont systemFontOfSize:22 weight:UIFontWeightMedium];
    _amountField.textColor = COLOR_TEXT;
    _amountField.delegate = self;
    [amtCard addSubview:_amountField];
    y += 78;
    
    // ── 分类 ──
    UILabel *catTitleLabel = [self sectionLabel:@"分类" frame:CGRectMake(pad, y, 100, 18)];
    [_scrollView addSubview:catTitleLabel];
    y += 24;
    
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    CGFloat itemSize = (W - pad*2 - 8*4) / 5.0;
    layout.itemSize = CGSizeMake(itemSize, itemSize * 1.1);
    layout.minimumInteritemSpacing = 8;
    layout.minimumLineSpacing = 8;
    
    _catCollectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(pad, y, W-pad*2, 0)
                                            collectionViewLayout:layout];
    _catCollectionView.backgroundColor = UIColor.clearColor;
    _catCollectionView.scrollEnabled = NO;
    _catCollectionView.dataSource = self;
    _catCollectionView.delegate = self;
    _catCollectionView.allowsSelection = YES;
    [_catCollectionView registerClass:[LedgerCatCell class] forCellWithReuseIdentifier:@"CatCell"];
    [_scrollView addSubview:_catCollectionView];
    // 高度稍后在 refreshForType 里更新
    y += 0; // placeholder
    
    // ── 日期 ──
    _datePicker = [[UIDatePicker alloc] init];
    _datePicker.datePickerMode = UIDatePickerModeDate;
    if (@available(iOS 13.4, *)) { _datePicker.preferredDatePickerStyle = UIDatePickerStyleWheels; }
    _datePicker.locale = [NSLocale localeWithLocaleIdentifier:@"zh_CN"];
    
    _dateField = [[UITextField alloc] init];
    _dateField.inputView = _datePicker;
    _dateField.font = [UIFont systemFontOfSize:15];
    _dateField.textColor = COLOR_TEXT;
    _dateField.tintColor = UIColor.clearColor;
    [_datePicker addTarget:self action:@selector(datePickerChanged:) forControlEvents:UIControlEventValueChanged];
    
    // done toolbar for date picker
    UIToolbar *toolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0,0,W,44)];
    UIBarButtonItem *flex = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    UIBarButtonItem *done = [[UIBarButtonItem alloc] initWithTitle:@"完成" style:UIBarButtonItemStyleDone
                                                            target:self action:@selector(dismissDatePicker)];
    done.tintColor = COLOR_INCOME;
    toolbar.items = @[flex, done];
    _dateField.inputAccessoryView = toolbar;
    
    // Date card placeholder – we add it below after calculating cat height
    
    // ── 备注 ──
    _noteField = [[UITextView alloc] init];
    _noteField.font = [UIFont systemFontOfSize:14];
    _noteField.textColor = COLOR_TEXT;
    _noteField.backgroundColor = UIColor.clearColor;
    _noteField.delegate = self;
    
    // Store y offset for cat section end, will lay out in refreshForType
    // Save a tag to locate the card views later
    catTitleLabel.tag = 100;
    _catCollectionView.tag = 101;
    
    // Build remaining UI (date + note + save) is done in refreshForType after catView height known
    [self buildLowerUI:W pad:pad];
}

- (void)buildLowerUI:(CGFloat)W pad:(CGFloat)pad {
    // ── 日期卡片 ──
    UIView *dateCard = [self cardViewWithFrame:CGRectMake(pad, 0, W-pad*2, 60)];
    dateCard.tag = 200;
    [_scrollView addSubview:dateCard];
    
    UILabel *dateLbl = [self sectionLabel:@"日期" frame:CGRectMake(12, 8, 80, 18)];
    [dateCard addSubview:dateLbl];
    _dateField.frame = CGRectMake(12, 30, W-pad*2-24, 22);
    [dateCard addSubview:_dateField];
    
    // ── 备注卡片 ──
    UIView *noteCard = [self cardViewWithFrame:CGRectMake(pad, 0, W-pad*2, 90)];
    noteCard.tag = 201;
    [_scrollView addSubview:noteCard];
    
    UILabel *noteLbl = [self sectionLabel:@"备注" frame:CGRectMake(12, 8, 80, 18)];
    [noteCard addSubview:noteLbl];
    _noteField.frame = CGRectMake(8, 30, W-pad*2-16, 52);
    [noteCard addSubview:_noteField];
    
    // ── 保存按钮 ──
    _saveButton = [UIButton buttonWithType:UIButtonTypeSystem];
    _saveButton.tag = 202;
    _saveButton.backgroundColor = COLOR_INCOME;
    _saveButton.layer.cornerRadius = 12;
    [_saveButton setTitle:@"保存记录" forState:UIControlStateNormal];
    [_saveButton setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    _saveButton.titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightMedium];
    [_saveButton addTarget:self action:@selector(save) forControlEvents:UIControlEventTouchUpInside];
    _saveButton.frame = CGRectMake(pad, 0, W-pad*2, 50);
    [_scrollView addSubview:_saveButton];
    
    [self relayout];
}

- (void)relayout {
    CGFloat W = self.view.bounds.size.width;
    CGFloat pad = 16;
    
    // Re-find catCollectionView
    CGFloat catY = CGRectGetMaxY([_scrollView viewWithTag:100].frame) + 8;
    NSInteger catCount = _currentCategoryKeys.count;
    CGFloat itemSize = (W - pad*2 - 8*4) / 5.0;
    NSInteger rows = (catCount + 4) / 5;
    CGFloat catH = rows * (itemSize * 1.1) + (rows - 1) * 8;
    _catCollectionView.frame = CGRectMake(pad, catY, W-pad*2, catH);
    
    CGFloat y = CGRectGetMaxY(_catCollectionView.frame) + 14;
    
    UIView *dateCard = [_scrollView viewWithTag:200];
    dateCard.frame = CGRectMake(pad, y, W-pad*2, 60);
    y += 68;
    
    UIView *noteCard = [_scrollView viewWithTag:201];
    noteCard.frame = CGRectMake(pad, y, W-pad*2, 90);
    y += 98;
    
    UIView *saveBtn = [_scrollView viewWithTag:202];
    saveBtn.frame = CGRectMake(pad, y, W-pad*2, 50);
    y += 66;
    
    _scrollView.contentSize = CGSizeMake(W, y);
}

#pragma mark - Type Change

- (void)refreshForType:(LedgerType)type {
    _selectedType = type;
    _typeSegment.selectedSegmentIndex = type;
    
    NSArray *keys = (type == LedgerTypeExpense)
        ? [LedgerRecord expenseCategoryKeys]
        : [LedgerRecord incomeCategoryKeys];
    _currentCategoryKeys = keys;
    
    if (![keys containsObject:_selectedCat]) {
        _selectedCat = keys.firstObject;
    }
    
    UIColor *typeColor = (type == LedgerTypeExpense) ? COLOR_EXPENSE : COLOR_INCOME;
    _amountPrefixLabel.textColor = typeColor;
    if (@available(iOS 13.0, *)) {
        _typeSegment.selectedSegmentTintColor = typeColor;
    }
    
    [_catCollectionView reloadData];
    
    // 选中正确 cell
    dispatch_async(dispatch_get_main_queue(), ^{
        NSInteger idx = [self->_currentCategoryKeys indexOfObject:self->_selectedCat];
        if (idx != NSNotFound) {
            NSIndexPath *ip = [NSIndexPath indexPathForItem:idx inSection:0];
            [self->_catCollectionView selectItemAtIndexPath:ip animated:NO scrollPosition:UICollectionViewScrollPositionNone];
        }
        [self relayout];
    });
}

- (void)typeChanged:(UISegmentedControl *)seg {
    [self refreshForType:seg.selectedSegmentIndex];
}

#pragma mark - Fill Existing Record

- (void)fillFromRecord {
    if (_editRecord) {
        _amountField.text = [NSString stringWithFormat:@"%.2f", _editRecord.amount];
        [self setDateFieldText:_editRecord.dateString];
        _noteField.text = _editRecord.note;
    } else {
        [self setDateFieldText:_defaultDate];
    }
}

- (void)setDateFieldText:(NSString *)dateStr {
    _dateField.text = dateStr;
    NSDateFormatter *f = [[NSDateFormatter alloc] init];
    f.dateFormat = @"yyyy-MM-dd";
    NSDate *d = [f dateFromString:dateStr];
    if (d) [_datePicker setDate:d animated:NO];
}

#pragma mark - Date Picker

- (void)datePickerChanged:(UIDatePicker *)picker {
    NSDateFormatter *f = [[NSDateFormatter alloc] init];
    f.dateFormat = @"yyyy-MM-dd";
    _dateField.text = [f stringFromDate:picker.date];
}

- (void)dismissDatePicker {
    [_dateField resignFirstResponder];
}

#pragma mark - Actions

- (void)cancel {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)save {
    NSString *amtStr = [_amountField.text stringByTrimmingCharactersInSet:
                        [NSCharacterSet whitespaceAndNewlineCharacterSet]];
    double amt = [amtStr doubleValue];
    if (amt <= 0) {
        [self showAlert:@"提示" message:@"请输入有效金额（大于0）"];
        return;
    }
    NSString *dateStr = [_dateField.text stringByTrimmingCharactersInSet:
                         [NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (!dateStr.length) {
        [self showAlert:@"提示" message:@"请选择日期"];
        return;
    }
    NSString *note = [_noteField.text stringByTrimmingCharactersInSet:
                      [NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    LedgerRecord *record;
    BOOL isNew = NO;
    if (_editRecord) {
        record = _editRecord;
        record.amount     = amt;
        record.type       = _selectedType;
        record.category   = _selectedCat;
        record.dateString = dateStr;
        record.note       = note;
    } else {
        record = [LedgerRecord recordWithType:_selectedType
                                       amount:amt
                                     category:_selectedCat
                                   dateString:dateStr
                                         note:note];
        isNew = YES;
    }
    [_delegate ledgerAddVC:self didSaveRecord:record isNew:isNew];
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - UICollectionView DataSource / Delegate

- (NSInteger)collectionView:(UICollectionView *)cv numberOfItemsInSection:(NSInteger)section {
    return _currentCategoryKeys.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)cv cellForItemAtIndexPath:(NSIndexPath *)ip {
    LedgerCatCell *cell = [cv dequeueReusableCellWithReuseIdentifier:@"CatCell" forIndexPath:ip];
    NSString *key = _currentCategoryKeys[ip.item];
    cell.iconLabel.text = [LedgerRecord iconForCategory:key];
    cell.nameLabel.text = [LedgerRecord nameForCategory:key];
    return cell;
}

- (void)collectionView:(UICollectionView *)cv didSelectItemAtIndexPath:(NSIndexPath *)ip {
    _selectedCat = _currentCategoryKeys[ip.item];
}

#pragma mark - UITextFieldDelegate

- (BOOL)textField:(UITextField *)tf shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    if (tf == _amountField) {
        NSString *newStr = [tf.text stringByReplacingCharactersInRange:range withString:string];
        // 只允许数字和一个小数点
        NSCharacterSet *allowed = [NSCharacterSet characterSetWithCharactersInString:@"0123456789."];
        if ([string rangeOfCharacterFromSet:allowed.invertedSet].location != NSNotFound) return NO;
        NSArray *parts = [newStr componentsSeparatedByString:@"."];
        if (parts.count > 2) return NO;
        if (parts.count == 2 && [parts[1] length] > 2) return NO;
        return YES;
    }
    return YES;
}

#pragma mark - Keyboard

- (void)keyboardWillShow:(NSNotification *)n {
    NSDictionary *info = n.userInfo;
    CGRect kb = [info[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    _scrollView.contentInset = UIEdgeInsetsMake(0, 0, kb.size.height, 0);
}

- (void)keyboardWillHide:(NSNotification *)n {
    _scrollView.contentInset = UIEdgeInsetsZero;
}

#pragma mark - Helpers

- (UIView *)cardViewWithFrame:(CGRect)frame {
    UIView *v = [[UIView alloc] initWithFrame:frame];
    v.backgroundColor = COLOR_CARD;
    v.layer.cornerRadius = 12;
    v.layer.borderWidth  = 0.5;
    v.layer.borderColor  = [UIColor colorWithRed:0 green:0 blue:0 alpha:.08].CGColor;
    return v;
}

- (UILabel *)sectionLabel:(NSString *)text frame:(CGRect)frame {
    UILabel *l = [[UILabel alloc] initWithFrame:frame];
    l.text = text;
    l.font = [UIFont systemFontOfSize:12];
    l.textColor = COLOR_TEXT3;
    return l;
}

- (void)showAlert:(NSString *)title message:(NSString *)msg {
    UIAlertController *a = [UIAlertController alertControllerWithTitle:title message:msg
                                                        preferredStyle:UIAlertControllerStyleAlert];
    [a addAction:[UIAlertAction actionWithTitle:@"好" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:a animated:YES completion:nil];
}

@end
