//
//  ZWWebViewVC.m
//  ZWWKWebView
//
//  Created by 郑亚伟 on 2017/3/12.
//  Copyright © 2017年 zhengyawei. All rights reserved.
//

#import "ZWWebViewVC.h"
#import <WebKit/WebKit.h>
#import "TestViewController.h"

@interface ZWWebViewVC ()<WKNavigationDelegate,UIGestureRecognizerDelegate,UIScrollViewDelegate>
@property  (nonatomic,strong) WKWebView *webView;

//进度条
@property(nonatomic,strong) UIView *progressView;
@property (nonatomic,strong) CALayer *progresslayer;

//返回按钮
@property (nonatomic, strong) UIButton * backItem;
//关闭按钮
@property (nonatomic, strong) UIButton * closeItem;

//预览图片相关
//遮罩
@property(nonatomic,strong)UIView *maskView;
//用于添加缩放手势和显示长图
@property(nonatomic,strong)UIScrollView *scrollView;
//展示图片
@property(nonatomic,strong)UIImageView *webImageView;

@property(nonatomic,assign)CGFloat totalScale;
@end

@implementation ZWWebViewVC
#pragma mark - lifeCycle
- (void)viewDidLoad {
    [super viewDidLoad];
    _totalScale = 1.0;
    self.view.backgroundColor = [UIColor whiteColor];
    self.automaticallyAdjustsScrollViewInsets = NO;
    [self.view addSubview:self.webView];
    [self.progressView.layer addSublayer:self.progresslayer];
    //设置导航栏item样式
    [self setupNavbarItem];
}
- (void)dealloc{
    [self.webView removeObserver:self forKeyPath:@"estimatedProgress"];
}

#pragma mark - Action
//返回按钮点击事件
- (void)clickedBackItem:(UIBarButtonItem *)btn{
    if (self.webView.canGoBack) {
        [self.webView goBack];
        self.closeItem.hidden = NO;
    }else{
        [self clickedCloseItem:nil];
    }
}
//关闭按钮点击事件
- (void)clickedCloseItem:(UIButton *)btn{
    [self.navigationController popViewControllerAnimated:YES];
}
//长按手势(保存图片到相册)
- (void)longPressed:(UILongPressGestureRecognizer *)longPress{
   
}
- (void)pinchGesture:(UIPinchGestureRecognizer*)pg{
    //变化的尺寸
    CGFloat scale = pg.scale;
    CGFloat temp = _totalScale + (scale - 1.0);
    [self setTotalScale:temp];
    
    //采用上面方法，改变尺寸存在累加效果，需要scale设置为1
    pg.scale = 1.0;
}
- (void)setTotalScale:(CGFloat)totalScale{
    //在0.7-2倍之间变化
    if ((_totalScale < 0.7 && totalScale < _totalScale) || (_totalScale > 2.0 && totalScale > _totalScale)){
        return;
    }
    _totalScale = totalScale;
    _webImageView.transform = CGAffineTransformMakeScale(_totalScale, _totalScale);
    // _panoView.transform = CGAffineTransformScale(_panoView.transform, _totalScale, _totalScale);
}



