//
//  BaseFile.mm
//

#import "BaseFile.h"
#import <sys/file.h>
#include <sys/stat.h>
#include <dirent.h>


#define BASEFILE_WRITE_CHUNK 512 * 1024

@implementation CBaseFile

@synthesize m_nsFilePath;
@synthesize m_fhFile;

- (id) init
{
	if(self = [super init])
	{
		m_fhFile = nil;
		m_bOpen = NO;
		m_nsFilePath = nil;
		m_uiMode = MODE_READ_ONLY;
	}
	return self;
}

- (void) dealloc
{
	[self Close];
	self.m_nsFilePath = nil;
	self.m_fhFile = nil;
}

- (BOOL) SetFileInfo:(NSString*)nsFilePath Mode:(UInt32)uiMode
{
	self.m_nsFilePath = nsFilePath;
	m_uiMode = uiMode;
	return YES;
}

- (BOOL) IsOpen
{
	return m_bOpen;
}

- (BOOL) Open
{
	if(!m_bOpen)
	{
		do 
		{
			if(![CBaseFile CreateFile:m_nsFilePath])
			{
				break;
			}
			if(m_uiMode == MODE_READ_ONLY)
			{
				self.m_fhFile = [NSFileHandle fileHandleForReadingAtPath:m_nsFilePath];
			}
			else
			{
				self.m_fhFile = [NSFileHandle fileHandleForUpdatingAtPath:m_nsFilePath];
			}
			if(m_fhFile == nil)
			{
				break;
			}
			m_bOpen = YES;
		} while (0);
	}
	return m_bOpen;
}

- (void) Close
{
	if(m_bOpen)
	{
		m_bOpen = NO;
		if(m_fhFile != nil)
		{
			[m_fhFile closeFile];
		}
		self.m_fhFile = nil;
	}
}

- (BOOL) SetFileSize:(int64_t)i64FileSize
{
	if(!m_bOpen)
	{
		return NO;
	}
	[m_fhFile truncateFileAtOffset:i64FileSize];
	return YES;
}

- (BOOL) Seek:(int64_t)i64Offset
{
	if(!m_bOpen)
	{
		return NO;
	}
	@try
	{
		[m_fhFile seekToFileOffset:i64Offset];
	}
	@catch (NSException * e)
	{
		return NO;
	}
	
	return YES;
}

- (unsigned long long) SeekToEndOfFile
{
	if(!m_bOpen)
	{
		return 0;
	}
	@try
	{
		return [m_fhFile seekToEndOfFile];
	}
	@catch (NSException * e)
	{
	}
	return 0;
}

- (BOOL) ReadData:(NSMutableData*)nsOutput Len:(UInt32)uiLen
{
	if(!m_bOpen)
	{
		return NO;
	}
	@try
	{
		NSData* nsFileData = [m_fhFile readDataOfLength:uiLen];
		if([nsFileData length] != uiLen)
		{
			return NO;
		}
		[nsOutput appendData:nsFileData];
	}
	@catch (NSException * e)
	{
		return NO;
	}
	return YES;
}

- (BOOL) WriteData:(NSData*)nsInput
{
	if(!m_bOpen)
	{
		return NO;
	}
	@try
	{
		[m_fhFile writeData:nsInput];
		//flush
		[m_fhFile synchronizeFile];
	}
	@catch (NSException * e)
	{
		return NO;
	}
	return YES;
}

- (BOOL) WriteLargeData:(NSData*)nsInput
{
	UInt32 uiLen = [nsInput length];
	if(uiLen > 0)
	{
		UInt32 uiCurrWrite = 0;
		while (uiCurrWrite < uiLen)
		{
			UInt32 uiShouldWrite = uiLen - uiCurrWrite;
			if(uiShouldWrite > BASEFILE_WRITE_CHUNK)
			{
				uiShouldWrite = BASEFILE_WRITE_CHUNK;
			}
			NSData* dtTemp = [nsInput subdataWithRange:NSMakeRange(uiCurrWrite, uiShouldWrite)];
			//assert([dtTemp length] == uiShouldWrite);
			if(![self WriteData:dtTemp])
			{
				return NO;
			}
			uiCurrWrite += uiShouldWrite;
		}
	}
	return YES;
}

