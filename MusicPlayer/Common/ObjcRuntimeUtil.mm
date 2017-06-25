//
//  ObjcRuntimeUtil.mm
//

#import "ObjcRuntimeUtil.h"
#import "NSMutableObject+SafeInsert.h"

//#define TEST_OBJC_RUNTIME

static void getAllMethodForProtocol(Protocol *proto, std::vector<objc_method_description>& arrMethods)
{
    // <NSObject> 就不处理了
    if (protocol_isEqual(proto, @protocol(NSObject))) {
        return;
    }
    
    unsigned int protoCount = 0;
    //	Protocol * arrProto = protocol_copyProtocolList(proto, &protoCount);
    Protocol * __unsafe_unretained * arrProto = protocol_copyProtocolList(proto, &protoCount);
    if (arrProto != NULL && protoCount > 0) {
        for (unsigned int index = 0; index < protoCount; index++) {
            getAllMethodForProtocol(arrProto[index], arrMethods);
        }
        free(arrProto);
    }
    
    unsigned int optionalCount = 0;
    objc_method_description* optionalMethods = protocol_copyMethodDescriptionList(proto, NO, YES, &optionalCount);
    if (optionalMethods != NULL && optionalCount > 0) {
        arrMethods.insert(arrMethods.end(), optionalMethods, optionalMethods+optionalCount);
        free(optionalMethods);
    }
    
    unsigned int requiredCount = 0;
    objc_method_description* requiredMethods = protocol_copyMethodDescriptionList(proto, YES, YES, &requiredCount);
    if (requiredMethods != NULL && requiredCount > 0) {
        arrMethods.insert(arrMethods.end(), requiredMethods, requiredMethods+requiredCount);
        free(requiredMethods);
    }
}


@implementation ObjcRuntimeUtil

+(BOOL) isClass:(Class)oneClass inheritsFromClass:(Class)baseClass {
    Class cls = oneClass;
    while(cls) {
        if(cls == baseClass) {
            return YES;
        }
        cls = class_getSuperclass(cls);
    }
    
    return NO;
}

+(std::vector<objc_method_description>) getAllMethodOfProtocol:(Protocol*) proto {
    std::vector<objc_method_description> arrMethos;
    
    getAllMethodForProtocol(proto, arrMethos);
    
    return arrMethos;
}

+(NSString*) getCallerMethod {
    NSArray* arrStacks = [NSThread callStackSymbols];
    if (arrStacks.count >= 3) {
        NSMutableString* nsMethod = [NSMutableString stringWithString:[arrStacks objectAtIndex:2]];
        [nsMethod replaceOccurrencesOfString:@"  " withString:@"" options:NSLiteralSearch range:NSMakeRange(0, nsMethod.length)];
        
        NSMutableArray* arr = [NSMutableArray arrayWithArray:[nsMethod componentsSeparatedByString:@" "]];
        [arr safeRemoveObjectAtIndex:0];
        [arr safeRemoveObjectAtIndex:0];
        [arr safeRemoveObjectAtIndex:arr.count-1];
        [arr safeRemoveObjectAtIndex:arr.count-1];
        NSString* nsPureMethod = [arr componentsJoinedByString:@" "];
        
        return nsPureMethod;
    }
    return nil;
}

@end


@implementation NSObject (ObjcRuntime)

// hash + 首字母 + 末字母
-(const void*) computeKeyFromString:(NSString*)nsKey {
    return (char*)((__bridge void *)self) + [nsKey hash] + [nsKey characterAtIndex:0] + [nsKey characterAtIndex:nsKey.length-1];
}

-(void)attachObject:(id)obj forKey:(NSString *)nsKey {
    if (nsKey.length > 0) {
        const void* computedKey = [self computeKeyFromString:nsKey];
//        CommonDebug(@"%@->%p", nsKey, computedKey);
        
        objc_setAssociatedObject(self, computedKey, obj, OBJC_ASSOCIATION_RETAIN);
    }
}

-(id)getAttachedObjectForKey:(NSString *)nsKey {
    if (nsKey.length <= 0) {
        return nil;
    }
    const void* computedKey = [self computeKeyFromString:nsKey];
//    CommonDebug(@"%@->%p", nsKey, computedKey);
    
    return objc_getAssociatedObject(self, computedKey);
}

-(void)detachObjectForKey:(NSString *)nsKey {
    if (nsKey.length > 0) {
        const void* computedKey = [self computeKeyFromString:nsKey];
//        CommonDebug(@"%@->%p", nsKey, computedKey);
        
        objc_setAssociatedObject(self, computedKey, nil, OBJC_ASSOCIATION_RETAIN);
    }
}

-(void)removeAssociatedObjects
{
    objc_removeAssociatedObjects(self);
}

@end


#ifdef TEST_OBJC_RUNTIME

@class CContact;
@interface UIButton (ObjcRuntime)

@property (retain) CContact* m_contact;

@end

@implementation UIButton (ObjcRuntime)

-(CContact*)m_contact {
    return [self getAttachedObjectForKey:@"m_contact"];
}

-(void)setM_contact:(CContact *)oContact {
    [self attachObject:oContact forKey:@"m_contact"];
}

@end

#endif
