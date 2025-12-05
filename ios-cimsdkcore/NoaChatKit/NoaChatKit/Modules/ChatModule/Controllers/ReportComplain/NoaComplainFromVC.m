//
//  NoaComplainFromVC.m
//  NoaKit
//
//  Created by Mac on 2023/6/19.
//

#import "NoaComplainFromVC.h"
#import "NoaToolManager.h"
#import "UITextView+Addition.h"
#import "NoaComplainImageCell.h"
#import "NoaImagePickerVC.h"
#import "NoaFileDownloadManager.h"
#import "UITextView+Placeholder.h"
#import "NoaFileUploadManager.h"

#define complaint_reson_max_num     200

@interface NoaComplainFromVC () <UICollectionViewDataSource, UICollectionViewDelegate, ZComplainImageCellDelegate, ZImagePickerVCDelegate, UITextFieldDelegate, UITextViewDelegate, ZFileUploadTaskDelegate>

@property (nonatomic, strong)UIScrollView *contentScroll;
@property (nonatomic, strong)UIView *containerView;
@property (nonatomic, strong)UIView *imgContentView;
@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) UILabel *lblImageNumber;
@property (nonatomic, strong) NSMutableArray *imageList;
@property (nonatomic, strong)UIView *textContentView;
@property (nonatomic, strong)UITextView *contentTextView;
@property (nonatomic, strong)UILabel *contentTextNumLbl;
@property (nonatomic, strong)UIView *itemContentView;
@property (nonatomic, strong)UIButton *itemContentBtn;//投诉原因
@property (nonatomic, strong)UITextField *emailTextField;
@property (nonatomic, strong)UITextField *domainTextField;
@property (nonatomic, strong)UIView *domainBackView;
@property (nonatomic, strong)UIButton *btnSubmit;//提交投诉

@property (nonatomic, copy) NSString *comImages;//投诉图片(非全路径)(系统投诉)
@property (nonatomic, copy) NSString *comFullImages;//投诉图片(全路径)(企业号/域名)
@property (nonatomic, copy) NSString *comContent;//投诉内容
@property (nonatomic, copy) NSString *comType;//投诉类型
@property (nonatomic, copy) NSString *comEmail;//邮箱
@property (nonatomic, copy) NSString *comCompany;//企业号/域名
@end

@implementation NoaComplainFromVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _imageList = [NSMutableArray array];
    _comType = @"1";//默认发布违法有害信息
    
    self.view.tkThemebackgroundColors = @[COLORWHITE, COLORWHITE_DARK];
    self.navView.hidden = YES;
    [self setupUI];
}

- (void)setupUI {
    [self.view addSubview:self.contentScroll];
    [self.contentScroll mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.top.trailing.mas_equalTo(self.view);
        make.bottom.mas_equalTo(self.view).offset(-DWScale(110));
    }];
      
    
    [self.contentScroll addSubview:self.containerView];
    [self.containerView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.contentScroll);
        make.width.equalTo(self.contentScroll);//这个不能省略
    }];
    
    //图片证据(必填)
    [self setupImgContentView];
    //投诉内容
    [self setupTextContentView];
    //投诉类型
    [self setupItemContentView];
    //邮箱输入框
    [self setupEmailContentView];
    //企业号/域名输入框
    [self setupDomainContentView];
   
   
    //提交投诉
    _btnSubmit = [UIButton buttonWithType:UIButtonTypeCustom];
    _btnSubmit.layer.cornerRadius = DWScale(8);
    _btnSubmit.layer.masksToBounds = YES;
    [_btnSubmit setTitle:LanguageToolMatch(@"确认提交投诉") forState:UIControlStateNormal];
    [_btnSubmit setTkThemeTitleColor:@[COLORWHITE, COLORWHITE] forState:UIControlStateNormal];
    _btnSubmit.titleLabel.font = FONTR(12);
    _btnSubmit.enabled = NO;
    [_btnSubmit setTkThemebackgroundColors:@[[COLOR_5966F2 colorWithAlphaComponent:0.3], [COLOR_5966F2_DARK colorWithAlphaComponent:0.3]]];
    [_btnSubmit addTarget:self action:@selector(btnSubmitClick) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_btnSubmit];
    [_btnSubmit mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(self.view).offset(-DHomeBarH - DWScale(15));
        make.height.mas_equalTo(DWScale(44));
        make.leading.equalTo(self.view).offset(DWScale(20));
        make.trailing.equalTo(self.view).offset(-DWScale(20));
    }];
}

