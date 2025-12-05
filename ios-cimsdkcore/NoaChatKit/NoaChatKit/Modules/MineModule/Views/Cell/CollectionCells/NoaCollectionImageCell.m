//
//  NoaCollectionImageCell.m
//  NoaKit
//
//  Created by Mac on 2023/4/19.
//

#import "NoaCollectionImageCell.h"

@interface NoaCollectionImageCell()

@property (nonatomic, strong)UIView *backView;
@property (nonatomic, strong)UIImageView *contentImgView;
@property (nonatomic, strong)UILabel *nickNameLbl;
@property (nonatomic, strong)UILabel *timeLbl;

@end

@implementation NoaCollectionImageCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.contentView.tkThemebackgroundColors = @[COLOR_F5F6F9, COLOR_11];
        [self setupUI];
    }
    return self;
}

#pragma mark - UI
- (void)setupUI {
    [self.contentView addSubview:self.backView];
    [self.backView addSubview:self.contentImgView];
    [self.backView addSubview:self.nickNameLbl];
    [self.backView addSubview:self.timeLbl];
    
    [self.backView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.contentView).offset(DWScale(16));
        make.leading.equalTo(self.contentView).offset(DWScale(16));
        make.trailing.equalTo(self.contentView).offset(-DWScale(16));
        make.height.mas_equalTo(DWScale(145));
    }];
    
    [self.contentImgView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.backView).offset(DWScale(16));
        make.leading.equalTo(self.backView).offset(DWScale(16));
        make.width.mas_equalTo(DWScale(80));
        make.height.mas_equalTo(DWScale(80));
    }];
    
    [self.nickNameLbl mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.contentImgView.mas_bottom).offset(DWScale(16));
        make.leading.equalTo(self.backView).offset(DWScale(16));
        make.width.mas_equalTo((DScreenWidth - DWScale(16)*4)/2 - DWScale(10));
        make.height.mas_equalTo(DWScale(18));
    }];
    
    [self.timeLbl mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.nickNameLbl);
        make.trailing.equalTo(self.backView).offset(-DWScale(16));
        make.width.mas_equalTo((DScreenWidth - DWScale(16)*4)/2 - DWScale(10));
        make.height.mas_equalTo(DWScale(18));
    }];
}

#pragma mark - Model
- (void)setModel:(NoaMyCollectionModel *)model {
    _model = model;
    WeakSelf;
    
    [self.contentImgView sd_setImageWithURL:[_model.itemModel.body.iImg getImageFullUrl] placeholderImage:[UIImage imageCompressFitSizeScale:DefaultImage targetSize:CGSizeMake(_model.itemWidth, _model.itemHeight)] options:SDWebImageAllowInvalidSSLCertificates progress:nil completed:^(UIImage * _Nullable image, NSError * _Nullable error, SDImageCacheType cacheType, NSURL * _Nullable imageURL) {
        StrongSelf;
        [strongSelf loadWithImage:image URL:[model.itemModel.body.iImg getImageFullString] error:error];
    }];
    self.nickNameLbl.text = _model.itemModel.nick;
    self.timeLbl.text = _model.itemModel.createTime;
}

- (void)loadWithImage:(UIImage *)image URL:(NSString *)url error:(NSError *)error {
    
    if (!image) {
        self.contentImgView.image = [UIImage imageCompressFitSizeScale:DefaultNoImage targetSize:CGSizeMake(_model.itemWidth, _model.itemHeight)];
        [self loadImageFailWithURL:url error:error];
    }
}
// 图片加载失败信息上报
- (void)loadImageFailWithURL:(NSString *)url error:(NSError *)error {
    
    if ([NSString isNil:url] || [NSString isNil:error.description]) {
        return;
    }
    //日志上传 oss竞速失败
    NSMutableDictionary *loganDict = [NSMutableDictionary dictionary];
    [loganDict setValue:url forKey:@"imageUrl"];
    [loganDict setValue:error.description forKey:@"failReason"];
    [IMSDKManager imSdkWriteLoganWith:LingIMLoganTypeApi loganContent:[[NoaIMLoganManager sharedManager] configLoganContent:loganDict]];

}

#pragma mark - Lazy
- (UIView *)backView {
    if (!_backView) {
        _backView = [[UIView alloc] init];
        _backView.tkThemebackgroundColors = @[COLORWHITE, COLOR_F5F6F9_DARK];
        [_backView rounded:12];
    }
    return _backView;
}

- (UIImageView *)contentImgView {
    if (!_contentImgView) {
        _contentImgView = [[UIImageView alloc] init];
        _contentImgView.image = DefaultImage;
        [_contentImgView rounded:DWScale(2)];
        _contentImgView.contentMode = UIViewContentModeScaleAspectFit;
    }
    return _contentImgView;
}

- (UILabel *)nickNameLbl {
    if (!_nickNameLbl) {
        _nickNameLbl = [[UILabel alloc] init];
        _nickNameLbl.text = @"";
        _nickNameLbl.tkThemetextColors = @[COLOR_99, COLOR_99_DARK];
        _nickNameLbl.font = FONTN(12);
        _nickNameLbl.textAlignment = NSTextAlignmentLeft;
    }
    return _nickNameLbl;
}

- (UILabel *)timeLbl {
    if (!_timeLbl) {
        _timeLbl = [[UILabel alloc] init];
        _timeLbl.text = @"";
        _timeLbl.tkThemetextColors = @[COLOR_99, COLOR_99_DARK];
        _timeLbl.font = FONTN(12);
        _timeLbl.textAlignment = NSTextAlignmentRight;
    }
    return _timeLbl;
}


#pragma mark - Other
- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