+ (BOOL) CreateFile:(NSString*)nsFilePath
{
	BOOL bCreated = NO;
	NSFileManager* oFileMgr = [NSFileManager defaultManager];
	do
	{
		if(oFileMgr == nil)
		{
			break;
		}
		if(![oFileMgr fileExistsAtPath:nsFilePath])
		{
            //create file
			if([oFileMgr createFileAtPath:nsFilePath contents:nil attributes:nil])
			{
                bCreated = YES;
                break;
			}
            
			//create path
			NSString* nsPath = [nsFilePath stringByDeletingLastPathComponent];

			//path is not null && is not '/'
			NSError* err;
			if([nsPath length] > 1 && ![oFileMgr createDirectoryAtPath:nsPath withIntermediateDirectories:YES attributes:nil error:&err])
			{
				break;
			}
			//create file
			if(![oFileMgr createFileAtPath:nsFilePath contents:nil attributes:nil])
			{
				break;
			}
		}
		bCreated = YES;
	}while(0);
	return bCreated;
}

+ (BOOL) CreatePath:(NSString*)nsPath
{
	if(![CBaseFile FileExist:nsPath])
	{
		NSFileManager* oFileMgr = [NSFileManager defaultManager];

		if(oFileMgr == nil)
		{
			return NO;
		}
		
		//path is not null && is not '/'
		NSError* err;
		if([nsPath length] > 1 && ![oFileMgr createDirectoryAtPath:nsPath withIntermediateDirectories:YES attributes:nil error:&err])
		{
			return NO;
		}
	}
	
	return YES;
}

+ (BOOL) RenameFile:(NSString*)nsOldPath To:(NSString*)nsNewPath
{
	BOOL bRet = NO;
	NSFileManager* oFileMgr = [NSFileManager defaultManager];
    if ([oFileMgr fileExistsAtPath:nsNewPath]) {
		[oFileMgr removeItemAtPath:nsNewPath error:nil];
	}
    
    NSError * error = nil ; 
	bRet = [oFileMgr moveItemAtPath:nsOldPath toPath:nsNewPath error:&error];
	return bRet;
}

+ (BOOL) CopyFile:(NSString*)nsOldPath To:(NSString*)nsNewPath
{
	BOOL bRet = NO;
	if ([nsOldPath isEqualToString:nsNewPath]) {
		return bRet;
	}

	NSFileManager* oFileMgr = [NSFileManager defaultManager];
	if ([oFileMgr fileExistsAtPath:nsNewPath]) {
		[oFileMgr removeItemAtPath:nsNewPath error:nil];
	}
    
    NSError * error = nil ; 
	bRet = [oFileMgr copyItemAtPath:nsOldPath toPath:nsNewPath error:&error];
	return bRet;
}

+ (BOOL) FileExist:(NSString*)nsFilePath
{
    if([nsFilePath length] == 0)
    {
        return NO;
    }
    
    struct stat temp;
    return lstat(nsFilePath.UTF8String, &temp) == 0;
}

+ (long) GetFiLeModifyTime:(NSString *) path
{
    struct stat temp;
    if(lstat(path.UTF8String, &temp)==0)
    {
        return temp.st_mtimespec.tv_sec;
    }
    return -1;
}

+ (long long) GetFiLeSize:(NSString *) path
{
    struct stat temp;   
    if(lstat(path.UTF8String, &temp)==0)
    {
        return temp.st_size;    
    }
    return -1;
}