//图片证据(必填)
- (void)setupImgContentView {
    
    [self.containerView addSubview:self.imgContentView];
    [self.imgContentView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.containerView);
        make.leading.equalTo(self.containerView).offset(DWScale(20));
        make.trailing.equalTo(self.containerView).offset(-DWScale(20));
        make.height.mas_equalTo(DWScale(136));
    }];

    
    UILabel *lblImageTip = [[UILabel alloc] init];
    lblImageTip.text = LanguageToolMatch(@"图片证据(必填)");
    lblImageTip.font = FONTR(12);
    lblImageTip.tkThemetextColors = @[COLOR_11, COLOR_11_DARK];
    [self.imgContentView addSubview:lblImageTip];
    [lblImageTip mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.leading.equalTo(self.imgContentView);
        make.size.mas_equalTo(CGSizeMake(DWScale(200), DWScale(36)));
    }];
    
    _lblImageNumber = [UILabel new];
    _lblImageNumber.text = [NSString stringWithFormat:LanguageToolMatch(@"%d张/9"), 0];
    _lblImageNumber.font = FONTR(12);
    _lblImageNumber.tkThemetextColors = @[COLOR_99, COLOR_99_DARK];
    [self.imgContentView addSubview:_lblImageNumber];
    [_lblImageNumber mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(lblImageTip);
        make.trailing.equalTo(self.imgContentView);
    }];
    
    UICollectionViewFlowLayout *layout = [UICollectionViewFlowLayout new];
    layout.scrollDirection = UICollectionViewScrollDirectionVertical;
    layout.itemSize = CGSizeMake(DWScale(84), DWScale(84));
    layout.minimumLineSpacing = DWScale(3);
    layout.minimumInteritemSpacing = DWScale(3);
    layout.sectionInset = UIEdgeInsetsZero;
    _collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
    [_collectionView registerClass:[NoaComplainImageCell class] forCellWithReuseIdentifier:NSStringFromClass([NoaComplainImageCell class])];
    _collectionView.delegate = self;
    _collectionView.dataSource = self;
    _collectionView.tkThemebackgroundColors = @[COLOR_CLEAR, COLOR_CLEAR_DARK];
    [self.imgContentView addSubview:_collectionView];
    [_collectionView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(self.imgContentView);
        make.top.equalTo(self.imgContentView).offset(DWScale(36));
        make.size.mas_equalTo(CGSizeMake(DWScale(264), DWScale(84)));
    }];
    
    UIView *lineView = [[UIView alloc] init];
    lineView.tkThemebackgroundColors = @[COLOR_EEEEEE, COLOR_EEEEEE_DARK];
    [self.imgContentView addSubview:lineView];
    [lineView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.height.mas_equalTo(1);
        make.bottom.leading.trailing.equalTo(self.imgContentView);
    }];
}

//投诉内容
- (void)setupTextContentView {
    [self.containerView addSubview:self.textContentView];
    [self.textContentView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.imgContentView.mas_bottom);
        make.leading.equalTo(self.containerView).offset(DWScale(20));
        make.trailing.equalTo(self.containerView).offset(-DWScale(20));
        make.height.mas_equalTo(DWScale(116));
    }];
    
    UILabel *titleLbl = [[UILabel alloc] init];
    titleLbl.text = LanguageToolMatch(@"投诉内容");
    titleLbl.font = FONTB(12);
    titleLbl.tkThemetextColors = @[COLOR_00, COLOR_00_DARK];
    [self.textContentView addSubview:titleLbl];
    [titleLbl mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.textContentView).offset(DWScale(20));
        make.leading.equalTo(self.textContentView).offset(DWScale(2));
        make.width.mas_equalTo(DWScale(160));
        make.height.mas_equalTo(DWScale(16));
    }];
    
    UIView *lineView = [[UIView alloc] init];
    lineView.tkThemebackgroundColors = @[COLOR_EEEEEE, COLOR_EEEEEE_DARK];
    [self.textContentView addSubview:lineView];
    [lineView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.bottom.trailing.equalTo(self.textContentView);
        make.height.mas_equalTo(1);
    }];
    
    [self.textContentView addSubview:self.contentTextNumLbl];
    [self.contentTextNumLbl mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(lineView.mas_top).offset(-DWScale(16));
        make.trailing.equalTo(self.textContentView);
        make.width.mas_equalTo(DWScale(80));
        make.height.mas_equalTo(DWScale(16));
    }];
    
    [self.textContentView addSubview:self.contentTextView];
    [self.contentTextView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(titleLbl.mas_bottom).offset(DWScale(10));
        make.leading.trailing.equalTo(self.textContentView);
        make.bottom.equalTo(self.contentTextNumLbl.mas_top).offset(-DWScale(5));
    }];
}

//投诉类型
- (void)setupItemContentView {
    [self.containerView addSubview:self.itemContentView];
    [self.itemContentView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.textContentView.mas_bottom);
        make.leading.equalTo(self.containerView).offset(DWScale(20));
        make.trailing.equalTo(self.containerView).offset(-DWScale(20));
        make.height.mas_equalTo(DWScale(50));
    }];
    
    UIView *lineView = [[UIView alloc] init];
    lineView.tkThemebackgroundColors = @[COLOR_EEEEEE, COLOR_EEEEEE_DARK];
    [self.itemContentView addSubview:lineView];
    [lineView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.bottom.trailing.equalTo(self.itemContentView);
        make.height.mas_equalTo(1);
    }];
    
    UIImageView *arrowImgView = [[UIImageView alloc] init];
    arrowImgView.image = ImgNamed(@"c_arrow_right_gray");
    [self.itemContentView addSubview:arrowImgView];
    [arrowImgView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.trailing.equalTo(self.itemContentView);
        make.centerY.equalTo(self.itemContentView);
        make.width.mas_equalTo(DWScale(8));
        make.height.mas_equalTo(DWScale(16));
    }];
    
    [self.itemContentView addSubview:self.itemContentBtn];
    [self.itemContentBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.itemContentView);
        make.bottom.equalTo(lineView.mas_top);
        make.trailing.equalTo(arrowImgView).offset(-DWScale(10));
        make.leading.equalTo(self.itemContentView).offset(DWScale(2));
    }];
}

