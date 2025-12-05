//
//  NoaUserInfoViewController.m
//  NoaKit
//
//  Created by Mac on 2022/11/12.
//

#import "NoaUserInfoViewController.h"
#import "NoaMineUserInfoCell.h"
#import "NoaChangeUserInfoViewController.h"
#import "NoaImagePickerVC.h"      //相册
#import "NoaFileUploadModel.h"
#import "NoaToolManager.h"
#import "NoaFileUploadManager.h"
//#import "ZFileNetProgressManager.h"
#import "NoaImageBrowser.h"
//#import "NSArray+Addition.h"

@interface NoaUserInfoViewController () <UITableViewDelegate, UITableViewDataSource, ZImagePickerVCDelegate, ZBaseCellDelegate, ZMineUserInfoCellDelegate>

@property (nonatomic, strong)NSArray *dataArr;
//@property (nonatomic, strong)ZFileNetProgressManager *fileUploader;
@property (nonatomic, strong) NoaImageBrowser *imageBrowser;

@end

@implementation NoaUserInfoViewController

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self.baseTableView reloadData];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navTitleStr = LanguageToolMatch(@"编辑个人资料");
    [self setUpData];
    [self setupUI];
}

- (void)setUpData {
    self.dataArr = @[LanguageToolMatch(@"头像"),LanguageToolMatch(@"昵称"), LanguageToolMatch(@"账号")];
}

//为了调试方便，先加一个退出登录的测试按钮
- (void)setupUI {
    self.baseTableView.delegate = self;
    self.baseTableView.dataSource = self;
    self.baseTableView.bounces = NO;
    self.baseTableView.separatorColor = COLOR_CLEAR;
    self.baseTableView.delaysContentTouches = NO;
    self.baseTableView.tkThemebackgroundColors = @[COLOR_F5F6F9, COLOR_11];
    [self.view addSubview:self.baseTableView];
    [self.baseTableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view).offset(DNavStatusBarH);
        make.leading.trailing.equalTo(self.view);
        make.bottom.equalTo(self.view).offset(-DHomeBarH);
    }];
    
    [self.baseTableView registerClass:[NoaMineUserInfoCell class] forCellReuseIdentifier:NSStringFromClass([NoaMineUserInfoCell class])];
}

#pragma mark - UITableViewDelegate  UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.dataArr.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row > 0) return DWScale(70);
    return DWScale(84.f);
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return CGFLOAT_MIN;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return CGFLOAT_MIN;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NoaMineUserInfoCell *cell = [tableView dequeueReusableCellWithIdentifier:NSStringFromClass([NoaMineUserInfoCell class]) forIndexPath:indexPath];
    cell.cellIndex = indexPath.row;
    cell.baseCellIndexPath = indexPath;
    cell.baseDelegate = self;
    cell.delegate = self;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - ZBaseCellDelegate
- (void)cellClickAction:(NSIndexPath *)indexPath {
    switch (indexPath.row) {
        case 0:
        {
            //修改头像
            [self changeUserAvater];
        }
            break;
        case 1:
        {
            //修改昵称
            NoaChangeUserInfoViewController *nickChangeVC = [[NoaChangeUserInfoViewController alloc] init];
            nickChangeVC.changeType = changeUserInfoTypeNick;
            nickChangeVC.originalContent = UserManager.userInfo.nickname;
            [self.navigationController pushViewController:nickChangeVC animated:YES];
        }
            break;
        case 2:
        {
            return;
            /*
            //修改账号
            NoaChangeUserInfoViewController *accountChangeVC = [[NoaChangeUserInfoViewController alloc] init];
            accountChangeVC.changeType = changeUserInfoTypeAccount;
            accountChangeVC.originalContent = UserManager.userInfo.userName;
            [self.navigationController pushViewController:accountChangeVC animated:YES];
            */
        }
            break;
            
        default:
            break;
    }
}

#pragma mark - ZMineUserInfoCellDelegate
- (void)headerImageClickAction:(UIImage *)image url:(NSString *)url {
    if (image != nil || ![NSString isNil:url]) {
        
        NSLog(@"点击了头像--> headerImageClickAction: ");
        [self headerImageBrowser:image url:url];
    }
}

