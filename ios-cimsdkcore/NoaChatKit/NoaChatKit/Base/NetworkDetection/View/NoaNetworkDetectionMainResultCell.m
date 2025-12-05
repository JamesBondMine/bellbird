//
//  NoaNetworkDetectionMainResultCell.m
//  NoaChatKit
//
//  Created by 庞海亮 on 2025/10/19.
//

#import "NoaNetworkDetectionMainResultCell.h"
#import "NoaNetworkDetectionMessageModel.h"

@interface NoaNetworkDetectionMainResultCell ()

/// 标题
@property (nonatomic, strong) UILabel *titleLabel;

/// 右侧等待检测状态描述
@property (nonatomic, strong) UILabel *waitDetectLabel;

/// 检测状态图标(如果是检测中带动画)
@property (nonatomic, strong) UIImageView *statusImgView;

/// 右侧箭头
@property (nonatomic, strong) UIImageView *arrowImgView;

/// 状态监听subject的状态管理
@property (nonatomic, strong) RACDisposable *statusDisposable;

@end

@implementation NoaNetworkDetectionMainResultCell

// MARK: set/get
- (UILabel *)titleLabel {
    if (!_titleLabel) {
        _titleLabel = [UILabel new];
        _titleLabel.tkThemetextColors = @[COLOR_11, COLOR_11_DARK];
        _titleLabel.font = FONTM(14);
    }
    return _titleLabel;
}

- (UILabel *)waitDetectLabel {
    if (!_waitDetectLabel) {
        _waitDetectLabel = [UILabel new];
        _waitDetectLabel.tkThemetextColors = @[COLOR_99, COLOR_99_DARK];
        _waitDetectLabel.font = FONTR(12);
        _waitDetectLabel.text = LanguageToolMatch(@"待检测");
        _waitDetectLabel.textAlignment = NSTextAlignmentRight;
    }
    return _waitDetectLabel;
}

- (UIImageView *)statusImgView {
    if (!_statusImgView) {
        _statusImgView = [UIImageView new];
        _statusImgView.hidden = YES;
    }
    return _statusImgView;
}

- (UIImageView *)arrowImgView {
    if (!_arrowImgView) {
        _arrowImgView = [UIImageView new];
        _arrowImgView.image = [UIImage imageNamed:@"c_arrow_right_gray"];
        _arrowImgView.hidden = YES;
    }
    return _arrowImgView;
}

- (void)setModel:(NoaNetworkDetectionMessageModel *)model {
    if (!model) {
        self.titleLabel.text = @"";
        self.waitDetectLabel.hidden = NO;
        self.statusImgView.hidden = YES;
        self.arrowImgView.hidden = YES;
        if (_statusDisposable) {
            [_statusDisposable dispose];
            _statusDisposable = nil;
        }
        return;
    }
    
    _model = model;
    
    if (_model.isFold) {
        // 当前折叠
        self.arrowImgView.image = [UIImage imageNamed:@"c_arrow_right_gray"];
        [self.arrowImgView mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.centerY.equalTo(self.titleLabel);
            make.trailing.equalTo(self.contentView).offset(-19);
            make.width.equalTo(@6);
            make.height.equalTo(@12);
        }];
    }else {
        // 当前展开
        self.arrowImgView.image = [UIImage imageNamed:@"c_arrow_down_gray"];
        [self.arrowImgView mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.centerY.equalTo(self.titleLabel);
            make.trailing.equalTo(self.contentView).offset(-16);
            make.width.equalTo(@12);
            make.height.equalTo(@6);
        }];
    }
    
    // 先取消旧的订阅，避免因为cell复用导致重复订阅同一个 subject
    if (_statusDisposable) {
        [_statusDisposable dispose];
        _statusDisposable = nil;
    }
    
    @weakify(self)
    // 保存订阅对象，方便下次取消
    _statusDisposable = [[_model.changeStatusSubject takeUntil:self.rac_willDeallocSignal] subscribeNext:^(id  _Nullable x) {
        @strongify(self)
        // 更新UI
        if ([self.model.sectionTitle isEqualToString:LanguageToolMatch(@"网络连接情况")]) {
            CIMLog(@"[网络链路检测] 网络连接情况收到通知，状态: %@", x);
        }
        ZNetworkDetectionMessageStatus status = [x integerValue];
        [self refreshUIWithStatus:status];
    }];
    
    self.titleLabel.text = model.sectionTitle;
    self.waitDetectLabel.hidden = (model.messageStatus != ZNetworkDetectionMessageWaitStatus);
    [self refreshUIWithStatus:_model.messageStatus];
}

