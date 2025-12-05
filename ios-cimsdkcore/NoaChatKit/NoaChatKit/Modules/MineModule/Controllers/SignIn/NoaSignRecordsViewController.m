//
//  NoaSignRecordsViewController.m
//  NoaKit
//
//  Created by Apple on 2023/8/9.
//

#import "NoaSignRecordsViewController.h"
#import "NoaSignRecordsTableViewCell.h"
#import "NoaFDatePickerView.h"
#import <DZNEmptyDataSet/UIScrollView+EmptyDataSet.h>

@interface NoaSignRecordsViewController ()<UITableViewDelegate,UITableViewDataSource,DZNEmptyDataSetSource,DZNEmptyDataSetDelegate>
@property (nonatomic, strong)NSArray *dataArr;
@property (nonatomic,strong) UIButton * downButtonMenu;
@property(nonatomic,strong) UILabel * getTotlePointLabel;
@end

@implementation NoaSignRecordsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.tkThemebackgroundColors = @[COLOR_F5F6F9, COLOR_11];
    self.navTitleStr = LanguageToolMatch(@"签到记录");
    [self setupTableView];
    
    // Do any additional setup after loading the view.
}
- (void)setupTableView {
    
    UIButton * downButtonMenu = [UIButton buttonWithType:UIButtonTypeCustom];
    [downButtonMenu setImage:ImgNamed(@"signDownBtn") forState:UIControlStateNormal];
    [downButtonMenu setTitle:[NSString stringWithFormat:@"%ld-%ld",[NSDate getYearWithCurrentDate],[NSDate getMonthWithCurrentDate]] forState:UIControlStateNormal];
    [downButtonMenu setTkThemeTitleColor:@[COLOR_11, COLOR_99] forState:UIControlStateNormal];
    downButtonMenu.titleLabel.font = FONTR(12);
    [downButtonMenu setBtnImageAlignmentType:ButtonImageAlignmentTypeRight imageSpace:DWScale(6)];
    [downButtonMenu addTarget:self action:@selector(selectDataPicker) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:downButtonMenu];
    self.downButtonMenu = downButtonMenu;
    [downButtonMenu mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view).offset(DNavStatusBarH + DWScale(8));
        make.leading.mas_equalTo(self.view.mas_leading).offset(16);
        make.height.mas_equalTo(DWScale(18));
    }];

    UILabel * getTotlePointLabel = [[UILabel alloc] init];
    getTotlePointLabel.text = [NSString stringWithFormat:LanguageToolMatch(@"累计获得：%@积分"),self.totalLoyalty];//@"累计获得：234积分";
    getTotlePointLabel.textColor = HEXCOLOR(@"999999");
    getTotlePointLabel.font = FONTR(12);
    getTotlePointLabel.textAlignment = NSTextAlignmentRight;
    [self.view addSubview:getTotlePointLabel];
    self.getTotlePointLabel =getTotlePointLabel;
    [getTotlePointLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.trailing.mas_equalTo(self.view.mas_trailing).offset(-16);
        make.centerY.mas_equalTo(downButtonMenu);
        make.height.mas_equalTo(DWScale(18));
    }];
    
    UILabel * signTimeLabel = [[UILabel alloc] init];
    signTimeLabel.text = LanguageToolMatch(@"签到时间");
    signTimeLabel.tkThemetextColors = @[COLOR_66, COLOR_99];
    signTimeLabel.font = FONTR(12);
    [self.view addSubview:signTimeLabel];
    
    [signTimeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.mas_equalTo(self.view.mas_leading).offset(16);
        make.top.mas_equalTo(downButtonMenu.mas_bottom).offset(DWScale(12));
        make.width.mas_equalTo((DScreenWidth - DWScale(30) - 32)/4 + DWScale(30)+DWScale(7));
        make.height.mas_equalTo(DWScale(18));
    }];
        
    UILabel * todaySignPointLabel = [[UILabel alloc] init];
    todaySignPointLabel.text = LanguageToolMatch(@"日签积分");
    todaySignPointLabel.tkThemetextColors = @[COLOR_66, COLOR_99];
    todaySignPointLabel.font = FONTR(12);
    todaySignPointLabel.textAlignment = NSTextAlignmentCenter;
    todaySignPointLabel.numberOfLines = 2;
    [self.view addSubview:todaySignPointLabel];
 
    [todaySignPointLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.mas_equalTo(signTimeLabel.mas_trailing);
        make.centerY.mas_equalTo(signTimeLabel);
        make.width.mas_equalTo((DScreenWidth - DWScale(30) - 32)/4);
    }];
    UILabel * todayRewardsPointLabel = [[UILabel alloc] init];
    todayRewardsPointLabel.text = LanguageToolMatch(@"奖励积分");
    todayRewardsPointLabel.tkThemetextColors = @[COLOR_66, COLOR_99];
    todayRewardsPointLabel.font = FONTR(12);
    todayRewardsPointLabel.textAlignment = NSTextAlignmentCenter;
    todayRewardsPointLabel.numberOfLines = 2;
    [self.view addSubview:todayRewardsPointLabel];
 
    [todayRewardsPointLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.mas_equalTo(todaySignPointLabel.mas_trailing);
        make.centerY.mas_equalTo(todaySignPointLabel);
        make.width.mas_equalTo((DScreenWidth - DWScale(30) - 32)/4);
    }];
    
    UILabel * todayTotlePointLabel = [[UILabel alloc] init];
    todayTotlePointLabel.text = LanguageToolMatch(@"日总积分");
    todayTotlePointLabel.tkThemetextColors = @[COLOR_66, COLOR_99];
    todayTotlePointLabel.font = FONTR(12);
    todayTotlePointLabel.numberOfLines = 2;
    todayTotlePointLabel.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:todayTotlePointLabel];
 
    [todayTotlePointLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.mas_equalTo(todayRewardsPointLabel.mas_trailing);
        make.centerY.mas_equalTo(todayRewardsPointLabel);
        make.width.mas_equalTo((DScreenWidth - DWScale(30) - 32)/4);
    }];
    
    self.baseTableView.delegate = self;
    self.baseTableView.dataSource = self;
    self.baseTableView.bounces = YES;
    self.baseTableView.separatorColor = COLOR_CLEAR;
    self.baseTableView.delaysContentTouches = NO;
    self.baseTableView.emptyDataSetSource = self;
    self.baseTableView.emptyDataSetDelegate = self;
    self.baseTableView.tkThemebackgroundColors = @[COLORWHITE, COLOR_11];
    [self.view addSubview:self.baseTableView];
    [self.baseTableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(signTimeLabel.mas_bottom).offset(8);
        make.leading.trailing.equalTo(self.view);
        make.bottom.equalTo(self.view).offset(-DHomeBarH);
    }];
    [self.baseTableView registerClass:[NoaSignRecordsTableViewCell class] forCellReuseIdentifier:NSStringFromClass([NoaSignRecordsTableViewCell class])];
}
-(void)selectDataPicker{
    WeakSelf;
    NoaFDatePickerView *datePickerView = [[NoaFDatePickerView alloc]initDatePackerWithSUperView:self.view response:^(NSString *str,NSString* selectYear,NSString* selectMonth) {
        NSString *string = str;
        [weakSelf.downButtonMenu setTitle:string forState:UIControlStateNormal];
        [weakSelf.downButtonMenu setBtnImageAlignmentType:ButtonImageAlignmentTypeRight imageSpace:DWScale(6)];
        [weakSelf requestSignWithRecord:selectYear selectMonth:selectMonth];
    }];
    [datePickerView show];
}
// 签到记录
- (void)requestSignWithRecord:(NSString*)year selectMonth:(NSString*)month
{
    WeakSelf;
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    [dict setValue:UserManager.userInfo.userUID forKey:@"userUid"];
    [dict setValue:year forKey:@"year"];
    [dict setValue:month forKey:@"month"];
    [IMSDKManager imSignInWithRecord:dict onSuccess:^(id _Nullable data, NSString * _Nullable traceId) {
        DLog(@"签到记录======%@",data);
        if ([data isKindOfClass:[NSDictionary class]]) {
            NSDictionary *signRecordDict = (NSDictionary *)data;
            NSArray * signInRecords = [signRecordDict objectForKey:@"signInRecords"];
            weakSelf.signInRecords = signInRecords;
            weakSelf.totalLoyalty = [signRecordDict objectForKey:@"totalLoyalty"];
            weakSelf.getTotlePointLabel.text = [NSString stringWithFormat:LanguageToolMatch(@"累计获得：%@积分"),weakSelf.totalLoyalty];
            [weakSelf.baseTableView reloadData];
        }
    } onFailure:^(NSInteger code, NSString * _Nullable msg, NSString * _Nullable traceId) {
      
    }];
}
#pragma mark - UITableViewDelegate  UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.signInRecords.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return DWScale(50);
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return CGFLOAT_MIN;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return CGFLOAT_MIN;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary * dict = [self.signInRecords objectAtIndex:indexPath.row];
    NoaSignRecordsTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:NSStringFromClass([NoaSignRecordsTableViewCell class]) forIndexPath:indexPath];
    cell.baseCellIndexPath = indexPath;
    [cell setSignRecordsWithDic:dict];
    return cell;
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}
#pragma mark - DZNEmptyDataSetSource
//图片距离中心偏移量
- (CGFloat)verticalOffsetForEmptyDataSet:(UIScrollView *)scrollView {
    return DWScale(-120);
}
//空态图片
- (UIImage *)imageForEmptyDataSet:(UIScrollView *)scrollView {
    return ImgNamed(@"c_no_history_chat");
}

#pragma mark - DZNEmptyDataSetDelegate
//允许滑动
- (BOOL)emptyDataSetShouldAllowScroll:(UIScrollView *)scrollView {
    return YES;
}
/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
