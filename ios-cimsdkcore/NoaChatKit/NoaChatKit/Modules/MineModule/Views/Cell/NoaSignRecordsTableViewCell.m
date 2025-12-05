//
//  NoaSignRecordsTableViewCell.m
//  NoaKit
//
//  Created by Apple on 2023/8/9.
//

#import "NoaSignRecordsTableViewCell.h"
@interface NoaSignRecordsTableViewCell ()

@property (nonatomic, strong) UIButton *backView;
@property (nonatomic, strong) UILabel * dataLabel;//签到时间
@property (nonatomic, strong) UILabel * todayPointLabel;//日签积分
@property(nonatomic,strong) UILabel * todayRewardsPointLabel;//奖励积分
@property(nonatomic,strong) UILabel * todayTotalPointLabel;//日总积分

@end
@implementation NoaSignRecordsTableViewCell
- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.contentView.backgroundColor = UIColor.clearColor;
        self.backgroundColor = UIColor.clearColor;
        [self setupUI];
    }
    return self;
}
-(void)setupUI{
    
    UIImageView * logoImgView = [[UIImageView alloc] init];
    logoImgView.image = ImgNamed(@"signLogoicon");
    [self.contentView addSubview:logoImgView];
    
    [logoImgView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.mas_equalTo(self.contentView.mas_leading).offset(16);
        make.centerY.mas_equalTo(self.contentView);
        make.size.mas_equalTo(CGSizeMake(DWScale(30), DWScale(30)));
    }];
    
    UILabel * dataLabel = [[UILabel alloc] init];
    dataLabel.tkThemetextColors = @[COLOR_66, COLOR_99];
    dataLabel.font = FONTR(12);
    [self.contentView addSubview:dataLabel];
    self.dataLabel =  dataLabel;
    [dataLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.mas_equalTo(logoImgView.mas_trailing).offset(DWScale(7));
        make.centerY.mas_equalTo(self.contentView);
        make.width.mas_equalTo((DScreenWidth - DWScale(30) - 32)/4+7);
        make.height.mas_equalTo(DWScale(18));
    }];
    
    UILabel * todayPointLabel = [[UILabel alloc] init];
    todayPointLabel.text = @"+1.00";
    todayPointLabel.textAlignment = NSTextAlignmentCenter;
    todayPointLabel.textColor = HEXCOLOR(@"4791FF");
    todayPointLabel.font = FONTR(12);
    [self.contentView addSubview:todayPointLabel];
    self.todayPointLabel = todayPointLabel;
    [todayPointLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.mas_equalTo(dataLabel.mas_trailing);
        make.centerY.mas_equalTo(self.contentView);
        make.width.mas_equalTo((DScreenWidth - DWScale(30) - 32)/4);
        make.height.mas_equalTo(DWScale(18));
    }];
    
    UILabel * todayRewardsPointLabel = [[UILabel alloc] init];
    todayRewardsPointLabel.text = @"+1.00";
    todayRewardsPointLabel.textAlignment = NSTextAlignmentCenter;
    todayRewardsPointLabel.textColor = HEXCOLOR(@"4791FF");
    todayRewardsPointLabel.font = FONTR(12);
    [self.contentView addSubview:todayRewardsPointLabel];
    self.todayRewardsPointLabel = todayRewardsPointLabel;
    [todayRewardsPointLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.mas_equalTo(todayPointLabel.mas_trailing);
        make.centerY.mas_equalTo(self.contentView);
        make.width.mas_equalTo((DScreenWidth - DWScale(30) - 32)/4);
        make.height.mas_equalTo(DWScale(18));
    }];
    
    UILabel * todayTotalPointLabel = [[UILabel alloc] init];
    todayTotalPointLabel.text = @"+2.00";
    todayTotalPointLabel.textAlignment = NSTextAlignmentCenter;
    todayTotalPointLabel.textColor = HEXCOLOR(@"4791FF");
    todayTotalPointLabel.font = FONTR(12);
    [self.contentView addSubview:todayTotalPointLabel];
    self.todayTotalPointLabel = todayTotalPointLabel;
    [todayTotalPointLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.mas_equalTo(todayRewardsPointLabel.mas_trailing);
        make.centerY.mas_equalTo(self.contentView);
        make.width.mas_equalTo((DScreenWidth - DWScale(30) - 32)/4);
        make.height.mas_equalTo(DWScale(18));
    }];
}
-(void)setSignRecordsWithDic:(NSDictionary*)dict{
    if(dict){
        long long createTime = [[dict objectForKey:@"createTime"] integerValue];//签到时间
        NSInteger money = [[dict objectForKey:@"money"] integerValue];//日总积分
        NSInteger signMoneyAway = [[dict objectForKey:@"signMoneyAway"] integerValue];//签到奖励积分
        NSInteger signMoneyDay = [[dict objectForKey:@"signMoneyDay"] integerValue];//日签积分
        
        NSString * createTimeStr = [NSDate transTimeStrToDateMethod3:createTime];
        self.dataLabel.text = createTimeStr;
        self.todayPointLabel.text = [NSString stringWithFormat:@"+%ld",signMoneyDay];
        self.todayRewardsPointLabel.text = [NSString stringWithFormat:@"+%ld",signMoneyAway];
        self.todayTotalPointLabel.text = [NSString stringWithFormat:@"+%ld",money];
    }
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