#pragma mark -设置进度条进度
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context{
    if ([keyPath isEqualToString:@"estimatedProgress"]) {
        self.progresslayer.opacity = 1;
        self.progresslayer.frame = CGRectMake(0, 0, self.view.bounds.size.width * [change[NSKeyValueChangeNewKey] floatValue], 3);
        if ([change[NSKeyValueChangeNewKey] floatValue] == 1) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                self.progresslayer.opacity = 0;
            });
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(.8 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                self.progresslayer.frame = CGRectMake(0, 0, 0, 3);
            });
        }
    }else{
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

#pragma mark -WKNavigationDelegate 网页代理
//拦截网页加载，主动发送请求
- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler{
    
    NSString *requestString = navigationAction.request.URL.absoluteString;
    if ([requestString hasPrefix:@"myweb:imageClick:"]) {
        //获取单个照片地址
        NSString *imageUrl = [requestString substringFromIndex:@"myweb:imageClick:".length];
        //这里可以继续做一个简单的判断，如果图片网址是以gif结尾，可以用SDWebImage来加载gif图片
        [self showImageWithUrlString:imageUrl];
        
        decisionHandler(WKNavigationActionPolicyCancel);
    }else{
        //如果网页进入下一页面，显示返回按钮
        if (self.webView.canGoBack) {
            self.closeItem.hidden = NO;
        }else{//网页处于第一页面，隐藏返回按钮
            self.closeItem.hidden = YES;
        }
        //这个参数必须调用，类似于UIWebView开始加载的时候，返回的YES
        decisionHandler(WKNavigationActionPolicyAllow);
    }
}
//网页加载完成  注入js
- (void)webView:(WKWebView *)webView didFinishNavigation:(null_unspecified WKNavigation *)navigation{
    //拼接js的代码
    NSMutableString *stringM  = [NSMutableString string];
    //添加移除导航的js
    [stringM appendString:@"var headerTag = document.getElementsByTagName(\"header\")		[0];headerTag.parentNode.removeChild(headerTag);"];
    //添加移除橙色按钮的js
    [stringM appendString:@"var footerBtnTag = document.getElementsByClassName(\"footer-btn-fix\")[0]; footerBtnTag.parentNode.removeChild(footerBtnTag);"];
    //添加移除网页底部电脑版的js
    [stringM appendString:@"var footer = document.getElementsByClassName('footer')[0]; footer.parentNode.removeChild(footer);"];
    
    //和预览图片相关的JS
    //要加上这两句代码   否则网页图片不显示，仅显示蓝色小标记
    [stringM appendString:@"document.getElementsByTagName('body')[0].style.webkitTextSizeAdjust= '95%';"];
    [stringM appendString:@"function getImages(){var objs = document.getElementsByTagName(\"img\");for(var i=0;i<objs.length;i++){objs[i].onclick=function(){document.location=\"myweb:imageClick:\"+this.src;};};return objs.length;};"];
   //注入JS
    //[webView stringByEvaluatingJavaScriptFromString:stringM];//UIWebView   UIWebView的注入方式
    [webView evaluateJavaScript:stringM completionHandler:nil];
    //注入自定义的js方法后别忘了调用 否则不会生效
    [webView evaluateJavaScript:@"getImages();" completionHandler:nil];
}
//网页已经开始加载调用
- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(null_unspecified WKNavigation *)navigation{
    
}
//页面加载失败调用
- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(null_unspecified WKNavigation *)navigation withError:(NSError *)error{
}
//当内容开始返回时调用，即服务器已经在想客服端发送网页数据
- (void)webView:(WKWebView *)webView didCommitNavigation:(null_unspecified WKNavigation *)navigation{
}




#pragma mark - Private
//设置导航栏Item
- (void)setupNavbarItem{
    UIView * backView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, 100, 44)];
    UIButton * backItem = [[UIButton alloc]initWithFrame:CGRectMake(0, 0, 56, 44)];
    [backItem setImage:[UIImage imageNamed:@"back_arrow"] forState:UIControlStateNormal];
    [backItem setImageEdgeInsets:UIEdgeInsetsMake(0, -15, 0, 0)];
    [backItem setTitle:@"返回" forState:UIControlStateNormal];
    [backItem setTitleEdgeInsets:UIEdgeInsetsMake(0, -15, 0, 0)];
    [backItem setTitleColor:[UIColor colorWithRed:0.000 green:0.502 blue:1.000 alpha:1.000] forState:UIControlStateNormal];
    [backItem addTarget:self action:@selector(clickedBackItem:) forControlEvents:UIControlEventTouchUpInside];
    self.backItem = backItem;
    [backView addSubview:backItem];
    
    UIButton * closeItem = [[UIButton alloc]initWithFrame:CGRectMake(44+12, 0, 44, 44)];
    [closeItem setTitle:@"关闭" forState:UIControlStateNormal];
    [closeItem setTitleColor:[UIColor colorWithRed:0.000 green:0.502 blue:1.000 alpha:1.000] forState:UIControlStateNormal];
    [closeItem addTarget:self action:@selector(clickedCloseItem:) forControlEvents:UIControlEventTouchUpInside];
    closeItem.hidden = YES;
    self.closeItem = closeItem;
    [backView addSubview:closeItem];
    
    UIBarButtonItem * leftItemBar = [[UIBarButtonItem alloc]initWithCustomView:backView];
    self.navigationItem.leftBarButtonItem = leftItemBar;
}
//显示照片
- (void)showImageWithUrlString:(NSString *)urlString{
    [[UIApplication sharedApplication].keyWindow addSubview:self.maskView];
    [self.maskView addSubview:self.scrollView];
    [self.scrollView addSubview:self.webImageView];
    self.webImageView.image = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:urlString]]];
}
//点击预览中的图片，结束预览
- (void)removeBigImage{
    [self.maskView removeFromSuperview];
}


