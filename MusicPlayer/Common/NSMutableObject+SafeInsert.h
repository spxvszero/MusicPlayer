//
//  NSMutableObject+SafeInsert.h
//

#import <Foundation/Foundation.h>

@interface NSMutableDictionary (SafeInsert)

-(void) safeSetObject:(id)anObject forKey:(id)aKey;
-(void) safeRemoveObjectForKey:(id)aKey;

//数据库插入用
-(void) dBSafeSetObject:(id)anObject forKey:(id)aKey;
@end

@interface NSMutableSet (SafeInsert)

-(void) safeAddObject:(id)object;
- (void) safeRemoveObject:(id)object;

@end

@interface NSMutableArray (SafeInsert)

-(void) safeAddObject:(id)anObject;
-(void) safeInsertObject:(id)anObject atIndex:(NSUInteger)index;
-(void) safeRemoveObjectAtIndex:(NSUInteger)index;
-(void) safeReplaceObjectAtIndex:(NSUInteger)index withObject:(id)anObject;
-(id) firstObject;
-(void) removeFirstObject;
-(id) safeObjectAtIndex:(NSInteger)index;

@end

@interface NSArray (SafeInsert)

-(id) firstObject;

@end

@interface NSCache (SafeInsert)
-(void) safeSetObject:(id)anObject forKey:(id)aKey;
-(void) safeRemoveObjectForKey:(id)aKey;
@end

@interface NSMutableString (SafeInsert)

- (void)safeAppendString:(NSString *)aString;

@end

//#define SAFE_DELETE(x) if(x != nil){ [x release]; x = nil; }

//#define SAFE_RETAIN(x) if(x != nil){ [x retain]; }

#define RETURN_STR(x) (x==NULL)?"":x

#define RETURN_NSSTRING(x) (x==nil)?@"":x

#define MAKE_SAFE_NSSTRING(x)	if (x == nil) { x = @"";}

#define SAFE_DECREASE(x, y) if(x >= y) { x = x - y;}

// 附值自动释放之前的对象和增加对新的对象引用 self.xxx =  value
//#define SETTER_RETAIN(x, value)	{if (x != nil && x != value) {[x release]; x = nil;}; x = [value retain];}

//#define LOCALSTR(str) NSLocalizedString(str, str)
#define LOCALSTR(str) NSLocalizedStringFromTable(str, @"wd", nil)

#define GetUtf8FromCString(dest, src) \
dest = [NSString stringWithUTF8String:RETURN_STR(src)]; \
if(dest == nil) \
{ \
dest = @""; \
}