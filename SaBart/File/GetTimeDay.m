//
//  GetTime.m
//  TestFixture
//
//  Created by CW-IT-MINI-001 on 14-3-12.
//  Copyright (c) 2014年 CW-IT-MINI-001. All rights reserved.
//

#import "GetTimeDay.h"

@implementation GetTimeDay

+(GetTimeDay *)shareInstance
{
    static GetTimeDay *getTimeDay = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        getTimeDay = [[GetTimeDay alloc] init];
    });
    
    return getTimeDay;
}


-(NSString*)getCurrentTime
{
    NSDate* date = [NSDate date];
    NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"_HH:mm:ss"];
    //[formatter setDateFormat:@"mm:ss:SSS"];
    NSString* currentTime = [formatter stringFromDate:date];
//    [formatter release];
    return currentTime;
}
-(NSString*)getCurrentTime_SFC
{
    NSDate* date = [NSDate date];
    NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"HHmmss"];
    //[formatter setDateFormat:@"mm:ss:SSS"];
    NSString* currentTime = [formatter stringFromDate:date];
    //    [formatter release];
    return currentTime;
}

-(time_t)convertTimeStamp:(NSString *)stringTime
{
    time_t createdAt = 0;
    struct tm *created;
    time_t now;
    time(&now);
    
    created = localtime(&now);
    const char *strTime = [stringTime UTF8String];
    
    if(![stringTime isEqualToString:@""])
    {
        if (strptime(strTime, "%a %b %d %H:%M:%S %z %Y", created) == NULL)
        {
            strptime(strTime, "%Y/%m/%d/%R", created);
        }
        
        createdAt = mktime(created);
    }
    
    return createdAt;
}

-(NSString*)getCurrentSecond
{
    NSDate* date = [NSDate date];
    NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"_yyyy/MM/dd HH:mm:ss"];
    NSString* currentTime = [formatter stringFromDate:date];
//    [formatter release];
    return currentTime;
}

    
-(NSString*)getFileTime
{
    NSDate* date = [NSDate date];
    NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy-MM-dd(HH:mm:ss)"];
    NSString* currentTime = [formatter stringFromDate:date];
    
//    [formatter release];
    return currentTime;
}

-(NSString*)getSFCTime
{
    NSDate* date = [NSDate date];
    NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy-MM-dd(HH:mm:ss)"];
    
    NSString* currentTime = [formatter stringFromDate:date];
    
    currentTime=[currentTime stringByReplacingOccurrencesOfString:@"(" withString:@"T"];
    currentTime=[currentTime stringByReplacingOccurrencesOfString:@")" withString:@""];
    
    return currentTime;
}

-(NSString*)getCurrentDay
{
    NSDate* date = [NSDate date];
    NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy-MM-dd"];
    NSString* currentDay = [formatter stringFromDate:date];
//    [formatter release];
    return currentDay;
}

-(NSString*)getCurrentMonth
{
    NSDate* date = [NSDate date];
    NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy-MM-"];
    NSString* currentMonth = [formatter stringFromDate:date];
    //    [formatter release];
    return currentMonth;
}

-(NSString *)getCurrentMinuteAndSecond
{
    NSDate* date = [NSDate date];
    NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"mm:ss:SSS"];
    NSString* currentTime = [formatter stringFromDate:date];
    return currentTime;
}


@end
