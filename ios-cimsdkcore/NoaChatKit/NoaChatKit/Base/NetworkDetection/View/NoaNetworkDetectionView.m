//
//  NoaNetworkDetectionView.m
//  NoaChatKit
//
//  Created by phl on 2025/10/15.
//  TODO: 网络检测页面

#import "NoaNetworkDetectionView.h"
#import "NoaNetworkDetectionHandle.h"
#import "NoaNetworkDetectionTopHeaderView.h"
#import "NoaNetworkDetectionMessageModel.h"
#import "NoaNetworkDetectionSectionHeaderView.h"
#import "NoaNetworkDetectionMainResultCell.h"
#import "NoaNetworkDetectionSubResultCell.h"

@interface NoaNetworkDetectionView ()<UITableViewDelegate, UITableViewDataSource>

/// 数据处理
@property (nonatomic, strong) NoaNetworkDetectionHandle *dataHandle;

/// 头部视图
@property (nonatomic, strong) NoaNetworkDetectionTopHeaderView *headerView;

/// 检测内容展示
@property (nonatomic, strong) UITableView *tableView;

/// 网络检测按钮
@property (nonatomic, strong) UIButton *networkDetectionSwitchBtn;

@property (nonatomic, strong) MASConstraint *tableViewHeightConstraint;

@end

@implementation NoaNetworkDetectionView

// MARK: set/get
- (NoaNetworkDetectionTopHeaderView *)headerView {
    if (!_headerView) {
        _headerView = [[NoaNetworkDetectionTopHeaderView alloc] initWithFrame:CGRectZero dataHandle:self.dataHandle];
    }
    return _headerView;
}

- (UITableView *)tableView {
    if (!_tableView) {
        _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped];
        _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        _tableView.tkThemebackgroundColors = @[COLOR_F5F6F9, COLOR_11];
        _tableView.dataSource = self;
        _tableView.delegate = self;
        _tableView.sectionHeaderHeight = CGFLOAT_MIN;
        _tableView.sectionFooterHeight = CGFLOAT_MIN;
        // 启用自动高度计算
        _tableView.estimatedRowHeight = 25.0;
        _tableView.rowHeight = UITableViewAutomaticDimension;
        _tableView.showsVerticalScrollIndicator = NO;
        _tableView.showsHorizontalScrollIndicator = NO;
        if (@available(iOS 15.0, *)) {
            _tableView.sectionHeaderTopPadding = 0;
        }
        [_tableView registerClass:[NoaNetworkDetectionSectionHeaderView class] forHeaderFooterViewReuseIdentifier:NSStringFromClass([NoaNetworkDetectionSectionHeaderView class])];
        
        _tableView.layer.cornerRadius = 12.0;
        _tableView.layer.masksToBounds = YES;
    }
    return _tableView;
}

- (UIButton *)networkDetectionSwitchBtn {
    if (!_networkDetectionSwitchBtn) {
        _networkDetectionSwitchBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_networkDetectionSwitchBtn setTitle:LanguageToolMatch(@"开始检测") forState:UIControlStateNormal];
        _networkDetectionSwitchBtn.titleLabel.font = FONTM(16);
        _networkDetectionSwitchBtn.titleLabel.tkThemetextColors = @[COLORWHITE, COLORWHITE];
        _networkDetectionSwitchBtn.tkThemebackgroundColors = @[COLOR_5966F2, COLOR_5966F2_DARK];
        _networkDetectionSwitchBtn.layer.cornerRadius = 8.0;
        _networkDetectionSwitchBtn.layer.masksToBounds = YES;
    }
    return _networkDetectionSwitchBtn;
}

- (instancetype)initWithFrame:(CGRect)frame
                   dataHandle:(NoaNetworkDetectionHandle *)dataHandle {
    self = [super initWithFrame:frame];
    if (self) {
        self.dataHandle = dataHandle;
        [self setupUI];
        [self processData];
    }
    return self;
}

- (void)setupUI {
    self.tkThemebackgroundColors = @[COLOR_F5F6F9, COLOR_11];
    
    // 布局
    [self addSubview:self.headerView];
    [self addSubview:self.tableView];
    [self addSubview:self.networkDetectionSwitchBtn];
    
    [self.headerView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self);
        make.leading.trailing.equalTo(self);
    }];
    [self.tableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.headerView.mas_bottom);
        make.leading.equalTo(@16);
        make.trailing.equalTo(self).offset(-16);
        make.bottom.equalTo(self.networkDetectionSwitchBtn.mas_top).offset(-24);
    }];
    
    [self.networkDetectionSwitchBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self);
        make.width.equalTo(self).offset(-32);
        make.height.equalTo(@44);
        make.bottom.equalTo(self).offset(-(DHomeBarH + 12));
    }];
    
    @weakify(self)
    [[self.networkDetectionSwitchBtn rac_signalForControlEvents:UIControlEventTouchUpInside] subscribeNext:^(__kindof UIControl * _Nullable x) {
        @strongify(self)
        if (self.dataHandle.networkDetectionStatus == ZNetworkDetectionAlready ||
            self.dataHandle.networkDetectionStatus == ZNetworkDetectFinish) {
            [self.networkDetectionSwitchBtn setTitle:LanguageToolMatch(@"退出检测") forState:UIControlStateNormal];
            [self.dataHandle.startDetectionCommand execute:nil];
        }else {
            [self.networkDetectionSwitchBtn setTitle:LanguageToolMatch(@"开始检测") forState:UIControlStateNormal];
            [self.dataHandle cleanLastDetectionData];
            [self.dataHandle cancelAllDetections];
        }
    }];
}

