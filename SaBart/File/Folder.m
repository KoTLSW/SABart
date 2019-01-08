//
//  Folder.m
//  HowToWorks
//
//  Created by h on 17/3/16.
//  Copyright © 2017年 bill. All rights reserved.
//

#import "Folder.h"
@interface Folder (){

}
@end

@implementation Folder

static Folder * _Folder = nil;

+(instancetype) shareInstance
{
    static dispatch_once_t onceToken ;
    dispatch_once(&onceToken, ^{
        _Folder = [[self alloc] init] ;
    }) ;
    
    return _Folder;
}


- (NSString*)Folder_GetCurrentPath
{
    NSFileManager *fm = [NSFileManager defaultManager];
    NSString *path = [fm currentDirectoryPath];
    return path;
    
}
-(BOOL) Folder_SetCurrentPath:(NSString*)newPath
{
    NSFileManager *fm = [NSFileManager defaultManager];
    return [fm changeCurrentDirectoryPath:newPath];
}
-(BOOL) Folder_Creat:(NSString*)path
{
     NSFileManager *fm = [NSFileManager defaultManager];
    if ([fm fileExistsAtPath:path]) {
        
        return YES;
    }
    else
    {
       return [fm createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
}
-(BOOL) Foleer_Rename:(NSString*)oldstr new:(NSString*)newstr
{
     NSFileManager *fm = [NSFileManager defaultManager];
    //return [fm movePath:oldstr toPath:newstr handler:nil];
    return [fm moveItemAtPath:oldstr toPath:newstr error:nil];
}

@end
