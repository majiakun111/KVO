//
//  ViewController.m
//  KVO
//
//  Created by Ansel on 16/6/17.
//  Copyright © 2016年 Ansel. All rights reserved.
//

#import "ViewController.h"
#import "NSObject+KVO.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    _person = [[Person alloc] init];
    
    [self.person addObserveForKey:@"name" block:^(id observer, NSString *key, id oldValue, id newValue) {
        
    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
