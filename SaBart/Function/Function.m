//
//  Function.m
//  TestFunction
//
//  Created by mac on 22/12/2018.
//  Copyright © 2018 piaoxu. All rights reserved.
//

#import "Function.h"

@implementation Function

-(NSString *)rangeofString:(NSString *)String Prefix:(NSString *)prefix Suffix:(NSString *)suffix{
    //OC获取中间的字符串
    NSString *middleStr;
    //到该字符结束
    NSRange range;
    range.location = [String rangeOfString:prefix].location + prefix.length;
    range.length = [String rangeOfString:suffix].location - range.location;
    middleStr = [NSString stringWithFormat:@"%@", [String substringWithRange:range]];
    NSLog(@"%@",middleStr);
    
    return middleStr;
}

@end
