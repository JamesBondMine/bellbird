//
//  NoaTitleContentButtonCell.h
//  NoaKit
//
//  Created by mac on 2022/9/14.
//

// 通用的 标题 内容 按钮 - Cell

#import "NoaBaseCell.h"

NS_ASSUME_NONNULL_BEGIN
@protocol ZTitleContentButtonCellDelegate <NSObject>
- (void)cellButtonAction:(id)action;
@end

@interface NoaTitleContentButtonCell : NoaBaseCell
@property (nonatomic, strong) UILabel *lblTitle;
@property (nonatomic, strong) UILabel *lblContent;
@property (nonatomic, strong) UIButton *btnAction;

@property (nonatomic, weak) id <ZTitleContentButtonCellDelegate> delegate;
@property (nonatomic, strong) id cellData;
@end

NS_ASSUME_NONNULL_END
