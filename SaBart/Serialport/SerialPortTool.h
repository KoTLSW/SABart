//
//  SerialPortTool.h
//  Framework
//
//  Created by Robin on 2018/11/11.
//  Copyright © 2018年 RobinCode. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Foundation/Foundation.h>
#import <CoreTestFoundation/CoreTestFoundation.h>
/*
 把ORSSerialPort包装成同步的,便于代码的维护
 
 */

@interface SerialPortTool : NSObject
/*
 @param: path -> serialPort Path example :/dev/cu.usbserial-A107R7CU
 @param: config -> dictionary , like key-value. timeout-2.0, reponseEndMark -"\r\n"
 return : open result. YES Or NO, fail and success.
 */

-(BOOL)openSerialPortWithPath:(NSString*)path congfig:(NSDictionary*)config;

/*
 @param:command -> the command you will send
 return response -> wait the response 
 */

-(NSString*)sendCommand:(NSString*)command timeout:(int)time;


/*
 close Serial-port
 return :close result
 */
-(BOOL)close;




@end
