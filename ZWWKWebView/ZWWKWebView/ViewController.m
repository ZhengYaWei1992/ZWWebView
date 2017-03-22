//
//  ViewController.m
//  ZWWKWebView
//
//  Created by 郑亚伟 on 2017/3/12.
//  Copyright © 2017年 zhengyawei. All rights reserved.
//

#import "ViewController.h"
#import "ZWWebViewVC.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    [btn setBackgroundColor:[UIColor redColor]];
    btn.titleLabel.font = [UIFont systemFontOfSize:12];
    btn.frame = CGRectMake(0, 100 , self.view.frame.size.width , 40);
    [btn setTitle:@"点击进入(关闭、进度、浏览和保存图片)" forState:UIControlStateNormal];
    [btn addTarget:self action:@selector(btnClick:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn];
}

- (void)btnClick:(UIButton *)btn{
    ZWWebViewVC *vc = [[ZWWebViewVC alloc]init];
    [self.navigationController pushViewController:vc animated:YES];
}

@end
