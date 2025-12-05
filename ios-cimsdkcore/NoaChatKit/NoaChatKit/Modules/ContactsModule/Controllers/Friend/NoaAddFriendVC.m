//
//  NoaAddFriendVC.m
//  NoaKit
//
//  Created by mac on 2022/9/9.
//

#import "NoaAddFriendVC.h"
#import "NoaSearchView.h"
#import "NoaNoDataView.h"
#import "NoaAddFriendCell.h"
#import "NoaUserHomePageVC.h"
#import "NoaMyQRCodeViewController.h"
#import "NoaQRCodeModel.h"
@interface NoaAddFriendVC () <UITableViewDataSource,UITableViewDelegate,ZSearchViewDelegate>

@property (nonatomic, strong) NoaSearchView *viewSearch;//搜索控件
@property (nonatomic, strong) NoaNoDataView *viewNoData;//该用户不存在
@property (nonatomic, strong) NSMutableArray *friendList;//搜索的好友列表
@property (nonatomic, strong) UIButton *myAccountBtn;

@end


@implementation NoaAddFriendVC

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    _friendList = [NSMutableArray array];
    
    [self setupNavUI];
    [self setupUI];
}

#pragma mark - 界面布局
- (void)setupNavUI {
    self.navTitleStr = LanguageToolMatch(@"添加好友");
    self.navLineView.hidden = YES;
}

- (void)setupUI {
    _viewSearch = [[NoaSearchView alloc] initWithPlaceholder:LanguageToolMatch(@"请输入用户账号/手机号/邮箱")];
    _viewSearch.frame = CGRectMake(0, DWScale(10) + DNavStatusBarH, DScreenWidth, DWScale(38));
    _viewSearch.showClearBtn = YES;
    _viewSearch.returnKeyType = UIReturnKeyDefault;
    _viewSearch.delegate = self;
    [self.view addSubview:_viewSearch];
    
    [self.view addSubview:self.baseTableView];
    self.baseTableView.dataSource = self;
    self.baseTableView.delegate = self;
    [self.baseTableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.trailing.equalTo(self.view);
        make.top.equalTo(_viewSearch.mas_bottom).offset(DWScale(10));
        make.bottom.equalTo(self.view).offset(-DHomeBarH);
    }];
    [self.baseTableView registerClass:[NoaAddFriendCell class] forCellReuseIdentifier:[NoaAddFriendCell cellIdentifier]];
    
    self.myAccountBtn = [[UIButton alloc] init];
    self.myAccountBtn.hidden = NO;
    [self.myAccountBtn setTitle:[NSString stringWithFormat:LanguageToolMatch(@"我的账号：%@"), UserManager.userInfo.userName] forState:UIControlStateNormal];
    [self.myAccountBtn setTkThemeTitleColor:@[COLOR_11, COLORWHITE] forState:UIControlStateNormal];
    [self.myAccountBtn setTkThemeImage:@[ImgNamed(@"icon_addfriend_myqrcode"), ImgNamed(@"icon_addfriend_myqrcode_dark")] forState:UIControlStateNormal];
    self.myAccountBtn.titleLabel.font = FONTN(12);
    [self.myAccountBtn setBtnImageAlignmentType:ButtonImageAlignmentTypeRight imageSpace:DWScale(12)];
    [self.myAccountBtn addTarget:self action:@selector(navToMyQrCodeVcAction) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.myAccountBtn];
    [self.myAccountBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_viewSearch.mas_bottom).offset(DWScale(12));
        make.leading.equalTo(self.view).offset(DWScale(10));
        make.trailing.equalTo(self.view).offset(-DWScale(10));
        make.height.mas_equalTo(DWScale(20));
    }];
    
    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressMyAccountAction:)];
    longPress.minimumPressDuration = 0.8;
    [self.myAccountBtn addGestureRecognizer:longPress];
}

#pragma mark - ZSearchViewDelegate
- (void)searchViewTextValueChanged:(NSString *)searchStr {
    if ([NSString isNil:searchStr]) {
        //数据为空
        [_friendList removeAllObjects];
        [self.baseTableView reloadData];
        self.baseTableView.tableHeaderView = nil;
        self.myAccountBtn.hidden = NO;
    }
}

