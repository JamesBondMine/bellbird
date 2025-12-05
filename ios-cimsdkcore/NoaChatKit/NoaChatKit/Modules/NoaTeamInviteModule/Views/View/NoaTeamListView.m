//
//  NoaTeamListView.m
//  NoaKit
//
//  Created by phl on 2025/7/21.
//

#import "NoaTeamListView.h"
#import "NoaTeamListDataHandle.h"
#import "NoaTeamListHeaderView.h"
#import "NoaTeamListCell.h"
#import <DZNEmptyDataSet/UIScrollView+EmptyDataSet.h>

@interface NoaTeamListView()<UITableViewDelegate, UITableViewDataSource, DZNEmptyDataSetSource,DZNEmptyDataSetDelegate>

/// 下拉刷新
@property (nonatomic, strong) MJRefreshNormalHeader *refreshHeader;

/// 上拉加载
@property (nonatomic, strong) MJRefreshBackNormalFooter *refreshFooter;

/// 数据处理类(TableView相关数据业务处理)
@property (nonatomic, strong) NoaTeamListDataHandle *teamListDataHandle;

/// 顶部数据显示
@property (nonatomic, strong) NoaTeamListHeaderView *headerView;

/// 列表
@property (nonatomic, strong) UITableView *tableView;

@end

@implementation NoaTeamListView

- (void)dealloc {
    CIMLog(@"%@ dealloc", [self class]);
}

- (MJRefreshNormalHeader *)refreshHeader {
    if (!_refreshHeader) {
        @weakify(self)
        _refreshHeader = [MJRefreshNormalHeader headerWithRefreshingBlock:^{
            @strongify(self)
            [self.teamListDataHandle resumeDefaultConfigure];
            
            [self.teamListDataHandle.requestTeamHomeDataCommand execute:nil];
            [self.teamListDataHandle.requestTeamListCommand execute:nil];
        }];
        
        _refreshHeader.lastUpdatedTimeLabel.font = [UIFont systemFontOfSize:14];
        _refreshHeader.lastUpdatedTimeLabel.hidden = YES;
        _refreshHeader.stateLabel.font = [UIFont systemFontOfSize:14];
        [_refreshHeader setTitle:LanguageToolMatch(@"下拉刷新") forState:MJRefreshStateIdle];
        [_refreshHeader setTitle:LanguageToolMatch(@"下拉刷新") forState:MJRefreshStatePulling];
        [_refreshHeader setTitle:LanguageToolMatch(@"正在加载...") forState:MJRefreshStateRefreshing];
        [_refreshHeader setTitle:LanguageToolMatch(@"正在加载...") forState:MJRefreshStateWillRefresh];
        
    }
    return _refreshHeader;
}
- (MJRefreshBackNormalFooter *)refreshFooter {
    if (!_refreshFooter) {
        @weakify(self)
        _refreshFooter = [MJRefreshBackNormalFooter footerWithRefreshingBlock:^{
            @strongify(self)
            [self.teamListDataHandle requestMoreDataConfigure];
            [self.teamListDataHandle.requestTeamListCommand execute:nil];
        }];
        _refreshFooter.stateLabel.font = [UIFont systemFontOfSize:14];
        [_refreshFooter setTitle:LanguageToolMatch(@"上拉加载更多") forState:MJRefreshStateIdle];
        [_refreshFooter setTitle:LanguageToolMatch(@"上拉加载更多") forState:MJRefreshStatePulling];
        [_refreshFooter setTitle:LanguageToolMatch(@"正在加载...") forState:MJRefreshStateRefreshing];
        [_refreshFooter setTitle:LanguageToolMatch(@"正在加载...") forState:MJRefreshStateWillRefresh];
        [_refreshFooter setTitle:LanguageToolMatch(@"我是有底线的") forState:MJRefreshStateNoMoreData];
    }
    return _refreshFooter;
}

/// 展示团队总数据
- (NoaTeamListHeaderView *)headerView {
    if (!_headerView) {
        _headerView = [[NoaTeamListHeaderView alloc] initWithFrame:CGRectZero];
    }
    return _headerView;
}

/// 展示我创建的团队
- (UITableView *)tableView {
    if (!_tableView) {
        _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
        _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        _tableView.backgroundColor = UIColor.clearColor;
        _tableView.dataSource = self;
        _tableView.delegate = self;
        _tableView.mj_header = self.refreshHeader;
        _tableView.mj_footer = self.refreshFooter;
        _tableView.emptyDataSetSource = self;
        _tableView.emptyDataSetDelegate = self;
    }
    return _tableView;
}

