//
//  BaseFile.h

#import <Foundation/Foundation.h>
#import "NSMutableObject+SafeInsert.h"

enum
{
	MODE_READ_ONLY = 0,
	MODE_DOWNLOAD,
	MODE_READ_WRITE,
	MODE_OP_LOG,
};


@interface CBaseFile : NSObject
{
	NSFileHandle* m_fhFile;
	NSString* m_nsFilePath;
	UInt32 m_uiMode;
	BOOL m_bOpen;
}

@property (nonatomic, strong) NSString* m_nsFilePath;
@property (nonatomic, strong) NSFileHandle* m_fhFile;

- (BOOL) SetFileInfo:(NSString*)nsFilePath Mode:(UInt32)uiMode;
- (BOOL) IsOpen;
- (BOOL) Open;
- (void) Close;
- (BOOL) SetFileSize:(int64_t)i64FileSize;

- (BOOL) Seek:(int64_t)i64Offset;
- (unsigned long long) SeekToEndOfFile;
- (BOOL) ReadData:(NSMutableData*)nsOutput Len:(UInt32)uiLen;
- (BOOL) WriteData:(NSData*)nsInput;
- (BOOL) WriteLargeData:(NSData*)nsInput;

+ (BOOL) CreateFile:(NSString*)nsFilePath;
+ (BOOL) CreatePath:(NSString*)nsPath;
+ (BOOL) RenameFile:(NSString*)nsOldPath To:(NSString*)nsNewPath;
+ (BOOL) CopyFile:(NSString*)nsOldPath To:(NSString*)nsNewPath;
+ (BOOL) FileExist:(NSString*)nsFilePath;
+ (long) GetFiLeModifyTime:(NSString *) path;

+ (long long) GetFiLeSize:(NSString *) path;
+ (long long) FolderSizeAtPath: (const char*)folderPath;

+ (NSMutableArray *)SubFoldersName:(const char *)folderPath;
+ (NSMutableArray *)SubFilesName:(const char *)folderPath;
+ (BOOL)LoadSubFolders:(NSMutableArray *)arrSubFolder SubFiles:(NSMutableArray *)arrSubFiles fromFolderPath:(const char *)folderPath;

+ (BOOL) RemoveFile:(NSString*)nsFilePath;
+ (int64_t) GetFileSize:(NSString*)nsFilePath;
+ (void) ClearPath:(NSString*)nsFilePath;
+ (void) ClearPath:(NSString*)nsFilePath WithOut:(NSString *)nsFilename;

+ (BOOL) CreateSymbolLink:(NSString*)nsFilePath LinkName:(NSString*)nsLinkName;

+(NSData*) LoadDataFromPath:(NSString*)nsPath Offset:(UInt32)uiOffset Len:(UInt32)uiLen;
+(NSData*) LoadDataFromPathEx:(NSString*)nsPath Offset:(UInt32)uiOffset MaxLen:(UInt32)uiLen;

+(BOOL) WriteDataToPath:(NSString*)nsPath Offset:(UInt32)uiOffset Data:(NSData*)dtData;

+(BOOL) AppendData:(NSData*)buffer toPath:(NSString*)path;
+(BOOL) OverWriteDataToPath:(NSString*)nsPath Data:(NSData*)dtData;

+(BOOL) SysAppendData:(NSData*)buffer toPath:(NSString*)path;
+(BOOL) SysOverWriteDataToPath:(NSString*)nsPath Data:(NSData*)dtData;

+(NSDate *) GetFileCreateTime:(NSString *) nsPath;

@end