- (void)headerImageBrowser:(UIImage *)image url:(NSString *)url {
    
    NSMutableArray *items = [NSMutableArray array];
    NSMutableArray *selectItems = [NSMutableArray array];
    
    KNPhotoItems *item = [[KNPhotoItems alloc] init];
    //图片
    item.isVideo = false;
    if (image) {
        item.sourceImage = image;
    }
    if(url) {
        //网络图片
        item.url = url;
        //缩略图地址
        item.thumbnailUrl = url;
    }
    
    [items addObjectIfNotNil:item];
    
    NoaPresentItem *modifyItem = [NoaPresentItem creatPresentViewItemWithText:LanguageToolMatch(@"修改个人头像") textColor:COLOR_11 font:FONTR(17) itemHeight:DWScale(54) backgroundColor:COLORWHITE];
    self.tkThemeChangeBlock = ^(id  _Nullable itself, NSUInteger themeIndex) {
        if (themeIndex == 0) {
            modifyItem.textColor = COLOR_11;
            modifyItem.backgroundColor = COLORWHITE;
        }else {
            modifyItem.textColor = COLORWHITE;
            modifyItem.backgroundColor = COLOR_11;
        }
    };
    [selectItems addObjectIfNotNil:modifyItem];
    
    NoaPresentItem *saveItem = [NoaPresentItem creatPresentViewItemWithText:LanguageToolMatch(@"保存到手机") textColor:COLOR_11 font:FONTR(17) itemHeight:DWScale(54) backgroundColor:COLORWHITE];
    self.tkThemeChangeBlock = ^(id  _Nullable itself, NSUInteger themeIndex) {
        if (themeIndex == 0) {
            saveItem.textColor = COLOR_11;
            saveItem.backgroundColor = COLORWHITE;
        }else {
            saveItem.textColor = COLORWHITE;
            saveItem.backgroundColor = COLOR_11;
        }
    };
    [selectItems addObjectIfNotNil:saveItem];
    
    NoaPresentItem *cancelItem = [NoaPresentItem creatPresentViewItemWithText:LanguageToolMatch(@"取消") textColor:COLOR_99 font:FONTR(17) itemHeight:DWScale(54) backgroundColor:COLORWHITE];
    self.tkThemeChangeBlock = ^(id  _Nullable itself, NSUInteger themeIndex) {
        if (themeIndex == 0) {
            cancelItem.textColor = COLOR_99;
            cancelItem.backgroundColor = COLORWHITE;
        }else {
            cancelItem.textColor = COLOR_99;
            cancelItem.backgroundColor = COLOR_11;
        }
    };
    
    NSString *imageUrl = item.url;
    WeakSelf;
    [self.imageBrowser imageBrowserWithImageItems:items currentIndex:0 selectItems:selectItems cancleItem:cancelItem doneClick:^(NSInteger index, KNPhotoItems *photoItems) {
        
        if (index == 0) { // 修改个人头像
            [weakSelf.imageBrowser dismiss];
            [weakSelf changeUserAvater];
        } else if (index == 1) { // 保存到手机
            NSString *customPath = @"";
            [ZTOOL saveImageToAlbumWith:imageUrl Cusotm:customPath];
        }
        NSLog(@"");
    } cancleClick:^{
        NSLog(@"");
    }];
}

//修改头像
- (void)changeUserAvater {
    //先检测权限，再进入相册，解决某些系统第一次不能获取照片，杀死进程后可以获取照片的问题
    WeakSelf
    [ZTOOL getPhotoLibraryAuth:^(BOOL granted) {
        if (granted) {
            [ZTOOL doInMain:^{
                NoaImagePickerVC *vc = [NoaImagePickerVC new];
                vc.isSignlePhoto = YES;
                vc.isNeedEdit = YES;
                vc.hasCamera = YES;
                vc.delegate = self;
                [vc setPickerType:ZImagePickerTypeImage];
                [weakSelf.navigationController pushViewController:vc animated:YES];
            }];
        }else {
            [HUD showWarningMessage:LanguageToolMatch(@"相册权限未开启，请在设置中选择当前应用，开启相册权限")];
        }
    }];
}