+ (long long) FolderSizeAtPath: (const char*)folderPath{
    long long folderSize = 0;
    DIR* dir = opendir(folderPath);
    if (dir == NULL) 
    {
        return 0;
    }
    struct dirent* child;
    while ((child = readdir(dir))!=NULL) {
        if (child->d_type == DT_DIR && ((child->d_name[0] == '.' && child->d_name[1] == 0) || (child->d_name[0] == '.' && child->d_name[1] == '.' && child->d_name[2] == 0))) continue;
        
        int folderPathLength = strlen(folderPath);
        char childPath[1024]; 
        stpcpy(childPath, folderPath);
        if (folderPath[folderPathLength-1] != '/'){
            childPath[folderPathLength] = '/';
            folderPathLength++;
        }
        stpcpy(childPath+folderPathLength, child->d_name);
        childPath[folderPathLength + child->d_namlen] = 0;
        if (child->d_type == DT_DIR){ 
            folderSize += [self FolderSizeAtPath:childPath]; 
            struct stat st;
            if(lstat(childPath, &st) == 0) folderSize += st.st_size;
        }else if (child->d_type == DT_REG || child->d_type == DT_LNK){ 
            struct stat st;
            if(lstat(childPath, &st) == 0) folderSize += st.st_size;
        }
    }
    
    closedir(dir);
    return folderSize;
}

+ (NSMutableArray *)SubFoldersName:(const char *)folderPath {
    NSMutableArray *arrSubFolderName = [NSMutableArray array];
    DIR *dir = opendir(folderPath);
    if (dir == NULL) {
        return arrSubFolderName;
    }
    
    struct dirent* child;
    while ((child = readdir(dir))!=NULL) {
        if (child->d_type == DT_DIR && ((child->d_name[0] == '.' && child->d_name[1] == 0) || (child->d_name[0] == '.' && child->d_name[1] == '.' && child->d_name[2] == 0))) continue;

        int folderPathLength = strlen(folderPath);
        char childPath[1024];
        stpcpy(childPath, folderPath);
        if (folderPath[folderPathLength-1] != '/'){
            childPath[folderPathLength] = '/';
            folderPathLength++;
        }
        stpcpy(childPath+folderPathLength, child->d_name);
        childPath[folderPathLength + child->d_namlen] = 0;
        if (child->d_type == DT_DIR){
            NSString *subFolderName = [[NSString alloc] initWithCString:childPath encoding:NSUTF8StringEncoding];
            [arrSubFolderName safeAddObject:subFolderName];
        }
    }
    
    closedir(dir);
    return arrSubFolderName;
}

+ (NSMutableArray *)SubFilesName:(const char *)folderPath {
    NSMutableArray *arrSubFileName = [NSMutableArray array];
    DIR *dir = opendir(folderPath);
    if (dir == NULL) {
        return arrSubFileName;
    }
    
    struct dirent* child;
    while ((child = readdir(dir))!=NULL) {
        if (child->d_type == DT_DIR && ((child->d_name[0] == '.' && child->d_name[1] == 0) || (child->d_name[0] == '.' && child->d_name[1] == '.' && child->d_name[2] == 0))) continue;
        
        int folderPathLength = strlen(folderPath);
        char childPath[1024];
        stpcpy(childPath, folderPath);
        if (folderPath[folderPathLength-1] != '/'){
            childPath[folderPathLength] = '/';
            folderPathLength++;
        }
        stpcpy(childPath+folderPathLength, child->d_name);
        childPath[folderPathLength + child->d_namlen] = 0;
        if (child->d_type == DT_REG || child->d_type == DT_LNK){
            NSString *subFileName = [[NSString alloc] initWithCString:childPath encoding:NSUTF8StringEncoding];
            [arrSubFileName safeAddObject:subFileName];
        }
    }
    
    closedir(dir);
    return arrSubFileName;
}

+ (BOOL)LoadSubFolders:(NSMutableArray *)arrSubFolder SubFiles:(NSMutableArray *)arrSubFiles fromFolderPath:(const char *)folderPath {
    if ((arrSubFolder == nil) || (arrSubFiles == nil) || (folderPath == NULL)) {
        return NO;
    }
    
    DIR *dir = opendir(folderPath);
    if (dir == NULL) {
        return NO;
    }
    
    struct dirent* child;
    while ((child = readdir(dir))!=NULL) {
        if (child->d_type == DT_DIR && ((child->d_name[0] == '.' && child->d_name[1] == 0) || (child->d_name[0] == '.' && child->d_name[1] == '.' && child->d_name[2] == 0))) continue;
        
        int folderPathLength = strlen(folderPath);
        char childPath[1024];
        stpcpy(childPath, folderPath);
        if (folderPath[folderPathLength-1] != '/'){
            childPath[folderPathLength] = '/';
            folderPathLength++;
        }
        stpcpy(childPath+folderPathLength, child->d_name);
        childPath[folderPathLength + child->d_namlen] = 0;
        if (child->d_type == DT_REG || child->d_type == DT_LNK){
            NSString *subFileName = [[NSString alloc] initWithCString:childPath encoding:NSUTF8StringEncoding];
            [arrSubFiles safeAddObject:subFileName];
        } else if (child->d_type == DT_DIR){
            NSString *subFolderName = [[NSString alloc] initWithCString:childPath encoding:NSUTF8StringEncoding];
            [arrSubFolder safeAddObject:subFolderName];
        }
    }
    
    closedir(dir);
    return YES;
}