- (void)searchViewReturnKeySearch:(NSString *)searchStr {
    NSString *searchContent = [searchStr trimString];
    NSInteger count = [self countCharNumberOfString:searchContent];
    if (count > 0) {
        if ([searchStr isEqualToString:UserManager.userInfo.userName]) {
            [HUD showMessage:LanguageToolMatch(@"这是你自己的账号哦~")];
            return;
        }
        //精准搜索，只能搜索到一个
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        [dict setObjectSafe:searchStr forKey:@"userName"];
        WeakSelf
        [IMSDKManager userSearchWith:dict onSuccess:^(id _Nullable data, NSString * _Nullable traceId) {
            [weakSelf.friendList removeAllObjects];
            if (data && [data isKindOfClass:[NSArray class]]) {
                weakSelf.friendList = [NoaUserModel mj_objectArrayWithKeyValuesArray:data];
            }
            weakSelf.myAccountBtn.hidden = weakSelf.friendList.count > 0 ? YES : NO;
            weakSelf.baseTableView.tableHeaderView = weakSelf.friendList.count > 0 ? nil : weakSelf.viewNoData;
            [weakSelf.baseTableView reloadData];
        } onFailure:^(NSInteger code, NSString * _Nullable msg, NSString * _Nullable traceId) {
            self.myAccountBtn.hidden = NO;
            [HUD showMessageWithCode:code errorMsg:msg];
        }];
    }
}

//计算文本字节数(用Unicode字符集表示的话，中文和英文一样，都只占用2个字节)
- (NSInteger)countCharNumberOfString:(NSString *)textString {
    NSInteger charCountResult = 0;
    //utf8下 一个汉字3字节，一个英文1字节，unicode下所有字符2字节
    NSInteger nameBytes = [textString lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
    if (nameBytes) {
        NSInteger unicodeBytes = [textString lengthOfBytesUsingEncoding:NSUnicodeStringEncoding];
        if (nameBytes * 2 >= unicodeBytes) {
            //中文字符的个数 = (utf8字节 * 2 - unicode字节) / 4
            NSInteger chinaCharNum = (nameBytes * 2 - unicodeBytes) / 4;
            if (textString.length >= chinaCharNum) {
                NSInteger englishCharNum = textString.length - chinaCharNum;
                charCountResult = chinaCharNum * 2 + englishCharNum;
            }
        }
    }
    return charCountResult;
}

#pragma mark - 获取我的二维码content后跳转到 我的二维码页面
- (void)navToMyQrCodeVcAction {
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    [dict setObjectSafe:@"" forKey:@"content"];
    [dict setObjectSafe:@1 forKey:@"type"];
    [dict setObjectSafe:UserManager.userInfo.userUID forKey:@"userUid"];
    
    WeakSelf
    [HUD showActivityMessage:@""];
    [IMSDKManager UserGetCreatQrcodeContentWith:dict onSuccess:^(id _Nullable data, NSString * _Nullable traceId) {
        [HUD hideHUD];
        NoaQRCodeModel *model = [NoaQRCodeModel mj_objectWithKeyValues:data];
        NSString *content = model.content;
        //跳转到我的二维码
        NoaMyQRCodeViewController *myQrcodeVC = [[NoaMyQRCodeViewController alloc] init];
        myQrcodeVC.qrcodeContent = ![NSString isNil:content] ? content : @"" ;
        [weakSelf.navigationController pushViewController:myQrcodeVC animated:YES];
    } onFailure:^(NSInteger code, NSString * _Nullable msg, NSString * _Nullable traceId) {
        [HUD hideHUD];
        [HUD showMessageWithCode:code errorMsg:msg];
    }];
}

#pragma mark - 长按我的账号进行复制
- (void)longPressMyAccountAction:(UILongPressGestureRecognizer *)gestureRecognizer {
    if ([gestureRecognizer state] == UIGestureRecognizerStateBegan) {
        UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
        pasteboard.string = UserManager.userInfo.userName;
        [HUD showMessage:LanguageToolMatch(@"复制成功")];
    }
}

#pragma mark - UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _friendList.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NoaAddFriendCell *cell = [tableView dequeueReusableCellWithIdentifier:[NoaAddFriendCell cellIdentifier] forIndexPath:indexPath];
    NoaUserModel *userModel = [_friendList objectAtIndexSafe:indexPath.row];
    cell.userModel = userModel;
    return cell;
}

#pragma mark - UITableViewDelegate
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return [NoaAddFriendCell defaultCellHeight];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NoaUserModel *userModel = [_friendList objectAtIndexSafe:indexPath.row];
    
    NoaUserHomePageVC *vc = [NoaUserHomePageVC new];
    vc.userUID = userModel.userUID;
    vc.groupID = @"";
    [self.navigationController pushViewController:vc animated:YES];
}

#pragma mark - 懒加载
- (NoaNoDataView *)viewNoData {
    if (!_viewNoData) {
        _viewNoData = [[NoaNoDataView alloc] initWithFrame:CGRectMake(0, DWScale(34), DScreenWidth, DWScale(34 + 40))];
        _viewNoData.lblNoDataTip.text = LanguageToolMatch(@"该用户不存在");
        _viewNoData.tkThemebackgroundColors = @[COLORWHITE, COLOR_11];
    }
    return _viewNoData;
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
