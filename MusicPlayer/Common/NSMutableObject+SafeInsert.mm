//
//  NSMutableObject+SafeInsert.mm
//

#import "ObjcRuntimeUtil.h"
#import "NSMutableObject+SafeInsert.h"

//#define ENABLE_SAFE_INSERT_LOG
@implementation NSCache(SafeInsert)

-(void) safeSetObject:(id)anObject forKey:(id)aKey
{
    if (anObject && aKey) {
		[self setObject:anObject forKey:aKey];
	}
#ifdef ENABLE_SAFE_INSERT_LOG
	else
	{
		if (!anObject || !aKey) {
			CommonWarning(@"inserting obj[%@] for key[%@], from: %@", anObject, aKey, [ObjcRuntimeUtil getCallerMethod]);
		}
	}
#endif

}
-(void) safeRemoveObjectForKey:(id)aKey
{
    if (aKey) {
		[self removeObjectForKey:aKey];
	}
#ifdef ENABLE_SAFE_INSERT_LOG
	else
	{
		CommonWarning(@"removing obj for key[%@], from: %@", aKey, [ObjcRuntimeUtil getCallerMethod]);
	}
#endif

}

@end

@implementation NSMutableDictionary (SafeInsert)

-(void) safeSetObject:(id)anObject forKey:(id)aKey {
	if (anObject && aKey) {
		[self setObject:anObject forKey:aKey];
	}
#ifdef ENABLE_SAFE_INSERT_LOG
	else
	{
		if (!anObject || !aKey) {
			CommonWarning(@"inserting obj[%@] for key[%@], from: %@", anObject, aKey, [ObjcRuntimeUtil getCallerMethod]);
		}
	}
#endif
}

-(void) safeRemoveObjectForKey:(id)aKey {
	if (aKey) {
		[self removeObjectForKey:aKey];
	}
#ifdef ENABLE_SAFE_INSERT_LOG
	else
	{
		CommonWarning(@"removing obj for key[%@], from: %@", aKey, [ObjcRuntimeUtil getCallerMethod]);
	}
#endif
}

-(void) dBSafeSetObject:(id)anObject forKey:(id)aKey {
    
#ifdef ENABLE_SAFE_INSERT_LOG
    if (!anObject || !aKey) {
        CommonWarning(@"inserting obj[%@] for key[%@], from: %@", anObject, aKey, [ObjcRuntimeUtil getCallerMethod]);
    }
#endif

    if (anObject) {
        [self setObject:anObject forKey:aKey];
    }
    else{
        if ([anObject isKindOfClass:[NSString class]]) {
           [self setObject:@"" forKey:aKey];
        }else if ([anObject isKindOfClass:[NSData class]]){
            NSData* dtValue = [[NSData alloc] init];
           [self setObject:dtValue forKey:aKey];
        }else{
           [self setObject:[NSNull null] forKey:aKey];
        }
    }
}

@end

@implementation NSMutableSet (SafeInsert)

-(void) safeAddObject:(id)object {
	if (object) {
		[self addObject:object];
	}
#ifdef ENABLE_SAFE_INSERT_LOG
	else
	{
		CommonWarning(@"adding obj[%@], from: %@", object, [ObjcRuntimeUtil getCallerMethod]);
	}
#endif
}

- (void) safeRemoveObject:(id)object {
	if (object) {
		[self removeObject:object];
	}
#ifdef ENABLE_SAFE_INSERT_LOG
	else
	{
		CommonWarning(@"remove obj[%@], from: %@", object, [ObjcRuntimeUtil getCallerMethod]);
	}
#endif
}


@end

@implementation NSMutableArray (SafeInsert)

-(void) safeAddObject:(id)anObject {
	if (anObject) {
		[self addObject:anObject];
	}
#ifdef ENABLE_SAFE_INSERT_LOG
	else
	{
		CommonWarning(@"adding obj[%@], from: %@", anObject, [ObjcRuntimeUtil getCallerMethod]);
	}
#endif
}

-(void) safeInsertObject:(id)anObject atIndex:(NSUInteger)index {
	if (anObject && index <= self.count) {
		[self insertObject:anObject atIndex:index];
	}
#ifdef ENABLE_SAFE_INSERT_LOG
	else
	{
		if (!anObject) {
			CommonWarning(@"inserting obj[%@] atIndex[%u], from: %@", anObject, index, [ObjcRuntimeUtil getCallerMethod]);
		}
		if (index > self.count) {
			CommonWarning(@"inserting obj[%@] atIndex[%u] out of bound[%u], from: %@", anObject, index, self.count, [ObjcRuntimeUtil getCallerMethod]);
		}
	}
#endif
}

-(void) safeRemoveObjectAtIndex:(NSUInteger)index {
	if (index < self.count) {
		[self removeObjectAtIndex:index];
	}
#ifdef ENABLE_SAFE_INSERT_LOG
	else
	{
		CommonWarning(@"removing atIndex[%u] out of bound[%u], from: %@", index, self.count, [ObjcRuntimeUtil getCallerMethod]);
	}
#endif
}

-(void) safeReplaceObjectAtIndex:(NSUInteger)index withObject:(id)anObject {
	if (index < self.count && anObject) {
		[self replaceObjectAtIndex:index withObject:anObject];
	}
#ifdef ENABLE_SAFE_INSERT_LOG
	else
	{
		if (!anObject) {
			CommonWarning(@"replacing obj[%@] atIndex, from: %@", anObject, index, [ObjcRuntimeUtil getCallerMethod]);
		}
		if (index >= self.count) {
			CommonWarning(@"replacing obj[%@] atIndex[%u] out of bound[%u], from: %@", anObject, index, self.count, [ObjcRuntimeUtil getCallerMethod]);
		}
	}
#endif
}

-(id) firstObject {
	if (self.count > 0) {
		return [self objectAtIndex:0];
	}
	return nil;
}

-(void) removeFirstObject {
	[self safeRemoveObjectAtIndex:0];
}

-(id) safeObjectAtIndex:(NSInteger)index{
    if (index < self.count) {
        return [self objectAtIndex:index];
    }else{
        return nil;
    }
}

@end

@implementation NSArray (SafeInsert)

-(id) firstObject {
	if (self.count > 0) {
		return [self objectAtIndex:0];
	}
	return nil;
}

@end

@implementation NSMutableString (SafeInsert)

- (void)safeAppendString:(NSString *)aString
{
    if (nil == aString) {
        return;
    }
    
    [self appendString:aString];
}

@end
