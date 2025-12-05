//
//  NoaSsoHelpView.m
//  NoaKit
//
//  Created by Mac on 2022/9/2.
//

#import "NoaSsoHelpView.h"
#import "NoaSsoHelpHeaderView.h"
#import "NoaSsoHelpCell.h"

#define HeaderIdentifier  @"NoaSsoHelpHeaderView"
#define CellIdentifier    @"NoaSsoHelpCell"

@interface NoaSsoHelpView() <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong)UIView *bgView;
@property (nonatomic, strong)NSArray *dataArr;
@property (nonatomic, strong)UITableView *tableView;

@end

@implementation NoaSsoHelpView

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self setupData];
        [self setupUI];
    }
    return self;
}

- (void)show {
    self.hidden = NO;
}

- (void)setupData {
    self.dataArr = @[
                    @{@"title" : LanguageToolMatch(@"为什么需要进行网络设置？"),
                      @"content":LanguageToolMatch(@"可以通过客户端随时随地享受数据服务的存储和管理。服务器归属于私有化部署的经营主体，只有经过经营主体许可的人员才能使用，安全性更高、私密性更强，提供非常好的信息安全服务。")},
                    @{@"title" : LanguageToolMatch(@"一、加入服务器"),
                      @"content" :  LanguageToolMatch(@"登录账户时需要加入服务器，以便您能精准找到所属企业或服务主体，支持企业号、域名加入服务器。企业号、域名需要您与平台客服人员进行联系或者由公司内部人员告知。服务器登录后，需填写账号密码完成登录，第二次登录不需要再次进行企业号设置。")},
                    @{@"title" : LanguageToolMatch(@"二、输入规范"),
                      @"content" : LanguageToolMatch(@"企业号方式：100000\n域名方式：xxx.com（系统自动匹配http://或https://）")}
                    ];
}

- (void)setupUI {
    self.frame = CGRectMake(0, 0, DScreenWidth, DScreenHeight);
    self.backgroundColor = [COLOR_00 colorWithAlphaComponent:0.35];
    self.hidden = YES;
    
    self.bgView = [[UIView alloc] init];
    self.bgView.frame = CGRectMake(20, 120, DScreenWidth - 20*2, DScreenHeight - DHomeBarH - 120 - 30);
    self.bgView.tkThemebackgroundColors = @[COLORWHITE, COLOR_11];
    [self.bgView rounded:8];
    [self addSubview:self.bgView];
    
    UILabel *tipTitle = [[UILabel alloc] init];
    tipTitle.text = LanguageToolMatch(@"网络设置说明");
    tipTitle.font = FONTB(16);
    tipTitle.tkThemetextColors = @[COLOR_11, COLOR_11_DARK];
    tipTitle.textAlignment = NSTextAlignmentCenter;
    [self.bgView addSubview:tipTitle];
    [tipTitle mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.bgView).offset(24);
        make.leading.equalTo(self.bgView).offset(35);
        make.trailing.equalTo(self.bgView).offset(-35);
        make.height.mas_equalTo(DWScale(22));
    }];
    
    UIButton *closeBtn = [[UIButton alloc] init];
    [closeBtn setImage:ImgNamed(@"icon_sso_help_close") forState:UIControlStateNormal];
    [closeBtn addTarget:self action:@selector(closeAction) forControlEvents:UIControlEventTouchUpInside];
    [self.bgView addSubview:closeBtn];
    [closeBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.bgView).offset(20);
        make.trailing.equalTo(self.bgView).offset(-20);
        make.width.mas_equalTo(DWScale(12));
        make.width.mas_equalTo(DWScale(12));
    }];
    
    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.bounces = NO;
    self.tableView.separatorColor = COLOR_CLEAR;
    self.tableView.estimatedRowHeight = 60;
    self.tableView.tkThemebackgroundColors = @[COLORWHITE, COLOR_11];
    [self.bgView addSubview:self.tableView];
    [self.tableView registerClass:[NoaSsoHelpHeaderView class] forHeaderFooterViewReuseIdentifier:HeaderIdentifier];
    [self.tableView registerClass:[NoaSsoHelpCell class] forCellReuseIdentifier:CellIdentifier];
    [self.tableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(tipTitle.mas_bottom).offset(20);
        make.bottom.equalTo(self.bgView).offset(-25);
        make.leading.trailing.equalTo(self.bgView);
    }];
    if (@available(iOS 15.0, *)) {
        self.tableView.sectionHeaderTopPadding = 0;
    }
}

#pragma mark -  Action
- (void)closeAction {
    self.hidden = YES;
    [self.bgView removeFromSuperview];
    [self removeFromSuperview];
}

#pragma mark - UITableViewDelegate UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.dataArr.count;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 20;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    if (section == self.dataArr.count - 1) {
        return 0;
    } else {
        return 30;
    }
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    NoaSsoHelpHeaderView *header = [tableView dequeueReusableHeaderFooterViewWithIdentifier:HeaderIdentifier];
    NSDictionary *dic = (NSDictionary *)[self.dataArr objectAtIndex:section];
    header.contentStr = (NSString *)[dic objectForKey:@"title"];
    return header;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NoaSsoHelpCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (!cell) {
        cell = [[NoaSsoHelpCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    NSDictionary *dic = (NSDictionary *)[self.dataArr objectAtIndex:indexPath.section];
    cell.contentStr = (NSString *)[dic objectForKey:@"content"];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
}


@end
