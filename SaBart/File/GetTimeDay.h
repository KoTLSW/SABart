//
//  GetTimeDay.h
//  TestFixture
//
//  Created by CW-IT-MINI-001 on 14-3-12.
//  Copyright (c) 2014年 CW-IT-MINI-001. All rights reserved.
//

#ifndef GET_TIME_DAY_H_H
#define GET_TIME_DAY_H_H


#import <Foundation/Foundation.h>

@interface GetTimeDay : NSObject

+(GetTimeDay *)shareInstance;
-(NSString*)getCurrentTime_SFC;
-(NSString*)getCurrentMonth;
-(NSString*)getSFCTime;
-(NSString*)getCurrentDay;  //get current date ,time format:yyyy-MM-dd               年月日
-(NSString*)getCurrentTime; //get current time ,time format:HH:mm:ss                 时分秒
-(NSString*)getFileTime;  //get current time ,time format:yyyy-MM-dd(HH``mm``ss)   年月日,时分秒(该格式用于文件命名)
-(NSString*)getCurrentSecond; //get current time ,time format:yyyy/MM/dd HH:mm:ss    年月日,时分秒
-(NSString*)getCurrentMinuteAndSecond;//获取分和秒
@end


#endif