/// 刷新UI
/// - Parameter messageStatus: 当前状态
- (void)refreshUIWithStatus:(ZNetworkDetectionMessageStatus)messageStatus {
    switch (messageStatus) {
        case ZNetworkDetectionMessageWaitStatus:
            // 等待检测
            self.waitDetectLabel.hidden = NO;
            self.statusImgView.hidden = YES;
            self.arrowImgView.hidden = YES;
            [self stopStatusImgViewRotateAnimation];
            break;
        case ZNetworkDetectionMessageDetectingStatus:
            // 检测中
            self.waitDetectLabel.hidden = YES;
            self.statusImgView.hidden = NO;
            self.arrowImgView.hidden = NO;
            self.statusImgView.image = [UIImage imageNamed:@"icon_network_detection_loading"];
            [self startStatusImgViewRotateAnimation];
            break;
        case ZNetworkDetectionMessageEndStatus:
            // 检测结束
            self.waitDetectLabel.hidden = YES;
            self.statusImgView.hidden = NO;
            self.arrowImgView.hidden = NO;
            if ([self.model isAllSubFunctionPass]) {
                self.statusImgView.image = [UIImage imageNamed:@"icon_network_detection_result_success"];
            }else {
                self.statusImgView.image = [UIImage imageNamed:@"icon_network_detection_result_fail"];
            }
            [self stopStatusImgViewRotateAnimation];
            break;
        default:
            self.waitDetectLabel.hidden = NO;
            self.statusImgView.hidden = YES;
            self.arrowImgView.hidden = YES;
            [self stopStatusImgViewRotateAnimation];
            break;
    }
}

/// 开始状态图标旋转动画
- (void)startStatusImgViewRotateAnimation {
    // 防止重复添加动画
    if ([self.statusImgView.layer animationForKey:@"rotateAnimation"]) {
        return;
    }
    CABasicAnimation *rotation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
    rotation.toValue = @(M_PI * 2);
    rotation.duration = 1.0;
    rotation.repeatCount = HUGE_VALF;
    rotation.removedOnCompletion = NO;
    rotation.fillMode = kCAFillModeForwards;
    [self.statusImgView.layer addAnimation:rotation forKey:@"rotateAnimation"];
}

/// 停止状态图标旋转动画并恢复角度
- (void)stopStatusImgViewRotateAnimation {
    [self.statusImgView.layer removeAnimationForKey:@"rotateAnimation"];
    self.statusImgView.transform = CGAffineTransformIdentity;
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        [self setUpUI];
    }
    return self;
}

- (void)setUpUI {
    self.contentView.tkThemebackgroundColors = @[COLORWHITE, COLORWHITE_DARK];
    [self.contentView addSubview:self.titleLabel];
    [self.contentView addSubview:self.waitDetectLabel];
    [self.contentView addSubview:self.statusImgView];
    [self.contentView addSubview:self.arrowImgView];
    
    [self.titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(@14);
        make.leading.equalTo(@16);
        make.height.equalTo(@20);
        make.trailing.greaterThanOrEqualTo(self.waitDetectLabel.mas_leading).offset(-16);
    }];
    
    [self.waitDetectLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.titleLabel);
        make.trailing.equalTo(self.contentView).offset(-16);
        make.height.equalTo(@17);
        make.width.greaterThanOrEqualTo(@36);
    }];
    
    [self.statusImgView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.titleLabel);
        make.trailing.equalTo(self.arrowImgView.mas_leading).offset(-7);
        make.height.equalTo(@16);
        make.width.equalTo(@16);
    }];
    
    [self.arrowImgView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.titleLabel);
        make.trailing.equalTo(self.contentView).offset(-19);
        make.width.equalTo(@6);
        make.height.equalTo(@12);
    }];
}

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
    
    // Configure the view for the selected state
}

@end