/// 跳转详情页面通知
- (RACSubject *)jumpDetailVCSubject {
    if (!_jumpDetailVCSubject) {
        _jumpDetailVCSubject = [RACSubject subject];
    }
    return _jumpDetailVCSubject;
}

- (instancetype)initWithFrame:(CGRect)frame
           TeamListDataHandle:(NoaTeamListDataHandle *)dataHandle {
    self = [super initWithFrame:frame];
    if (self) {
        self.teamListDataHandle = dataHandle;
        [self setupUI];
        [self processData];
    }
    return self;
}

- (void)setupUI {
    // 背景图片
    UIImageView *bgImageView = [UIImageView new];
    bgImageView.image = [UIImage imageNamed:@"team_list_top_bgImg"];
    [self addSubview:bgImageView];
    [bgImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self);
    }];
    
    // 团队总数据
    [self addSubview:self.headerView];
    [self.headerView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(@(DNavStatusBarH));
        make.leading.trailing.equalTo(self);
        make.height.equalTo(@204);
    }];
    
    // 我创建的团队
    [self addSubview:self.tableView];
    [self.tableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.headerView.mas_bottom);
        make.leading.trailing.bottom.equalTo(self);
    }];
}

- (void)reloadData {
    [self.tableView.mj_header beginRefreshing];
}

- (void)processData {
    @weakify(self)
    [self.teamListDataHandle.requestTeamHomeDataCommand.executionSignals.switchToLatest subscribeNext:^(id  _Nullable x) {
        @strongify(self)
        BOOL isSuccess = [x boolValue];
        if (!isSuccess) {
            return;
        }
        self.headerView.teamModel = self.teamListDataHandle.defaultTeamModel;
    }];
    
    [self.teamListDataHandle.requestTeamListCommand.executionSignals.switchToLatest subscribeNext:^(id  _Nullable x) {
        @strongify(self)
        [self.tableView.mj_header endRefreshing];
        [self.tableView.mj_footer endRefreshing];
        BOOL isSuccess = [x boolValue];
        if (!isSuccess) {
            return;
        }
        [self.tableView reloadData];
    }];
    
    [self reloadData];
}

#pragma mark - UITableViewDelegate  UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.teamListDataHandle.teamListModelArr.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NoaTeamListCell *cell = [tableView dequeueReusableCellWithIdentifier:NSStringFromClass([NoaTeamListCell class])];
    if (!cell) {
        cell = [[NoaTeamListCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:NSStringFromClass([NoaTeamListCell class])];
    }
    
    NoaTeamModel *teamModel = [self.teamListDataHandle obtainTeamModelWithIndexPath:indexPath];
    cell.teamModel = teamModel;
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    NoaTeamModel *teamModel = [self.teamListDataHandle obtainTeamModelWithIndexPath:indexPath];
    if (!teamModel) {
        return 88;
    }
  
    return teamModel.isDefaultTeam == 1 ? 100 : 88;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NoaTeamModel *teamModel = [self.teamListDataHandle obtainTeamModelWithIndexPath:indexPath];
    [self.jumpDetailVCSubject sendNext:teamModel];
}

/// MARK: DZNEmptyDataSetSource
- (NSAttributedString *)titleForEmptyDataSet:(UIScrollView *)scrollView {
    NSString *string = LanguageToolMatch(@"暂无数据");
    __block NSMutableAttributedString *accessAttributeString;
    self.tkThemeChangeBlock = ^(id  _Nullable itself, NSUInteger themeIndex) {
        switch (themeIndex) {
            case 1: {
                //暗黑
                accessAttributeString  = [[NSMutableAttributedString alloc] initWithString:string attributes:@{NSFontAttributeName:FONTR(14),NSForegroundColorAttributeName:COLOR_99}];
            }
                break;
                
            default: {
                accessAttributeString  = [[NSMutableAttributedString alloc] initWithString:string attributes:@{NSFontAttributeName:FONTR(14),NSForegroundColorAttributeName:COLOR_00}];
            }
                break;
        }
    };
    return accessAttributeString;
}
/// 图片距离中心偏移量
- (CGFloat)verticalOffsetForEmptyDataSet:(UIScrollView *)scrollView {
    return - 30;
}
/// 空态图片
- (UIImage *)imageForEmptyDataSet:(UIScrollView *)scrollView {
    return ImgNamed(@"c_no_history_chat");
}

/// MARK:  DZNEmptyDataSetDelegate
/// 允许滑动
- (BOOL)emptyDataSetShouldAllowScroll:(UIScrollView *)scrollView {
    return YES;
}


/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