//邮箱输入框
- (void)setupEmailContentView {
    UIView *backView = [[UIView alloc] init];
    backView.tkThemebackgroundColors = @[COLOR_F5F6F9, COLOR_F5F6F9_DARK];
    [backView rounded:DWScale(8)];
    [self.containerView addSubview:backView];
    [backView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.itemContentView.mas_bottom).offset(DWScale(16));
        make.leading.equalTo(self.containerView).offset(DWScale(20));
        make.trailing.equalTo(self.containerView).offset(-DWScale(20));
        make.height.mas_equalTo(DWScale(44));
    }];
    
    [backView addSubview:self.emailTextField];
    [self.emailTextField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(backView);
        make.leading.equalTo(backView).offset(DWScale(7));
        make.trailing.equalTo(backView).offset(-DWScale(7));
        make.height.mas_equalTo(DWScale(44));
    }];
}

//企业号/域名输入框
- (void)setupDomainContentView {
    [self.containerView addSubview:self.domainBackView];
    [self.domainBackView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.emailTextField.mas_bottom).offset(DWScale(16));
        make.leading.equalTo(self.containerView).offset(DWScale(20));
        make.trailing.equalTo(self.containerView).offset(-DWScale(20));
        make.height.mas_equalTo(DWScale(44));
    }];
    
    [self.domainBackView addSubview:self.domainTextField];
    [self.domainTextField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.domainBackView);
        make.leading.equalTo(self.domainBackView).offset(DWScale(7));
        make.trailing.equalTo(self.domainBackView).offset(-DWScale(7));
        make.height.mas_equalTo(DWScale(44));
    }];
}

//区分 系统投诉 和 企业号/域名投诉
- (void)setComplainVCType:(ZComplainType)complainVCType {
    _complainVCType = complainVCType;
    if (_complainVCType == ZComplainTypeSystem) {
        self.domainBackView.hidden = YES;
        [self.domainBackView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.emailTextField.mas_bottom);
            make.leading.equalTo(self.containerView).offset(DWScale(20));
            make.trailing.equalTo(self.containerView).offset(-DWScale(20));
            make.height.mas_equalTo(0);
        }];
        
        self.domainTextField.hidden = YES;
        [self.domainTextField mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.domainBackView);
            make.leading.equalTo(self.domainBackView).offset(DWScale(7));
            make.trailing.equalTo(self.domainBackView).offset(-DWScale(7));
            make.height.mas_equalTo(0);
        }];
        
        [self.containerView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.bottom.equalTo(self.emailTextField).offset(DWScale(10));
        }];
    } else {
        [self.containerView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.bottom.equalTo(self.domainTextField).offset(DWScale(10));
        }];
    }
}

#pragma mark - UITextViewDelegate
- (void)textViewDidChange:(UITextView *)textView {
    //字数限制操作
    if (textView.text.length >= complaint_reson_max_num) {
        textView.text = [textView.text substringToIndex:complaint_reson_max_num];
    }
    self.contentTextNumLbl.text = [NSString stringWithFormat:@"%lu/%d", (unsigned long)textView.text.length, complaint_reson_max_num];
}

