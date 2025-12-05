//
//  NoaComplainVC.m
//  NoaKit
//
//  Created by Mac on 2023/6/19.
//

#import "NoaComplainVC.h"
#import <JXCategoryView/JXCategoryView.h>
#import "NoaScrollView.h"
#import "NoaComplainFromVC.h"

@interface NoaComplainVC ()<JXCategoryViewDelegate,UIScrollViewDelegate>

@property (nonatomic, strong) JXCategoryTitleView *viewCategory;
@property (nonatomic, strong) NoaScrollView *scrollView;
@property (nonatomic, strong) NoaComplainFromVC *systemComplainVC;    //系统投诉
@property (nonatomic, strong) NoaComplainFromVC *domainComplainVC;    //企业号、域名投诉
@property (nonatomic, assign) NSInteger currentSelectedIndex;//当前选中下标

@end

@implementation NoaComplainVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.tkThemebackgroundColors = @[COLOR_F5F6F9, COLOR_11];
    self.navView.tkThemebackgroundColors = @[COLOR_F5F6F9, COLOR_11];
    [self setupUI];
}

#pragma mark - 界面布局
- (void)setupUI {
    UILabel *titleLbl = [[UILabel alloc] initWithFrame:CGRectMake(DWScale(25), DNavStatusBarH + DWScale(10), DScreenWidth - DWScale(25)*2, DWScale(20))];
    titleLbl.text = LanguageToolMatch(@"投诉与支持");
    titleLbl.tkThemetextColors = @[COLOR_11, COLOR_11_DARK];
    titleLbl.font = FONTB(18);
    [self.view addSubview:titleLbl];
    
    _viewCategory = [[JXCategoryTitleView alloc] initWithFrame:CGRectMake(0, DNavStatusBarH + DWScale(10) + DWScale(20) + DWScale(10) , DScreenWidth, DWScale(45))];
    _viewCategory.delegate = self;
    _viewCategory.titles = @[LanguageToolMatch(@"系统投诉"),[NSString stringWithFormat:@"%@/%@",LanguageToolMatch(@"企业号"),LanguageToolMatch(@"IP/域名")]];
    _viewCategory.titleColorGradientEnabled = YES;
    _viewCategory.titleLabelZoomScale = YES;
    _viewCategory.titleFont = FONTB(16);
    _viewCategory.titleLabelZoomScale = 1.0;
    WeakSelf
    self.view.tkThemeChangeBlock = ^(id  _Nullable itself, NSUInteger themeIndex) {
        switch (themeIndex) {
            case 1:
            {
                //暗黑
                weakSelf.viewCategory.titleColor = COLOR_66_DARK;
                weakSelf.viewCategory.titleSelectedColor = COLOR_5966F2;
            }
                break;
                
            default:
            {
                weakSelf.viewCategory.titleColor = COLOR_66;
                weakSelf.viewCategory.titleSelectedColor = COLOR_5966F2;
            }
                break;
        }
    };
    
    //指示器
    JXCategoryIndicatorLineView *lineView = [[JXCategoryIndicatorLineView alloc] init];
    lineView.indicatorColor = COLOR_5966F2;
    lineView.componentPosition = JXCategoryComponentPosition_Bottom;
    lineView.verticalMargin = 0;
    _viewCategory.indicators = @[lineView];
    
    _scrollView = [[NoaScrollView alloc] initWithFrame:CGRectMake(0, DNavStatusBarH + DWScale(10) + DWScale(20) + DWScale(10) + DWScale(45), DScreenWidth, DScreenHeight - DNavStatusBarH - DWScale(10) - DWScale(20) - DWScale(10) - DWScale(45))];
    _scrollView.delegate = self;
    _scrollView.pagingEnabled = YES;
    _scrollView.showsVerticalScrollIndicator = NO;
    _scrollView.showsHorizontalScrollIndicator = NO;
    _scrollView.delaysContentTouches = NO;
    _scrollView.contentSize = CGSizeMake(DScreenWidth * 2, 0);
    _scrollView.bounces = NO;
    
    [self.view addSubview:self.viewCategory];
    [self.view addSubview:self.scrollView];
    self.viewCategory.contentScrollView = self.scrollView;
    
    _systemComplainVC = [[NoaComplainFromVC alloc] init];
    _systemComplainVC.view.frame = CGRectMake(0, 0, DScreenWidth, _scrollView.height);
    _systemComplainVC.complainVCType = ZComplainTypeSystem;
    _systemComplainVC.complainID = _complainID;
    _systemComplainVC.complainType = _complainType;
    [self addChildViewController:_systemComplainVC];
    [self.scrollView addSubview:_systemComplainVC.view];
    
    _domainComplainVC = [[NoaComplainFromVC alloc] init];
    _domainComplainVC.view.frame = CGRectMake(DScreenWidth, 0, DScreenWidth, _scrollView.height);
    _domainComplainVC.complainVCType = ZComplainTypeDomain;
    _domainComplainVC.complainID = _complainID;
    _domainComplainVC.complainType = _complainType;
    [self addChildViewController:_domainComplainVC];
    [self.scrollView addSubview:_domainComplainVC.view];
    
    _currentSelectedIndex = 0;
}

#pragma mark - JXCategoryViewDelegate
//选中某个下标
- (void)categoryView:(JXCategoryBaseView *)categoryView didSelectedItemAtIndex:(NSInteger)index {
    if (_currentSelectedIndex == index) {
        //点击的同一个下标
    }else {
        //切换选中下标
        if (_currentSelectedIndex == 0) {
            //清空系统投诉界面内容
            //[_systemComplainVC clearUIContent];
        }else {
            //清空企业号界面内容
            //[_domainComplainVC clearUIContent];
        }
    }
    _currentSelectedIndex = index;
}
@end