+ (BOOL) RemoveFile:(NSString*)nsFilePath
{
    if ([CBaseFile FileExist:nsFilePath])
    {
        NSFileManager* oFileMgr = [NSFileManager defaultManager];
        NSError *err = nil;
        if(![oFileMgr removeItemAtPath:nsFilePath error:&err])
        {
            return NO;
        }
    }
    return YES;
}

+ (int64_t) GetFileSize:(NSString*)nsFilePath
{
	NSFileManager* oFileMgr = [NSFileManager defaultManager];
	NSDictionary* dicFileAttr;
    NSError* err = nil;
	dicFileAttr = [oFileMgr attributesOfItemAtPath:nsFilePath error:&err];
	if(dicFileAttr != nil)
	{
		return [[dicFileAttr objectForKey:NSFileSize] longLongValue];
	}
	return 0;
}

+ (void) ClearPath:(NSString*)nsFilePath
{
    if(nsFilePath.length <= 0) {
        return;
    }
    
    if(![CBaseFile FileExist:nsFilePath]) {
        return;
    }
    
    // sync clear
	NSFileManager* oFileMgr = [NSFileManager defaultManager];
    NSError* err = nil;
	NSArray* arrContent = [oFileMgr contentsOfDirectoryAtPath:nsFilePath error:&err];
	for(NSString* nsString in arrContent)
	{
		NSString* nsListPath = [nsFilePath stringByAppendingPathComponent:nsString];
		[CBaseFile RemoveFile:nsListPath];
	}
}

+(void) ClearPath:(NSString*)nsFilePath WithOut:(NSString *)nsFilename
{
    NSFileManager* oFileMgr = [NSFileManager defaultManager];
    NSError* err = nil;
	NSArray* arrContent = [oFileMgr contentsOfDirectoryAtPath:nsFilePath error:&err];
	for(NSString* nsString in arrContent)
	{
        if(![nsString isEqualToString:nsFilename])
        {
            NSString* nsListPath = [nsFilePath stringByAppendingPathComponent:nsString];
            [CBaseFile RemoveFile:nsListPath];
        }
	}
}

+ (BOOL) CreateSymbolLink:(NSString*)nsFilePath LinkName:(NSString*)nsLinkName
{
	NSFileManager* oFileMgr = [NSFileManager defaultManager];
    NSError* err = nil;
    if(![oFileMgr createSymbolicLinkAtPath:nsLinkName withDestinationPath:nsFilePath error:&err])
    {
        return NO;
    }
	return YES;
}

+(NSData*) LoadDataFromPath:(NSString*)nsPath Offset:(UInt32)uiOffset Len:(UInt32)uiLen
{
	if(![CBaseFile FileExist:nsPath])
	{
		return nil;
	}
	UInt32 uiFileSize = [CBaseFile GetFileSize:nsPath];
	if(uiOffset + uiLen > uiFileSize)
	{
		return nil;
	}
	
	CBaseFile* fRead = [[CBaseFile alloc] init];
	[fRead SetFileInfo:nsPath Mode:MODE_READ_ONLY];
    if(![fRead Open])
    {
        return nil;
    }
    
	if([fRead Seek:uiOffset])
	{
		NSMutableData* dtRead = [[NSMutableData alloc] init];
		if([fRead ReadData:dtRead Len:uiLen])
		{
			[fRead Close];
			return dtRead;
		}
	}
    
    [fRead Close];
	return nil;
}