#pragma mark - UITextFieldDelegate
- (BOOL)textFieldShouldEndEditing:(UITextField *)textField {
    return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
//    if ([textField isEqual:_tfEmail]) {
//        //正则邮箱
//        NSString *emailStr = [textField.text trimString];
//        if ([emailStr notEmpty]) {
//            //邮箱格式校验
//            NSString *emailRegex = @"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}";
//            NSPredicate *emailPredicate = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegex];
//            if ([emailPredicate evaluateWithObject:emailStr]) {
//                _lblEmailTip.hidden = YES;
//            }else {
//                _lblEmailTip.hidden = NO;
//            }
//        }else {
//            _lblEmailTip.hidden = YES;
//        }
//        
//    }
}
#pragma mark - UICollectionViewDataSource
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    if (_imageList.count > 0) {
        return _imageList.count >= 9 ? 9 : (_imageList.count + 1);
    }else {
        return 1;
    }
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    NoaComplainImageCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:NSStringFromClass([NoaComplainImageCell class]) forIndexPath:indexPath];
    cell.cellIndex = indexPath;
    cell.delegate = self;
    PHAsset *assetModel = [_imageList objectAtIndexSafe:indexPath.row];
    if (assetModel) {
        //有图片
        if (assetModel.mediaType == PHAssetMediaTypeImage) {
            [[PHImageManager defaultManager] requestImageForAsset:assetModel targetSize:PHImageManagerMaximumSize contentMode:PHImageContentModeAspectFit options:nil resultHandler:^(UIImage *resultImage, NSDictionary *info) {
                cell.ivComplain.image = resultImage;
                cell.btnDelete.hidden = NO;
            }];
        }
    }else {
        //+
        cell.ivComplain.image = ImgNamed(@"c_gray_add");
        cell.btnDelete.hidden = YES;
    }
    
    return cell;
}
#pragma mark - UICollectionViewDelegate
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    PHAsset *assetModel = [_imageList objectAtIndexSafe:indexPath.row];
    if (assetModel) return;
    //点击+
    //关闭键盘
    [self hiddenKeyBoard];
    //先检测权限，再进入相册，解决某些系统第一次不能获取照片，杀死进程后可以获取照片的问题
    WeakSelf
    [ZTOOL getPhotoLibraryAuth:^(BOOL granted) {
        if (granted) {
            [ZTOOL doInMain:^{
                NoaImagePickerVC *vc = [NoaImagePickerVC new];
                vc.maxSelectNum = 9 - weakSelf.imageList.count;
                vc.isNeedEdit = NO;
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

#pragma mark - ZComplainImageCellDelegate
- (void)cellDeleteImageWith:(NSIndexPath *)cellIndex {
    NSInteger row = cellIndex.row;
    [_imageList removeObjectAtIndexSafe:row];
    //[IMAGEPICKER.zSelectedAssets removeObjectAtIndexSafe:row];
    [_collectionView reloadData];
    _lblImageNumber.text = [NSString stringWithFormat:LanguageToolMatch(@"%d张/9"), _imageList.count];
}

#pragma mark - ZImagePickerVCDelegate
- (void)imagePickerVCSelected {
    
    //容错机制
    [IMAGEPICKER.zSelectedAssets enumerateObjectsUsingBlock:^(PHAsset * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj.mediaType != PHAssetMediaTypeImage) {
            //非图片
            [IMAGEPICKER.zSelectedAssets removeObjectAtIndexSafe:idx];
        }
    }];
    
    [_imageList addObjectsFromArray:IMAGEPICKER.zSelectedAssets];
    
//    if (_imageList.count > 9) {
//        NSRange removeRange = NSMakeRange(9, _imageList.count - 9);
//        [_imageList removeObjectsInRange:removeRange];
//        [HUD showMessage:[NSString stringWithFormat:LanguageToolMatch(@"最多只能选择%ld张照片"), 9]];
//    }
    
    _lblImageNumber.text = [NSString stringWithFormat:LanguageToolMatch(@"%d张/9"), _imageList.count];
    
    [IMAGEPICKER.zSelectedAssets removeAllObjects];
    
    //更新图片控件高度
    NSInteger totalItemCount = _imageList.count + 1;
    CGFloat imageH = DWScale(84);
    if (totalItemCount > 3 && totalItemCount < 7) {
        imageH = DWScale(84) * 2 + DWScale(6);
    } else if (totalItemCount > 6) {
        imageH = DWScale(84) * 3 + DWScale(6) * 2;
    }
    _collectionView.height = imageH;
    [self.imgContentView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.containerView);
        make.leading.equalTo(self.containerView).offset(DWScale(20));
        make.trailing.equalTo(self.containerView).offset(-DWScale(20));
        make.height.mas_equalTo(imageH + DWScale(36) + DWScale(16));
    }];
    
    [_collectionView reloadData];
    [self checkBtnSubmitEnableState];
}

#pragma mark - 选择投诉的原因
- (void)selectComplainReason {
    //关闭键盘
    [self hiddenKeyBoard];
    
    NSArray *complainList = @[
        @{
            @"comName" : LanguageToolMatch(@"发布违法有害信息"),
            @"comType" : @"1"
        },
        @{
            @"comName" : LanguageToolMatch(@"发布垃圾广告"),
            @"comType" : @"2"
        },
        @{
            @"comName" : LanguageToolMatch(@"种族歧视"),
            @"comType" : @"3"
        },
        @{
            @"comName" : LanguageToolMatch(@"存在文化歧视"),
            @"comType" : @"4"
        },
        @{
            @"comName" : LanguageToolMatch(@"辱骂骚扰"),
            @"comType" : @"5"
        },
        @{
            @"comName" : LanguageToolMatch(@"帐号可能被盗"),
            @"comType" : @"6"
        },
        @{
            @"comName" : LanguageToolMatch(@"存在欺诈行为"),
            @"comType" : @"8"
        },
        @{
            @"comName" : LanguageToolMatch(@"其他"),
            @"comType" : @"7"
        }
    ];
    
    NSMutableArray *complainItemList = [NSMutableArray array];
    
    for (NSDictionary *comDict in complainList) {
        
        NSString *complainReason = [NSString stringWithFormat:@"%@", [comDict objectForKeySafe:@"comName"]];
        
        NoaPresentItem *item = [NoaPresentItem creatPresentViewItemWithText:complainReason textColor:COLOR_11 font:FONTR(17) itemHeight:DWScale(56) backgroundColor:COLORWHITE];
        
        self.tkThemeChangeBlock = ^(id  _Nullable itself, NSUInteger themeIndex) {
            if (themeIndex == 0) {
                item.textColor = COLOR_11;
                item.backgroundColor = COLORWHITE;
            } else {
                item.textColor = COLORWHITE;
                item.backgroundColor = COLOR_11;
            }
        };
        
        [complainItemList addObjectIfNotNil:item];
    }
    
    //取消
    NoaPresentItem *cancelItem = [NoaPresentItem creatPresentViewItemWithText:LanguageToolMatch(@"取消") textColor:COLOR_99 font:FONTR(17) itemHeight:DWScale(52) backgroundColor:COLORWHITE];
    
    self.tkThemeChangeBlock = ^(id  _Nullable itself, NSUInteger themeIndex) {
        if (themeIndex == 0) {
            cancelItem.textColor = COLOR_B3B3B3;
            cancelItem.backgroundColor = COLORWHITE;
        } else {
            cancelItem.textColor = COLOR_99;
            cancelItem.backgroundColor = COLOR_11;
        }
    };
    
    WeakSelf
    NoaPresentView *viewAlert = [[NoaPresentView alloc] initWithFrame:CGRectMake(0, 0, DScreenWidth, DScreenHeight) titleItem:nil selectItems:complainItemList cancleItem:cancelItem doneClick:^(NSInteger index) {
        
        //选中的投诉原因
        NSDictionary *comDict = [complainList objectAtIndexSafe:index];
        
        weakSelf.comType = [NSString stringWithFormat:@"%@", [comDict objectForKeySafe:@"comType"]];
        
        NSString *selectedReson = [NSString stringWithFormat:@"%@", [comDict objectForKeySafe:@"comName"]];
        [weakSelf.itemContentBtn setTitle:selectedReson forState:UIControlStateNormal];
        
    } cancleClick:^{
        //取消
    }];
    
    [CurrentWindow addSubview:viewAlert];
    [viewAlert showPresentView];
}

#pragma mark - 上传图片
- (void)handleComplainImage {
    [HUD showMessage:LanguageToolMatch(@"处理中...")];
    WeakSelf
    __block NSMutableDictionary *uploadFileInfoDict = [[NSMutableDictionary alloc] init];
    dispatch_group_t myGroup = dispatch_group_create();
    for (int i = 0; i < _imageList.count; ++i) {
        dispatch_group_enter(myGroup);
        PHAsset *imageAsset = _imageList[i];
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [weakSelf handleImageToSaveSaxBoxWithAsset:imageAsset compelete:^(NSString *imagePath, NSString *imageName) {
                [uploadFileInfoDict setObjectSafe:imagePath forKey:imageName];
                dispatch_group_leave(myGroup);
            }];
        });
    }
    
    dispatch_group_notify(myGroup, dispatch_get_main_queue(), ^{
        [weakSelf uploadComplainImageWithImageInfoDict:[uploadFileInfoDict copy]];
    });
}

