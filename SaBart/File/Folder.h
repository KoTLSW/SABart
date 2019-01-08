//
//  Folder.h
//  HowToWorks
//
//  Created by h on 17/3/16.
//  Copyright © 2017年 bill. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Folder : NSObject
+(instancetype) shareInstance;
- (NSString*)Folder_GetCurrentPath;
-(BOOL) Folder_SetCurrentPath:(NSString*)newPath;
-(BOOL) Folder_Creat:(NSString*)path;
-(BOOL) Foleer_Rename:(NSString*)oldstr new:(NSString*)newstr;

@end
