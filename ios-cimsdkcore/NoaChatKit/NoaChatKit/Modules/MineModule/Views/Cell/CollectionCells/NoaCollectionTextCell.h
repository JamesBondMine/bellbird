//
//  NoaCollectionTextCell.h
//  NoaKit
//
//  Created by Mac on 2023/4/19.
//

#import "MGSwipeTableCell.h"
#import "NoaMyCollectionModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface NoaCollectionTextCell : MGSwipeTableCell

@property (nonatomic, strong) NoaMyCollectionModel *model;

@end

NS_ASSUME_NONNULL_END