- (void)handleImageToSaveSaxBoxWithAsset:(PHAsset *)asset compelete:(void(^)(NSString *imagePath, NSString *imageName))compelete {
    [[PHImageManager defaultManager] requestImageForAsset:asset targetSize:PHImageManagerMaximumSize contentMode:PHImageContentModeAspectFit options:nil resultHandler:^(UIImage *resultImage, NSDictionary *info) {
        if ([[info valueForKey:@"PHImageResultIsDegradedKey"] integerValue] == 0){
            NSString *customPath = [NSString stringWithFormat:@"%@-%@", UserManager.userInfo.userUID, @"app_complain"];
            //压缩后的图
            NSData *imageData = UIImageJPEGRepresentation(resultImage, 0.5);
            //文件名
            NSString *imageName = [[NSString alloc] initWithFormat:@"%@_%lld.%@", UserManager.userInfo.userUID, [NSDate currentTimeIntervalWithMillisecond], [NSString getImageFileFormat:imageData]];
            //沙盒路径
            
            //将图片放入沙盒目录下并返回完整路径
            [NSString saveImageToSaxboxWithData:imageData CustomPath:customPath ImgName:imageName];
            NSString *imagePath = [NSString getPathWithImageName:imageName CustomPath:customPath];
            if (compelete) {
                compelete(imagePath, imageName);
            }
        }
    }];
}

