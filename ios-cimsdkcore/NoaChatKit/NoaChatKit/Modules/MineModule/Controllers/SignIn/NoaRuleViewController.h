//
//  NoaRuleViewController.h
//  NoaKit
//
//  Created by Apple on 2023/8/9.
//

#import "NoaBaseViewController.h"
#import "NoaSignInRuleModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface NoaRuleViewController : NoaBaseViewController

@property (nonatomic, assign) CGFloat ruleContentAttHeight;
@property (nonatomic, copy) NSMutableAttributedString *ruleContentAtt;
@property(nonatomic,strong) NoaSignInRuleModel* signRuleModel;

@end

NS_ASSUME_NONNULL_END