- (void)processData {
    @weakify(self)
    [self.dataHandle.tableViewReloadDataSubject subscribeNext:^(id  _Nullable x) {
        @strongify(self)
        [self.tableView reloadData];
    }];
    
    [self.dataHandle.startDetectionCommand.executionSignals.switchToLatest subscribeNext:^(id  _Nullable x) {
        @strongify(self)
        if (self.dataHandle.networkDetectionStatus == ZNetworkDetectFinish) {
            [self.networkDetectionSwitchBtn setTitle:LanguageToolMatch(@"重新检测") forState:UIControlStateNormal];
        }else {
            [self.networkDetectionSwitchBtn setTitle:LanguageToolMatch(@"开始检测") forState:UIControlStateNormal];
        }
    }];
}

// MARK: UITableViewDelegate, UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.dataHandle.tableDataSource.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NoaNetworkDetectionMessageModel *sectionModel = [self.dataHandle getSectionModelWithIndex:section];
    if (sectionModel) {
        if (sectionModel.isFold) {
            // 折叠状态
            return 1;
        }
        return sectionModel.subFunctionResultArr.count + 1;
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSInteger section = indexPath.section;
    NSInteger row = indexPath.row;
    if (row == 0) {
        NoaNetworkDetectionMainResultCell *mainCell = [tableView dequeueReusableCellWithIdentifier:NSStringFromClass([NoaNetworkDetectionMainResultCell class])];
        if (!mainCell) {
            mainCell = [[NoaNetworkDetectionMainResultCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:NSStringFromClass([NoaNetworkDetectionMainResultCell class])];
        }
        
        NoaNetworkDetectionMessageModel *sectionModel = [self.dataHandle getSectionModelWithIndex:section];
        mainCell.model = sectionModel;
        
        return mainCell;
    }
    
    NoaNetworkDetectionSubResultCell *subCell = [tableView dequeueReusableCellWithIdentifier:NSStringFromClass([NoaNetworkDetectionSubResultCell class])];
    if (!subCell) {
        subCell = [[NoaNetworkDetectionSubResultCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:NSStringFromClass([NoaNetworkDetectionSubResultCell class])];
    }
    
    NoaNetworkDetectionSubResultModel *cellModel = [self.dataHandle getCellModelWithIndexPath:indexPath];
    subCell.model = cellModel;
    
    BOOL isLastCell = NO;
    NSInteger rows = [tableView numberOfRowsInSection:section];
    if (row == rows - 1) {
        isLastCell = YES;
    }
    
    subCell.isLastCell = isLastCell;
    
    return subCell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSInteger row = indexPath.row;
    if (row == 0) {
        return 48.0;
    }
    return UITableViewAutomaticDimension;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return CGFLOAT_MIN;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UIView *headerView = [[UIView alloc] init];
    headerView.tkThemebackgroundColors = @[COLORWHITE, COLORWHITE_DARK];
    return headerView;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return CGFLOAT_MIN;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    UIView *footerView = [[UIView alloc] init];
    footerView.tkThemebackgroundColors = @[COLORWHITE, COLORWHITE_DARK];
    return footerView;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSInteger section = indexPath.section;
    NSInteger row = indexPath.row;
    if (row != 0) {
        return;
    }
    
    // 点击标题
    NoaNetworkDetectionMessageModel *sectionModel = [self.dataHandle getSectionModelWithIndex:section];
    if (sectionModel.messageStatus == ZNetworkDetectionMessageWaitStatus) {
        // 未开始，禁止点击
        return;
    }
    sectionModel.isFold = !sectionModel.isFold;
    [self.tableView reloadData];
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    NSInteger currentSection = indexPath.section;
    NSInteger currentRow = indexPath.row;
    
    BOOL isNeedCornerRadius = NO;
    if (currentSection == 0) {
        isNeedCornerRadius = YES;
    }
    
    if (currentSection == self.dataHandle.tableDataSource.count - 1) {
        isNeedCornerRadius = YES;
    }
    
    if (!isNeedCornerRadius) {
        // 移除旧的 mask，防止复用残留
        cell.layer.mask = nil;
        return;
    }
    
    NSInteger rows = [tableView numberOfRowsInSection:currentSection];
    
    // 移除旧的 mask，防止复用残留
    cell.layer.mask = nil;
    
    // 计算圆角半径
    CGFloat cornerRadius = 12.0;
    CGRect bounds = cell.bounds;
    
    if (currentSection == 0 && currentRow == 0) {
        // 第一行 -> 上圆角
        UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:bounds
                                                   byRoundingCorners:(UIRectCornerTopLeft | UIRectCornerTopRight)
                                                         cornerRadii:CGSizeMake(cornerRadius, cornerRadius)];
        CAShapeLayer *maskLayer = [CAShapeLayer layer];
        maskLayer.path = path.CGPath;
        cell.layer.mask = maskLayer;
        return;
    }
    
    if (currentSection == self.dataHandle.tableDataSource.count - 1 && currentRow == rows - 1) {
        // 最后一行 -> 下圆角
        UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:bounds
                                                   byRoundingCorners:(UIRectCornerBottomLeft | UIRectCornerBottomRight)
                                                         cornerRadii:CGSizeMake(cornerRadius, cornerRadius)];
        CAShapeLayer *maskLayer = [CAShapeLayer layer];
        maskLayer.path = path.CGPath;
        cell.layer.mask = maskLayer;
        return;
    }
}

/*
 // Only override drawRect: if you perform custom drawing.
 // An empty implementation adversely affects performance during animation.
 - (void)drawRect:(CGRect)rect {
 // Drawing code
 }
 */

@end
