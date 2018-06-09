//
//  ViewController.m
//  Ping
//
//  Created by dazhou on 2018/6/9.
//  Copyright © 2018年 dazhou. All rights reserved.
//

#import "ViewController.h"
#import "NetworkMonitorManager.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [[NetworkMonitorManager shareInstance] startMonitorAction:@"www.baidu.com"];
    // Do any additional setup after loading the view, typically from a nib.
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
