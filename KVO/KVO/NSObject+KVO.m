//
//  NSObject+KVO.m
//  KVO
//
//  Created by Ansel on 16/6/18.
//  Copyright © 2016年 Ansel. All rights reserved.
//

#import "NSObject+KVO.h"
#import <objc/runtime.h>
#import <objc/message.h>

NSString *const kKVOClassPrefix = @"KVOClassPrefix_";
static NSString *kKVOAssociatedObservationInfos = nil;

@interface ObservationInfo : NSObject

@property (nonatomic, weak) id observer;
@property (nonatomic, copy) NSString *key;
@property (nonatomic, copy) ObserverBlock block;

@end

@implementation ObservationInfo

- (instancetype)initWithObserver:(id)observer key:(NSString *)key block:(ObserverBlock)block
{
    self = [super init];
    if (self) {
        _observer = observer;
        _key = key;
        _block = block;
    }
    
    return self;
}

@end

@implementation NSObject (KVO)
/**
 *  1. 通过key获取set方法
 *  2. 创建observer class的子类subclass, 给subclass添加set方法
 *  3. 交换subclass的class方法  让调用class方法返回 observer clas
 *  4. 把observer class 设成subclass
 *  5. 构建ObservationInfo，存储ObservationInfo
 *
 *  @param observer observer
 *  @param key      key
 *  @param block    block
 */

- (void)addObserver:(NSObject *)observer forKey:(NSString *)key block:(ObserverBlock)block
{
    //1.
    NSString *setterName = setterForGetter(key);
    SEL setterSelector = NSSelectorFromString(setterName);
    Method setterMethod = class_getInstanceMethod([self class], setterSelector);
    if (!setterMethod) {
        NSLog(@"%@ not implement %@", [self class], setterName);
        return;
    }
    
    //2.
    Class clazz = object_getClass(self);
    NSString *clazzName = NSStringFromClass(clazz);
    if (![clazzName hasPrefix:kKVOClassPrefix]) {
        clazz = [self makeKVOClassWithClassName:clazzName];
        
        const char *types = method_getTypeEncoding(setterMethod);
        class_addMethod(clazz, setterSelector, (IMP)kvo_setter, types);
        
        //4.
        object_setClass(self, clazz);
    }
    
    //5
    ObservationInfo *observationInfo = [[ObservationInfo alloc] initWithObserver:observer key:key block:block];
    NSMutableArray *observerInfos = objc_getAssociatedObject(self, &kKVOAssociatedObservationInfos);
    if (!observerInfos) {
        observerInfos = [NSMutableArray array];
        objc_setAssociatedObject(self,  &kKVOAssociatedObservationInfos, observerInfos, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    [observerInfos addObject:observationInfo];
}

- (void)removeObserver:(NSObject *)observer forKey:(NSString *)key
{
    NSMutableArray* observers = objc_getAssociatedObject(self, &kKVOAssociatedObservationInfos);
    
    ObservationInfo *observationInfo;
    for (ObservationInfo* info in observers) {
        if (info.observer == observer && [info.key isEqual:key]) {
            observationInfo = info;
            break;
        }
    }
    
    [observers removeObject:observationInfo];
}

#pragma mark - Create Class

- (Class)makeKVOClassWithClassName:(NSString *)clazzName
{
    NSString *kvoClazzName = [kKVOClassPrefix stringByAppendingString:clazzName];

    Class clazz = object_getClass(self);
    Class kvoClazz = objc_allocateClassPair(clazz, kvoClazzName.UTF8String, 0);
    
    //3
    Method clazzMethod = class_getInstanceMethod(clazz, @selector(class));
    const char *types = method_getTypeEncoding(clazzMethod);
    class_addMethod(kvoClazz, @selector(class), (IMP)kvo_class, types);
    
    objc_registerClassPair(kvoClazz);
    
    return kvoClazz;
}

#pragma mark -  Getter And Setter

static void kvo_setter(id self, SEL _cmd, id newValue)
{
    NSString *setterName = NSStringFromSelector(_cmd);
    NSString *getterName = getterForSetter(setterName);
    
    if (!getterName) {
        NSLog(@"%@ not %@ property", [self class] ,getterName);
        return;
    }
    
    id oldValue = [self valueForKey:getterName];
    
    struct objc_super superclazz = {
        .receiver = self,
        .super_class = class_getSuperclass(object_getClass(self))
    };
    
    void (*objc_msgSendSuperCasted)(void *, SEL, id) = (void *)objc_msgSendSuper;
    
    objc_msgSendSuperCasted(&superclazz, _cmd, newValue);
    
    NSMutableArray *observers = objc_getAssociatedObject(self, &kKVOAssociatedObservationInfos);
    for (ObservationInfo *each in observers) {
        if ([each.key isEqualToString:getterName]) {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                each.block(self, getterName, oldValue, newValue);
            });
        }
    }
}

static Class kvo_class(id self, SEL _cmd)
{
    return class_getSuperclass(object_getClass(self));
}

static NSString *getterForSetter(NSString *setter)
{
    if (setter.length <=0 || ![setter hasPrefix:@"set"] || ![setter hasSuffix:@":"]) {
        return nil;
    }
    
    NSRange range = NSMakeRange(3, setter.length - 4);
    NSString *key = [setter substringWithRange:range];
    
    NSString *firstLetter = [[key substringToIndex:1] lowercaseString];
    key = [key stringByReplacingCharactersInRange:NSMakeRange(0, 1)
                                       withString:firstLetter];
    
    return key;
}

static NSString *setterForGetter(NSString *getter)
{
    if (getter.length <= 0) {
        return nil;
    }
    
    NSString *firstLetter = [[getter substringToIndex:1] uppercaseString];
    NSString *remainingLetters = [getter substringFromIndex:1];
    
    NSString *setter = [NSString stringWithFormat:@"set%@%@:", firstLetter, remainingLetters];
    
    return setter;
}

@end