- (void)uploadComplainImageWithImageInfoDict:(NSDictionary *)imgInfoDict {
    //上传操作
    if (imgInfoDict.count > 0) {
        __block NSMutableArray *uploadImgUrlArr = [[NSMutableArray alloc] init];
        __block NSMutableArray *uploadFullImgUrlArr = [[NSMutableArray alloc] init];
        __block NSInteger taskNum = 0;
        WeakSelf
        NSBlockOperation * blockOperation = [NSBlockOperation blockOperationWithBlock:^{
            NSLog(@"本次上传任务全部完成");
            StrongSelf
            for (NSString *taskId in imgInfoDict.allKeys) {
                NoaFileUploadTask *uploadTask = [[NoaFileUploadManager sharedInstance] getTaskWithId:taskId];
                if (uploadTask.status == FileUploadTaskStatus_Completed) {
                    [uploadImgUrlArr addObject:uploadTask.originUrl];
                    [uploadFullImgUrlArr addObjectIfNotNil:[uploadTask.originUrl getImageFullString]];
                    taskNum++;
                }
                if (uploadTask.status == FileUploadTaskStatus_Failed) {
                    [ZTOOL doInMain:^{
                        [HUD showMessage:LanguageToolMatch(@"上传图片失败")];
                        return;
                    }];
                }
                if (taskNum == imgInfoDict.allKeys.count) {
                    strongSelf.comImages = [uploadImgUrlArr componentsJoinedByString:@","];
                    strongSelf.comFullImages = [uploadFullImgUrlArr componentsJoinedByString:@","];
                    [ZTOOL doInMain:^{
                        [HUD hideHUD];
                        [HUD showMessage:LanguageToolMatch(@"处理中...")];
                        [strongSelf requestComplainSubmit];
                    }];
                }
            }
        }];
        
        NoaFileUploadGetSTSTask *getSTSTask = [[NoaFileUploadGetSTSTask alloc] init];
        [[NoaFileUploadManager sharedInstance].operationQueue addOperation:getSTSTask];

        for (NSString *imageName in imgInfoDict.allKeys) {
            NSString *imagePath = (NSString *)[imgInfoDict objectForKey:imageName];
            NSData *imageData = [NSData dataWithContentsOfFile:imagePath];
            NoaFileUploadTask *task = [[NoaFileUploadTask alloc] initWithTaskId:imageName filePath:imagePath originFilePath:@"" fileName:imageName fileType:@"" isEncrypt:YES dataLength:imageData.length uploadType:ZHttpUploadTypeUniversal beSendMessage:nil delegate:nil];
            [task addDependency:getSTSTask];
            [blockOperation addDependency:task];
            [[NoaFileUploadManager sharedInstance] addUploadTask:task];
        }
        [[NoaFileUploadManager sharedInstance].operationQueue addOperation:blockOperation];
    } else {
        [HUD hideHUD];
    }
}

#pragma mark - 检查按钮交互状态
- (void)checkBtnSubmitEnableState{
    //邮箱格式验证
    BOOL emailOK = NO;
    NSString *emailStr = [self.emailTextField.text trimString];
    NSString *emailRegex = @"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}";
    NSPredicate *emailPredicate = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegex];
    if ([emailPredicate evaluateWithObject:emailStr]) {
        emailOK = YES;
    }
    
    //提交按钮交互验证
    if (_imageList.count > 0 && emailOK) {
        _btnSubmit.enabled = YES;
    }else {
        _btnSubmit.enabled = NO;
    }
    
    if (_btnSubmit.isEnabled) {
        [_btnSubmit setTkThemebackgroundColors:@[COLOR_5966F2, COLOR_5966F2_DARK]];
    }else {
        [_btnSubmit setTkThemebackgroundColors:@[[COLOR_5966F2 colorWithAlphaComponent:0.3], [COLOR_5966F2_DARK colorWithAlphaComponent:0.3]]];
    }
}

#pragma mark - 确认提交投诉 交互
- (void)btnSubmitClick {
    if (_btnSubmit.isEnabled) {
        //先上传图片
        [self handleComplainImage];
    }
}

//请求提交投诉信息
- (void)requestComplainSubmit {
    if (_complainVCType == ZComplainTypeSystem) {
        //系统投诉
        [self requestComplainSubmitForSystem];
    }else if (_complainVCType == ZComplainTypeDomain) {
        //企业号/域名
        [self requestComplainSubmitForCompany];
    }
}

#pragma mark - 投诉与支持接口 (系统投诉)
- (void)requestComplainSubmitForSystem {
    if ([NSString isNil:_comImages]) {
        [HUD showMessage:LanguageToolMatch(@"操作失败")];
        return;
    }
    
    _comContent = [self.contentTextView.text trimString];
    _comEmail = [self.emailTextField.text trimString];
    _comCompany = @"";//[self.domainTextField.text trimString];
    
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    [dict setValue:UserManager.userInfo.userUID forKey:@"userUid"];//反馈人ID
    [dict setValue:UserManager.userInfo.nickname forKey:@"nickname"];//反馈人昵称
    [dict setValue:_comImages forKey:@"ufbImages"];//投诉图片(必填)
    [dict setValue:_comType forKey:@"ufbContentGroup"];//投诉类型(默认1)
    if (![NSString isNil:_comContent]) {
        [dict setValue:_comContent forKey:@"ufbComment"];//投诉内容
    }
    if (![NSString isNil:_comEmail]) {
        [dict setValue:_comEmail forKey:@"ufbUserEmail"];//反馈人邮箱
    }
    if (![NSString isNil:_comCompany]) {
        [dict setValue:_comCompany forKey:@"ufbTo"];//投诉企业号
    }
    if (![NSString isNil:_complainID]) {
        if (_complainType == CIMChatType_SingleChat) {
            //单聊 人
            [dict setValue:@"0" forKey:@"ufbToType"];//投诉用户
            [dict setValue:_complainID forKey:@"ufbToUserId"];//被投诉用户ID
        } else if (_complainType == CIMChatType_GroupChat) {
            //群聊 群组
            [dict setValue:@"1" forKey:@"ufbToType"];//投诉群组
            [dict setValue:_complainID forKey:@"ufbToGroupId"];//被投诉群组ID
        }
    } else {
        [dict setValue:@"3" forKey:@"ufbToType"];//我的-投诉与支持
    }
    
    WeakSelf
    [IMSDKManager userAddFeedBackWith:dict onSuccess:^(id _Nullable data, NSString * _Nullable traceId) {
        [HUD showMessage:LanguageToolMatch(@"操作成功")];
        [weakSelf.navigationController popViewControllerAnimated:YES];
    } onFailure:^(NSInteger code, NSString * _Nullable msg, NSString * _Nullable traceId) {
        [HUD showMessageWithCode:code errorMsg:msg];
    }];
}