+(NSData*) LoadDataFromPathEx:(NSString*)nsPath Offset:(UInt32)uiOffset MaxLen:(UInt32)uiLen
{
    if(![CBaseFile FileExist:nsPath])
	{
		return nil;
	}
	UInt32 uiFileSize = [CBaseFile GetFileSize:nsPath];
	if(uiOffset + uiLen > uiFileSize)
	{
        uiLen = uiFileSize-uiOffset;
        if (uiLen<=0) {
            return nil;
        }
	}
	
	CBaseFile* fRead = [[CBaseFile alloc] init];
	[fRead SetFileInfo:nsPath Mode:MODE_READ_ONLY];
    if(![fRead Open])
    {
        return nil;
    }
    
	if([fRead Seek:uiOffset])
	{
		NSMutableData* dtRead = [[NSMutableData alloc] init];
		if([fRead ReadData:dtRead Len:uiLen])
		{
			[fRead Close];
			return dtRead;
		}
	}
    
    [fRead Close];
	return nil;
}

+(BOOL) WriteDataToPath:(NSString*)nsPath Offset:(UInt32)uiOffset Data:(NSData*)dtData
{
	if ([nsPath length] == 0 || [dtData length] == 0)
	{
		return NO;
	}
	
	CBaseFile* fWrite = [[CBaseFile alloc] init];
	[fWrite SetFileInfo:nsPath Mode:MODE_READ_WRITE];
	if(![fWrite Open])
	{
		return NO;
	}
	
	if (![fWrite Seek:uiOffset])
	{
		[fWrite Close];
		return NO;
	}
	
	if(![fWrite WriteLargeData:dtData])
	{
		[fWrite Close];
		return NO;
	}
	
	[fWrite Close];
	
	return YES;
}

+(BOOL) AppendData:(NSData*)buffer toPath:(NSString*)path
{
    CBaseFile* hfile = [[CBaseFile alloc] init];
    [hfile SetFileInfo:path Mode:MODE_READ_WRITE];
    
    if([hfile Open]){
        [hfile SeekToEndOfFile];
        [hfile WriteLargeData:buffer];
        [hfile Close];
    }else{
        return NO;
    }
    
    return YES;
}

+(BOOL) OverWriteDataToPath:(NSString*)nsPath Data:(NSData*)dtData
{
    [CBaseFile RemoveFile:nsPath];
    return [CBaseFile WriteDataToPath:nsPath Offset:0 Data:dtData];
}

+(BOOL) SysOverWriteDataToPath:(NSString*)nsPath Data:(NSData*)dtData
{
	if (![CBaseFile FileExist:nsPath]) {
		[CBaseFile CreateFile:nsPath];
	}
	
	ssize_t bytesWrited = 0;
	int fd = open(nsPath.UTF8String, O_WRONLY | O_CREAT | O_TRUNC, S_IRWXU);
	if (fd > 0) {
		bytesWrited = write(fd, dtData.bytes, dtData.length);
	}
	close(fd);

	return fd > 0 && bytesWrited == dtData.length;
}

+(BOOL) SysAppendData:(NSData*)dtData toPath:(NSString*)nsPath
{
	if (![CBaseFile FileExist:nsPath]) {
		[CBaseFile CreateFile:nsPath];
	}
	
	ssize_t bytesWrited = 0;
	int fd = open(nsPath.UTF8String, O_WRONLY | O_CREAT | O_APPEND, S_IRWXU);
	if (fd > 0) {
		bytesWrited = write(fd, dtData.bytes, dtData.length);
	}
	close(fd);
	
	return fd > 0 && bytesWrited == dtData.length;
}

+(NSDate *) GetFileCreateTime:(NSString *) nsPath
{
    if (![CBaseFile FileExist:nsPath]) {
        return nil;
	}
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *err = nil;
    NSDictionary *dic = [fileManager attributesOfItemAtPath:nsPath error:&err];
    if(dic == nil) return nil;
    NSDate *lastModifiedDate = (NSDate*)[dic objectForKey:NSFileModificationDate];
    return lastModifiedDate;
}

@end
