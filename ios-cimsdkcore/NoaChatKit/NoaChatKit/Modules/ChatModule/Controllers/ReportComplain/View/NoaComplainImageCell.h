//
//  NoaComplainImageCell.h
//  NoaKit
//
//  Created by mac on 2023/6/19.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN
@protocol ZComplainImageCellDelegate <NSObject>
- (void)cellDeleteImageWith:(NSIndexPath *)cellIndex;
@end

@interface NoaComplainImageCell : UICollectionViewCell
@property (nonatomic, strong) UIImageView *ivComplain;
@property (nonatomic, strong) UIButton *btnDelete;
@property (nonatomic, strong) NSIndexPath *cellIndex;
@property (nonatomic, weak) id <ZComplainImageCellDelegate> delegate;
@end

NS_ASSUME_NONNULL_END