#pragma mark - 投诉与支持接口 (企业号/域名)
- (void)requestComplainSubmitForCompany {
    
    if ([NSString isNil:_comImages]) {
        [HUD showMessage:LanguageToolMatch(@"操作失败")];
        return;
    }
    
    _comContent = [self.contentTextView.text trimString];
    _comEmail = [self.emailTextField.text trimString];
    //自动填充 企业号/域名
    NoaSsoInfoModel *ssoModel = [NoaSsoInfoModel getSSOInfo];
    if (![NSString isNil:ssoModel.liceseId]) {
        //企业号
        _comCompany = [ssoModel.liceseId trimString];
    }
    if (![NSString isNil:ssoModel.ipDomainPortStr]) {
        // IP/Doamin
        _comCompany = [ssoModel.ipDomainPortStr trimString];;
    }
    
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    [dict setValue:UserManager.userInfo.userUID forKey:@"userUid"];//反馈人ID
    [dict setValue:UserManager.userInfo.nickname forKey:@"nickname"];//反馈人昵称
    [dict setValue:_comFullImages forKey:@"ufbImages"];//投诉图片(必填)
    [dict setValue:_comType forKey:@"ufbContentGroup"];//投诉类型(默认1)
    if (![NSString isNil:_comContent]) {
        [dict setValue:_comContent forKey:@"ufbComment"];//投诉内容
    }
    if (![NSString isNil:_comEmail]) {
        [dict setValue:_comEmail forKey:@"ufbUserEmail"];//反馈人邮箱
    }
    if (![NSString isNil:_comCompany]) {
        [dict setValue:_comCompany forKey:@"ufbTo"];//投诉企业号
    }
    if (![NSString isNil:_complainID]) {
        if (_complainType == CIMChatType_SingleChat) {
            //单聊 人
            [dict setValue:@"0" forKey:@"ufbToType"];//投诉用户
            [dict setValue:_complainID forKey:@"ufbToUserId"];//被投诉用户ID
        } else if (_complainType == CIMChatType_GroupChat) {
            //群聊 群组
            [dict setValue:@"1" forKey:@"ufbToType"];//投诉群组
            [dict setValue:_complainID forKey:@"ufbToGroupId"];//被投诉群组ID
        }
    } else {
        [dict setValue:@"3" forKey:@"ufbToType"];//我的-投诉与支持
    }
    [dict setValue:@"alex" forKey:@"productCode"];//投诉来源App
    
    //根据后端返回的配置信息里的环境信息，调用不同环境下的 企业号投诉url的域名
    NSString *urlHostStr = complainBaseurl;
    WeakSelf
    [IMSDKHTTPTOOL netRequestWorkCommonBaseUrl:urlHostStr Path:@"/feedback/addFeedBack" medth:LingIMHttpRequestTypePOST parameters:dict onSuccess:^(id _Nullable data, NSString * _Nullable traceId) {
        [HUD showMessage:LanguageToolMatch(@"操作成功")];
        [weakSelf.navigationController popViewControllerAnimated:YES];
    } onFailure:^(NSInteger code, NSString * _Nullable msg, NSString * _Nullable traceId) {
        [HUD showMessageWithCode:code errorMsg:msg];
    }];
    
}


//隐藏键盘
- (void)hiddenKeyBoard {
    [self.contentTextView resignFirstResponder];
    [self.emailTextField resignFirstResponder];
}
#pragma mark - 清空界面上的内容
- (void)clearUIContent {
    //图片
    [IMAGEPICKER.zSelectedAssets removeAllObjects];
    [_imageList removeAllObjects];
    _lblImageNumber.text = [NSString stringWithFormat:LanguageToolMatch(@"%d张/9"), 0];
    [_collectionView reloadData];
    //投诉内容
    self.contentTextView.text = @"";
    self.contentTextNumLbl.text = @"0/200";
    //投诉类型 默认1
    self.comType = @"1";
    [self.itemContentBtn setTitle:LanguageToolMatch(@"发布违法有害信息") forState:UIControlStateNormal];
    //邮箱
    self.emailTextField.text = @"";
    //提交按钮
    _btnSubmit.enabled = NO;
    [_btnSubmit setTkThemebackgroundColors:@[[COLOR_5966F2 colorWithAlphaComponent:0.3], [COLOR_5966F2_DARK colorWithAlphaComponent:0.3]]];
}
#pragma mark - 实时监听邮箱的输入值
- (void)emailTextFieldChanged:(UITextField *)tfEmail {
    if ([tfEmail isEqual:self.emailTextField]) {
        [self checkBtnSubmitEnableState];
    }
}
#pragma mark - Lazy
- (UIScrollView *)contentScroll {
    if (!_contentScroll) {
        _contentScroll = [[UIScrollView alloc] init];
        _contentScroll.tkThemebackgroundColors = @[COLORWHITE, COLORWHITE_DARK];
    }
    return _contentScroll;
}

