//
//  NoaRegisterTypeView.m
//  NoaChatKit
//
//  Created by phl on 2025/11/11.
//

#import "NoaRegisterTypeView.h"
#import "NoaRegisterTypeCell.h"
#import "NoaRegisterTypeDataHandle.h"

@interface NoaRegisterTypeView ()<UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) UITableView *tableView;

@property (nonatomic, strong) NoaRegisterTypeDataHandle *dataHandle;

@end

@implementation NoaRegisterTypeView

#pragma mark - Lazy Loading

/// 展示我创建的团队
- (UITableView *)tableView {
    if (!_tableView) {
        _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
        _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        _tableView.backgroundColor = UIColor.clearColor;
        _tableView.dataSource = self;
        _tableView.delegate = self;
    }
    return _tableView;
}

- (instancetype)initWithFrame:(CGRect)frame
                   DataHandle:(NoaRegisterTypeDataHandle *)dataHandle {
    self = [super initWithFrame:frame];
    if (self) {
        self.dataHandle = dataHandle;
        [self setUpUI];
    }
    return self;
}

- (void)setUpUI {
    [self addSubview:self.tableView];
    [self.tableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.leading.trailing.bottom.equalTo(self);
    }];
}

#pragma mark - tableview delegate
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.dataHandle getRegisterTypeCount];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NoaRegisterTypeCell *cell = [tableView dequeueReusableCellWithIdentifier:NSStringFromClass([NoaRegisterTypeCell class])];
    if (!cell) {
        cell = [[NoaRegisterTypeCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:NSStringFromClass([NoaRegisterTypeCell class])];
    }
    cell.registerTypeModel = [self.dataHandle getRegisterTypeModelWithIndexPath:indexPath];
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 116;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 50.0;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UIView *headerView = [UIView new];
    headerView.tkThemebackgroundColors = @[UIColor.clearColor, UIColor.clearColor];
    return headerView;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NoaRegisterTypeModel *registerTypeModel = [self.dataHandle getRegisterTypeModelWithIndexPath:indexPath];
    [self.dataHandle.jumpRegisterDetailSubject sendNext:registerTypeModel];
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