#pragma mark - ZImagePickerVCDelegate
- (void)imagePickerClipImage:(UIImage *)resultImg localIdenti:(NSString *)localIdenti {
    [HUD showActivityMessage:@""];
    NSData *imageData = UIImageJPEGRepresentation(resultImg, 1.0);//转成jpeg
    UIImage *comSizeImage = [UIImage imageWithImage:[UIImage imageWithData:imageData] scaledToSize:CGSizeMake(200, 200)];
    NSData *comMassImageData = [UIImage compressImageSize:comSizeImage toByte:50*1024];
    NSString *imageName = [[NSString alloc] initWithFormat:@"%@_%lld.%@", UserManager.userInfo.userUID, [NSDate currentTimeIntervalWithMillisecond], [NSString getImageFileFormat:comMassImageData]];
    NSString *customPath = [NSString stringWithFormat:@"%@-%@", UserManager.userInfo.userUID, UserManager.userInfo.userUID];
    
    __block NSString *imagePath = @"";
    [ZTOOL doAsync:^{
        [NSString saveImageToSaxboxWithData:comMassImageData CustomPath:customPath ImgName:imageName];
        imagePath = [NSString getPathWithImageName:imageName CustomPath:customPath];
    } completion:^{
        //上传头像图片
        WeakSelf
        NoaFileUploadTask *task = [[NoaFileUploadTask alloc] initWithTaskId:imageName filePath:imagePath originFilePath:@"" fileName:imageName fileType:@"" isEncrypt:YES dataLength:comMassImageData.length uploadType:ZHttpUploadTypeUserAvatar beSendMessage:nil delegate:nil];
         NSBlockOperation * blockOperation = [NSBlockOperation blockOperationWithBlock:^{
             if (task.status == FileUploadTaskStatus_Completed) {
                 [weakSelf requestUpdateUserAvatar:task.originUrl];
             }
             if (task.status == FileUploadTaskStatus_Failed) {
                 [ZTOOL doInMain:^{
                     [HUD hideHUD];
                     [HUD showMessage:LanguageToolMatch(@"上传头像失败")];
                 }];
             }
         }];
        
        NoaFileUploadGetSTSTask *getSTSTask = [[NoaFileUploadGetSTSTask alloc] init];
        [task addDependency:getSTSTask];
        [blockOperation addDependency:task];
        [[NoaFileUploadManager sharedInstance] addUploadTask:task];
        [[NoaFileUploadManager sharedInstance].operationQueue addOperation:blockOperation];
        [[NoaFileUploadManager sharedInstance].operationQueue addOperation:getSTSTask];

    }];
}

#pragma mark - 调用更新头像接口
- (void)requestUpdateUserAvatar:(NSString *)avatarUrl {
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    [dict setObjectSafe:avatarUrl forKey:@"avatar"];
    [dict setObjectSafe:UserManager.userInfo.userUID forKey:@"userUid"];
    
    WeakSelf
    [IMSDKManager userAvatarChangeWith:dict onSuccess:^(id _Nullable data, NSString * _Nullable traceId) {
        NoaUserModel *resultUserModel = UserManager.userInfo;
        resultUserModel.avatar = avatarUrl;
        [resultUserModel saveUserInfo];
        [UserManager setUserInfo:resultUserModel];
        [HUD hideHUD];
        [HUD showMessage:LanguageToolMatch(@"更新头像成功")];
        [weakSelf.baseTableView reloadData];
    } onFailure:^(NSInteger code, NSString * _Nullable msg, NSString * _Nullable traceId) {
        [HUD hideHUD];
        [HUD showMessage:LanguageToolMatch(@"更新头像失败")];
    }];
}

#pragma mark - Lazy
//- (ZFileNetProgressManager *)fileUploader {
//    if (!_fileUploader) {
//        _fileUploader = [[ZFileNetProgressManager alloc] init];
//    }
//    return _fileUploader;
//}

- (NoaImageBrowser *)imageBrowser {
    if (_imageBrowser == nil) {
        _imageBrowser = [[NoaImageBrowser alloc] init];
    }
    
    return _imageBrowser;
}

@end