#pragma mark - 懒加载
- (WKWebView *)webView{
    if (_webView == nil) {
        _webView = [[WKWebView alloc]initWithFrame:CGRectMake(0, 63, self.view.frame.size.width, self.view.frame.size.height - 64)];
        //http://m.dianping.com/tuan/deal/5501525
        //http://dantang.liwushuo.com/posts/3121/content 这个网址无法进入下一页？？？？？？
        //http://www.jianshu.com/p/0e49fa89a2d2
        [_webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"http://www.jianshu.com/u/4a57fb76690f"]]];
        /*****************注**********************/
        _webView.navigationDelegate = self;
        //添加进度属性监听
        [_webView addObserver:self forKeyPath:@"estimatedProgress" options:NSKeyValueObservingOptionNew context:nil];
        //网页添加长按手势
        UILongPressGestureRecognizer* longPressed = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressed:)];
        longPressed.delegate = self;
        [_webView addGestureRecognizer:longPressed];
    }
    return _webView;
}
//显示进度相关
- (UIView *)progressView{
    if (_progressView == nil) {
        //进度条
        _progressView = [[UIView alloc]initWithFrame:CGRectMake(0, 64, CGRectGetWidth(self.view.frame), 3)];
        _progressView.backgroundColor = [UIColor clearColor];
        [self.view addSubview:_progressView];
    }
    return _progressView;
}
- (CALayer *)progresslayer{
    if (_progresslayer == nil) {
        _progresslayer = [CALayer layer];
        _progresslayer.frame = CGRectMake(0, 0, 0, 3);
        _progresslayer.backgroundColor = [UIColor blueColor].CGColor;
    }
    return _progresslayer;
}
//预览图片相关
- (UIView *)maskView{
    if (_maskView == nil) {
        _maskView = [[UIView alloc]initWithFrame:self.view.bounds];
        _maskView.backgroundColor = [UIColor colorWithRed:0.3 green:0.3 blue:0.3 alpha:0.9];
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(removeBigImage)];
        [_maskView addGestureRecognizer:tap];
    }
    return _maskView;
}
- (UIScrollView *)scrollView{
    if (_scrollView == nil) {
        _scrollView = [[UIScrollView alloc]initWithFrame:self.view.frame];
        _scrollView.showsHorizontalScrollIndicator = NO;
        _scrollView.showsVerticalScrollIndicator = NO;
        _scrollView.bounces = NO;
        _scrollView.delegate = self;
        [_scrollView setMinimumZoomScale:0.5];
        [_scrollView setMaximumZoomScale:2];
    }
    return _scrollView;
}
- (UIImageView *)webImageView{
    if (_webImageView == nil) {
        _webImageView = [[UIImageView alloc]initWithFrame:self.view.frame];
        _webImageView.userInteractionEnabled = YES;
        _webImageView.contentMode = UIViewContentModeScaleAspectFit;
        _webImageView.userInteractionEnabled = YES;
        UIPinchGestureRecognizer *pinch = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(pinchGesture:)];
        [_webImageView addGestureRecognizer:pinch];
    }
    return _webImageView;
}

@end