- (UIView *)containerView {
    if (!_containerView) {
        _containerView = [[UIView alloc] init];
        _containerView.tkThemebackgroundColors = @[COLORWHITE, COLORWHITE_DARK];
    }
    return _containerView;
}
- (UIView *)imgContentView {
    if (!_imgContentView) {
        _imgContentView = [[UIView alloc] init];
        _imgContentView.tkThemebackgroundColors = @[COLORWHITE, COLORWHITE_DARK];
    }
    return _imgContentView;
}
- (UIView *)textContentView {
    if (!_textContentView) {
        _textContentView = [[UIView alloc] init];
        _textContentView.tkThemebackgroundColors = @[COLORWHITE, COLORWHITE_DARK];
    }
    return _textContentView;
}

- (UITextView *)contentTextView {
    if (!_contentTextView) {
        _contentTextView = [[UITextView alloc] init];
        _contentTextView.attributedPlaceholder = [[NSAttributedString alloc]initWithString:LanguageToolMatch(@"请输入投诉内容")];
        _contentTextView.placeholderColor = COLOR_99;
        _contentTextView.font = FONTN(12);
        _contentTextView.delegate = self;
    }
    return _contentTextView;
}

- (UILabel *)contentTextNumLbl {
    if (!_contentTextNumLbl) {
        _contentTextNumLbl = [[UILabel alloc] init];
        _contentTextNumLbl.text = @"0/200";
        _contentTextNumLbl.font = FONTN(12);
        _contentTextNumLbl.tkThemetextColors = @[COLOR_99, COLOR_99_DARK];
        _contentTextNumLbl.textAlignment = NSTextAlignmentRight;
    }
    return _contentTextNumLbl;
}

- (UIView *)itemContentView {
    if (!_itemContentView) {
        _itemContentView = [[UIView alloc] init];
    }
    return _itemContentView;
}

- (UIButton *)itemContentBtn {
    if (!_itemContentBtn) {
        _itemContentBtn = [[UIButton alloc] init];
        [_itemContentBtn setTitle:LanguageToolMatch(@"发布违法有害信息") forState:UIControlStateNormal];
        [_itemContentBtn setTkThemeTitleColor:@[COLOR_00, COLOR_00_DARK] forState:UIControlStateNormal];
        _itemContentBtn.titleLabel.font = FONTB(12);
        if(ZLanguageTOOL.isRTL){
            _itemContentBtn.contentHorizontalAlignment = UIControlContentHorizontalAlignmentRight;
        }else{
            _itemContentBtn.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
        }
        [_itemContentBtn addTarget:self action:@selector(selectComplainReason) forControlEvents:UIControlEventTouchUpInside];
    }
    return _itemContentBtn;
}

- (UITextField *)emailTextField {
    if (!_emailTextField) {
        _emailTextField = [[UITextField alloc] init];
        _emailTextField.attributedPlaceholder =[[NSAttributedString alloc]initWithString:LanguageToolMatch(@"请输入您的邮箱")];
        _emailTextField.tkThemetextColors = @[COLOR_99, COLOR_99_DARK];
        _emailTextField.font = FONTN(12);
        [_emailTextField addTarget:self action:@selector(emailTextFieldChanged:) forControlEvents:UIControlEventEditingChanged];
    }
    return _emailTextField;
}

- (UIView *)domainBackView {
    if (!_domainBackView) {
        _domainBackView = [[UIView alloc] init];
        _domainBackView.tkThemebackgroundColors = @[COLOR_F5F6F9, COLOR_F5F6F9_DARK];
        [_domainBackView rounded:DWScale(8)];
    }
    return _domainBackView;
}

- (UITextField *)domainTextField {
    if (!_domainTextField) {
        _domainTextField = [[UITextField alloc] init];
        _domainTextField.placeholder = LanguageToolMatch(@"请输入企业号/域名");
        _domainTextField.tkThemetextColors = @[COLOR_99, COLOR_99_DARK];
        _domainTextField.font = FONTN(12);
        
        NoaSsoInfoModel *ssoModel = [NoaSsoInfoModel getSSOInfo];
        if (![NSString isNil:ssoModel.liceseId]) {
            //企业号
            _domainTextField.text = [NSString stringWithFormat:@"%@：%@", LanguageToolMatch(@"企业号"), ssoModel.liceseId];
        }
        if (![NSString isNil:ssoModel.ipDomainPortStr]) {
            // IP/Doamin
            _domainTextField.text = [NSString stringWithFormat:@"%@：%@", LanguageToolMatch(@"域名"), ssoModel.ipDomainPortStr];
        }
        _domainTextField.userInteractionEnabled = NO;
    }
    return _domainTextField;
}

//- (ZFileNetProgressManager *)fileUploader {
//    if (!_fileUploader) {
//        _fileUploader = [[ZFileNetProgressManager alloc] init];
//    }
//    return _fileUploader;
//}

- (void)dealloc {
    [IMAGEPICKER.zSelectedAssets removeAllObjects];
}
@end
