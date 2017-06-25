//
//  ObjcRuntimeUtil.h
//  MusicPlayer
//
//  Created by jacky on 2017/6/24.
//  Copyright © 2017年 jacky. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import <vector>

@interface ObjcRuntimeUtil : NSObject


+(BOOL) isClass:(Class)cls inheritsFromClass:(Class)baseClass;

+(std::vector<objc_method_description>) getAllMethodOfProtocol:(Protocol*) proto;

+(NSString*) getCallerMethod;

@end

// using objc_setAssociatedObject to attach/detach object in dynamic
@interface NSObject (ObjcRuntime)

-(void) attachObject:(id)obj forKey:(NSString*)nsKey;

-(id) getAttachedObjectForKey:(NSString*)nsKey;

-(void) detachObjectForKey:(NSString*)nsKey;

-(void)removeAssociatedObjects;

@end

// for ARC self retain/autorelease
void arc_retain(id obj);
void arc_autorelease(id obj);
