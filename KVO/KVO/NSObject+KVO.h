//
//  NSObject+KVO.h
//  KVO
//
//  Created by Ansel on 16/6/18.
//  Copyright © 2016年 Ansel. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void(^ObserverBlock)(id object, NSString *key, id oldValue, id newValue);

@interface NSObject (KVO)

////TODO: 暂不支持  a.b.c
- (void)addObserver:(NSObject *)observer forKey:(NSString *)key block:(ObserverBlock)block;

- (void)removeObserver:(NSObject *)observer forKey:(NSString *)key;

@end
