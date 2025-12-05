//
//  NoaCollectionFileCell.m
//  NoaKit
//
//  Created by Mac on 2023/4/19.
//

#import "NoaCollectionFileCell.h"

@interface NoaCollectionFileCell()

@property (nonatomic, strong)UIView *backView;
@property (nonatomic, strong)UIImageView *fileTypeImgView;
@property (nonatomic, strong)UILabel *littetTypeLbl;
@property (nonatomic, strong)UILabel *fileNameLbl;
@property (nonatomic, strong)UILabel *fileTypeSizeLbl;
@property (nonatomic, strong)UILabel *nickNameLbl;
@property (nonatomic, strong)UILabel *timeLbl;

@end

@implementation NoaCollectionFileCell

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
    [self.backView addSubview:self.fileTypeImgView];
    [self.fileTypeImgView addSubview:self.littetTypeLbl];
    [self.backView addSubview:self.fileNameLbl];
    [self.backView addSubview:self.fileTypeSizeLbl];
    [self.backView addSubview:self.nickNameLbl];
    [self.backView addSubview:self.timeLbl];
    
    [self.backView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.contentView).offset(DWScale(16));
        make.leading.equalTo(self.contentView).offset(DWScale(16));
        make.trailing.equalTo(self.contentView).offset(-DWScale(16));
        make.height.mas_equalTo(DWScale(137));
    }];
    
    [self.fileTypeImgView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.backView).offset(DWScale(16));
        make.trailing.equalTo(self.backView).offset(-DWScale(20));
        make.width.mas_equalTo(DWScale(54));
        make.height.mas_equalTo(DWScale(66));
    }];
    
    [self.littetTypeLbl mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(self.fileTypeImgView).offset(-DWScale(10));
        make.leading.trailing.equalTo(self.fileTypeImgView);
        make.height.mas_equalTo(DWScale(16));
    }];
    
    [self.fileNameLbl mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.backView).offset(DWScale(16));
        make.leading.equalTo(self.backView).offset(DWScale(16));
        make.trailing.equalTo(self.fileTypeImgView.mas_leading).offset(-DWScale(12));
        make.height.mas_equalTo(DWScale(22));
    }];
    
    [self.fileTypeSizeLbl mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.fileNameLbl.mas_bottom).offset(DWScale(10));
        make.leading.equalTo(self.backView).offset(DWScale(16));
        make.trailing.equalTo(self.fileTypeImgView.mas_leading).offset(-DWScale(12));
        make.height.mas_equalTo(DWScale(20));
    }];
    
    [self.nickNameLbl mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.fileTypeImgView.mas_bottom).offset(DWScale(22));
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
    
    self.fileTypeImgView.image = [UIImage getFileMessageIconWithFileType:_model.itemModel.body.type fileName:_model.itemModel.body.name];
    self.littetTypeLbl.text = [NSString getFileTypeContentWithFileType:_model.itemModel.body.type fileName:_model.itemModel.body.name];
    NSRange range1 = [_model.itemModel.body.name rangeOfString:@"-"];
    if (range1.length == 0) {
        self.fileNameLbl.text = _model.itemModel.body.name;
    } else {
        self.fileNameLbl.text = [_model.itemModel.body.name safeSubstringWithRange:NSMakeRange(range1.location+1, _model.itemModel.body.name.length - (range1.location+1))];
    }
    self.fileTypeSizeLbl.text = [NSString stringWithFormat:@"%@ %@", [NSString getFileTypeContentWithFileType:_model.itemModel.body.type fileName:_model.itemModel.body.name], [NSString fileTranslateToSize:_model.itemModel.body.size]];
    
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

- (UIImageView *)fileTypeImgView {
    if (!_fileTypeImgView) {
        _fileTypeImgView = [[UIImageView alloc] init];
    }
    return _fileTypeImgView;
}

- (UILabel *)littetTypeLbl {
    if (!_littetTypeLbl) {
        _littetTypeLbl = [[UILabel alloc] init];
        _littetTypeLbl.text = @"";
        _littetTypeLbl.tkThemetextColors = @[COLORWHITE, COLORWHITE];
        _littetTypeLbl.font = FONTN(18);
        _littetTypeLbl.textAlignment = NSTextAlignmentCenter;
    }
    return _littetTypeLbl;
}

- (UILabel *)fileNameLbl {
    if (!_fileNameLbl) {
        _fileNameLbl = [[UILabel alloc] init];
        _fileNameLbl.text = @"";
        _fileNameLbl.tkThemetextColors = @[COLOR_11, COLOR_11_DARK];
        _fileNameLbl.font = FONTN(16);
    }
    return _fileNameLbl;
}

- (UILabel *)fileTypeSizeLbl {
    if (!_fileTypeSizeLbl) {
        _fileTypeSizeLbl = [[UILabel alloc] init];
        _fileTypeSizeLbl.text = @"";
        _fileTypeSizeLbl.tkThemetextColors = @[COLOR_99, COLOR_99_DARK];
        _fileTypeSizeLbl.font = FONTN(14);
    }
    return _fileTypeSizeLbl;
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
