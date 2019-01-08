//
//  SerialPortTool.m
//  Framework
//
//  Created by Robin on 2018/11/11.
//  Copyright © 2018年 RobinCode. All rights reserved.
//

#import "SerialPortTool.h"
#import "ORSSerialPort.h"

@interface SerialPortTool()<ORSSerialPortDelegate>
@property(nonatomic,strong) ORSSerialPort *serialPort;
@property(nonatomic,strong) NSString * reponseEndMark;
@property(nonatomic,strong) NSString * dataReponseEndMark;
@property(nonatomic,strong) NSString*response;
@property(nonatomic,strong) NSMutableString *responseBuffer;
@property(nonatomic,assign) double timeout;

#define KOpened @"Opened"
#define KClosed @"Closed"
#define KInterval 1
#define KTimeoutText @"Error:timeout,Pls check the serial-port"
#define KRemovedText @"Error:Removed,Serial-port removed from system"

@end

@implementation SerialPortTool

-(NSMutableString *)responseBuffer{
     if (_responseBuffer == nil) {
          _responseBuffer = [NSMutableString string];
     }
     return _responseBuffer;
}

-(BOOL)openSerialPortWithPath:(NSString *)path congfig:(NSDictionary *)config{
     self.serialPort = [[ORSSerialPort alloc]initWithPath:path];
     self.reponseEndMark = config[@"reponseEndMark"] == nil?@"\r\n":config[@"reponseEndMark"];
     self.dataReponseEndMark = config[@"dataReponseEndMark"] == nil?@"\r\n":config[@"dataReponseEndMark"];
     self.timeout = config[@"timeout"] == nil ? 2.0:[config[@"timeout"] doubleValue];
     self.serialPort.baudRate = @(115200);
     self.serialPort.delegate = self;
     [self.serialPort open];
    
    CTLog(CTLOG_LEVEL_INFO,@"self.reponseEndMark=%@===========================dataReponseEndMark=%@",self.reponseEndMark,self.dataReponseEndMark);
     
     double timeout = 0.0;
     
     while (1) {
          timeout = timeout + KInterval/1000.0;
          usleep(KInterval*1000);
          if ([self.response containsString:KOpened]||[self.response containsString:KClosed]){
               break;
          }
          
          if (timeout > self.timeout) {
               //NSLog(@"连接超时");
               break;
          }
     }
     
     return self.serialPort.isOpen;
}


-(NSString*)sendCommand:(NSString*)command timeout:(int)time{
     if (![command containsString:@"\r\n"]) {
          command = [NSString stringWithFormat:@"%@\r\n",command];
     }
     NSData *data = [command dataUsingEncoding:NSASCIIStringEncoding];
     self.response = @"";
     [self.serialPort sendData:data];
     double timeout = 0.0;
     self.timeout = time;
     while (1) {
          timeout = timeout + KInterval/1000.0;
          usleep(KInterval*1000);
         
         if ([self.response containsString:self.reponseEndMark]||(self.response.length>=10&&[self.response containsString:@"="])||[self.response containsString:self.dataReponseEndMark]){
             
             CTLog(CTLOG_LEVEL_INFO,@"response=%@",self.response);
             break;
          }
          
          if (timeout > self.timeout) {
               //NSLog(@"连接超时");
               if (self.response.length == 0) {
                 self.response = KTimeoutText;
               }
               break;
          }
     }

     return self.response;
}


-(BOOL)close{
    return  [self.serialPort close];
}


#pragma mark ----ORSSerialPortDelegate-------

-(void)serialPort:(ORSSerialPort *)serialPort didReceiveData:(NSData *)data{
     
     NSString *str=[[NSString alloc]initWithData:data encoding:NSASCIIStringEncoding];
     
     if (str == nil) {
          return;
     }
    
     [self.responseBuffer appendString:str];
//        CTLog(CTLOG_LEVEL_INFO,@"self.reponseEndMark=%@===========================self.responseBuffer=%@",self.reponseEndMark,self.responseBuffer);
//
    
    CTLog(CTLOG_LEVEL_INFO,@"self.reponseEndMark=%@===========================dataReponseEndMark=%@",self.reponseEndMark,self.dataReponseEndMark);
    
    
     if ([self.responseBuffer containsString:self.reponseEndMark]
         ||(self.responseBuffer.length>=10&&[self.responseBuffer containsString:@"="])||[self.responseBuffer containsString:self.dataReponseEndMark]) {
         
          CTLog(CTLOG_LEVEL_INFO,@"--------------------------self.responseBuffer=%@",self.responseBuffer);
         
          self.response = [self.responseBuffer mutableCopy];
          self.responseBuffer = nil;
     }
    
}


-(void)serialPortWasOpened:(ORSSerialPort *)serialPort{
     self.response = KOpened;
}

-(void)serialPortWasRemovedFromSystem:(ORSSerialPort *)serialPort{
     self.response = KRemovedText;
}

@end
