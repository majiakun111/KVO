//
//  SubViewController.m
//  KVO
//
//  Created by Ansel on 16/6/19.
//  Copyright © 2016年 Ansel. All rights reserved.
//

#import "SubViewController.h"
#import "NSObject+KVO.h"

@implementation SubViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    [self.person addObserveForKey:@"name" block:^(id observer, NSString *key, id oldValue, id newValue) {
        
    }];
    
    [self.person addObserveForKey:@"address" block:^(id object, NSString *key, id oldValue, id newValue) {
        
    }];
}

-(void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    self.person.name = @"Ansel";
    self.person.address = @"SZ";
}

@end
