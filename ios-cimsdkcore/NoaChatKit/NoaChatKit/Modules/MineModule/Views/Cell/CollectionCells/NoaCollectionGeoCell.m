//
//  NoaCollectionGeoCell.m
//  NoaKit
//
//  Created by Mac on 2023/4/19.
//

#import "NoaCollectionGeoCell.h"

@interface NoaCollectionGeoCell()

@property (nonatomic, strong)UIView *backView;
@property (nonatomic, strong)UIImageView *geoMapImgView;
@property (nonatomic, strong)UILabel *geoNameLbl;
@property (nonatomic, strong)UILabel *geoAddressLbl;
@property (nonatomic, strong)UILabel *nickNameLbl;
@property (nonatomic, strong)UILabel *timeLbl;

@end

@implementation NoaCollectionGeoCell

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
    [self.backView addSubview:self.geoMapImgView];
    [self.backView addSubview:self.geoNameLbl];
    [self.backView addSubview:self.geoAddressLbl];
    [self.backView addSubview:self.nickNameLbl];
    [self.backView addSubview:self.timeLbl];
    
    [self.backView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.contentView).offset(DWScale(16));
        make.leading.equalTo(self.contentView).offset(DWScale(16));
        make.trailing.equalTo(self.contentView).offset(-DWScale(16));
        make.height.mas_equalTo(DWScale(137));
    }];
    
    [self.geoMapImgView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.backView).offset(DWScale(16));
        make.trailing.equalTo(self.backView).offset(-DWScale(16));
        make.width.mas_equalTo(DWScale(66));
        make.height.mas_equalTo(DWScale(66));
    }];
    
    [self.geoNameLbl mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.backView).offset(DWScale(16));
        make.leading.equalTo(self.backView).offset(DWScale(16));
        make.trailing.equalTo(self.geoMapImgView.mas_leading).offset(-DWScale(16));
        make.height.mas_equalTo(DWScale(22));
    }];
    
    [self.geoAddressLbl mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.geoNameLbl.mas_bottom).offset(DWScale(10));
        make.leading.equalTo(self.backView).offset(DWScale(16));
        make.trailing.equalTo(self.geoMapImgView.mas_leading).offset(-DWScale(16));
        make.height.mas_equalTo(DWScale(45));
    }];
    
    [self.nickNameLbl mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.geoMapImgView.mas_bottom).offset(DWScale(22));
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
    
    [self.geoMapImgView sd_setImageWithURL:[_model.itemModel.body.cImg getImageFullUrl] placeholderImage:[UIImage imageCompressFitSizeScale:DefaultImage targetSize:CGSizeMake(_model.itemWidth, _model.itemHeight)] options:SDWebImageAllowInvalidSSLCertificates];
    self.geoNameLbl.text = _model.itemModel.body.name;
    self.geoAddressLbl.text = _model.itemModel.body.details;
    self.nickNameLbl.text = _model.itemModel.nick;
    self.timeLbl.text = _model.itemModel.createTime;
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

- (UIImageView *)geoMapImgView {
    if (!_geoMapImgView) {
        _geoMapImgView = [[UIImageView alloc] init];
        _geoMapImgView.image = DefaultImage;
        [_geoMapImgView rounded:DWScale(4)];
        _geoMapImgView.contentMode = UIViewContentModeScaleAspectFill;
    }
    return _geoMapImgView;
}

- (UILabel *)geoNameLbl {
    if (!_geoNameLbl) {
        _geoNameLbl = [[UILabel alloc] init];
        _geoNameLbl.text = @"";
        _geoNameLbl.tkThemetextColors = @[COLOR_11, COLOR_11_DARK];
        _geoNameLbl.font = FONTN(16);
    }
    return _geoNameLbl;
}

- (UILabel *)geoAddressLbl {
    if (!_geoAddressLbl) {
        _geoAddressLbl = [[UILabel alloc] init];
        _geoAddressLbl.text = @"";
        _geoAddressLbl.tkThemetextColors = @[COLOR_99, COLOR_99_DARK];
        _geoAddressLbl.font = FONTN(14);
        _geoAddressLbl.numberOfLines = 2;
    }
    return _geoAddressLbl;
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
