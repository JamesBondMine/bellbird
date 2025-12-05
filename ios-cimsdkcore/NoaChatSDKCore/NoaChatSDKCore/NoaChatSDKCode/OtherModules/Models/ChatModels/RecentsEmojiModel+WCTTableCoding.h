//
//  RecentsEmojiModel+WCTTableCoding.h
//  NoaChatSDKCore
//
//  Created by mac on 2023/10/27.
//

#import "RecentsEmojiModel.h"
#import <WCDBObjc/WCDBObjc.h>

@interface RecentsEmojiModel (WCTTableCoding) <WCTTableCoding>

WCDB_PROPERTY(emojiName)
WCDB_PROPERTY(en)
WCDB_PROPERTY(type)
WCDB_PROPERTY(zhCN)
WCDB_PROPERTY(zhTW)

@end
