
#import <Foundation/Foundation.h>


#import <Foundation/Foundation.h>
#import <CoreTestFoundation/CoreTestFoundation.h>


@interface WDSyncSocket : NSObject

- (BOOL)connect:(NSString *)ip port:(int)port withTimeout:(double)timeout;
//#########################
/*
 主动连接服务器
 @param  IP : socket 的IP地址
 @param  port : socket 的端口
 @param  timeout : connect 的timeout
 @param  terminator : response返回的结尾
 */

-(BOOL)connectToServerIPAddress:(NSString *)IP port:(int)port timeout:(double)timeout terminator:(NSString*)terminator dataTerminator:(NSString *)dataTerminator;

//#########################
/*断开与服务器的连接*/
-(BOOL)disConnectToServer;


//#########################
//say hello to server, and receive reply from server, if not receive socket is disconnect
/*
 主动连接服务器
 @param  ask : 发给server的询问语句
 @param  reply : server接受到ask之后的回复
 @param  timeout : 发送询问的timeout时间
 @param  repeat : 询问之后timeout时间内server没有回复重复此动作的次数。
 */
-(BOOL)isConnectWithAsk:(NSString*)ask reply:(NSString*)reply timeout:(double)timeout repeat:(int)repeat;

//#########################
/*
 发送命令给服务器
 @param  command : command为发送给服务器的指令
 @param  timeout : 发送command的timeout时间
 */
-(NSString*)sendCommand:(NSString*)command timeout:(double)timeout;

@end
