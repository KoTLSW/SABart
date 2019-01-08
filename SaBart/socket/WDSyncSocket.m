
//

#import "WDSyncSocket.h"
#import <sys/socket.h>
#import <netinet/in.h>
#import <arpa/inet.h>
#import <sys/types.h>
#include <sys/time.h>
#include <unistd.h>
#include <fcntl.h>
#include <stdio.h>
#include <errno.h>
#include <netdb.h>
#include <stdlib.h>
#include <sys/types.h>

@interface WDSyncSocket ()

@property (nonatomic, assign) int clientSocket;
@property (nonatomic,assign) BOOL isConnect;
@property (nonatomic,copy) NSString *terminator;
@property (nonatomic,strong)NSString * dataTerminator;

@property (nonatomic,copy) NSString *ip;
@property (nonatomic, assign) int port;

@end

@implementation WDSyncSocket
//1.连接服务器
- (BOOL)connect:(NSString *)ip port:(int)port withTimeout:(double)timeout{
    //创建socket
    int clientSocket= socket(AF_INET, SOCK_STREAM, IPPROTO_TCP);
    
    self.clientSocket = clientSocket;
    self.ip = ip;
    self.port = port;
    
    struct sockaddr_in addr;
    addr.sin_family = AF_INET;
    addr.sin_addr.s_addr = inet_addr(ip.UTF8String);
    addr.sin_port = htons(port);
    /*
     struct timeval timeo={3,0};
     socklen_t len =sizeof(timeo);
     */
    
    //setsockopt(clientSocket, SOL_SOCKET, SO_RCVTIMEO, &timeo, len);
    
    if (connect_nonb(clientSocket,(const struct sockaddr *) &addr, sizeof(addr), timeout)<0) {
        NSLog(@"connect fail:");
        self.isConnect=false;
        return false;
    }
    NSLog(@"connect success!\n");
    self.isConnect=true;
    return true;
    
    /*
     addr.sin_family = AF_INET;
     addr.sin_addr.s_addr = inet_addr(ip.UTF8String);
     addr.sin_port = htons(port);
     int result = connect(clientSocket, (const struct sockaddr *) &addr, sizeof(addr));
     if (result == 0) {
     return YES;
     }else{
     return NO;
     }
     */
}
//1.发送和接受数据
- (NSString *)sendAndRecv:(NSString *)sendMsg withTimeout:(double)timeout{
    
    NSString  * originMsg = [sendMsg copy];
    //向服务器发送数据
    sendMsg = [NSString stringWithFormat:@"%@\r\n",sendMsg];
    
    const char *msg = sendMsg.UTF8String;
    //##当server 挂掉的时候（比如闪退关闭等等）
    
    sigset_t set;
    sigemptyset(&set);
    sigaddset(&set, SIGPIPE);
    sigprocmask(SIG_BLOCK, &set, NULL);
    //成功发送返回发送的字节数, 失败返回-1
    ssize_t sendCount = send(self.clientSocket, msg, strlen(msg), 0);
    NSLog(@"发送的字节数%zd", sendCount);
    
    //接受服务器返回的数据
    //返回的是实际接受的字节个数
    
    /*
     struct sockaddr_in peer_addr;
     socklen_t addr_len = sizeof(peer_addr);
     reinterpret_cast
     int recv_len = 0;
     char buf[1024];
     bzero(buf, sizeof(buf));
     
     fd_set reasfds;
     FD_ZERO(&reasfds);
     FD_SET(self.clientSocket, &reasfds);
     struct timeval timeout_val;
     timeout_val.tv_sec = 5;
     timeout_val.tv_usec = 0;
     int ret = select(self.clientSocket+1, &reasfds, NULL, NULL, &timeout_val);
     if (ret > 0) {
     
     recv_len = recvfrom(self.clientSocket, buf, sizeof(buf), 0,
     reinterpret_cast<const struct sockaddr *>(&peer_addr),
     &addr_len);
     if (recv_len < 0)
     printf("recvfrom err, errno=%d\n", errno);
     } else if (ret == 0) {
     printf("recvfrom timeout\n");
     } else {
     printf("select err, errno=%d\n", errno);
     }
     return 0;
     
     */
    
    struct timeval timeo={timeout,0};
    socklen_t len =sizeof(timeo);
    setsockopt(self.clientSocket, SOL_SOCKET, SO_RCVTIMEO, &timeo, len);
    
    NSMutableString *response = [NSMutableString string];
    
    while (1) {
        uint8_t buffer[1024];
        ssize_t recvCount = recv(self.clientSocket, buffer, sizeof(buffer),0);
        NSLog(@"接收的字节数%zd", recvCount);
        
        /* */
        //recvCount = recv(self.clientSocket, buffer, sizeof(buffer),0);
        //NSLog(@"接收的字节数%zd", recvCount);
          /* */
        
        NSLog(@"errno:%d",errno);
        
        if (sendCount==-1&&errno==EPIPE) {
            self.isConnect=false;
            [self closeSocket];
            return @"Timeout! Can't get Response From Robot,The Socket is DisConnect!";
        }
        /*
         if(recvCount==-1&&errno==EAGAIN)
         {
         printf("timeout\n");
         NSString *timeout=@"Timeout! Can't get Response From Robot";
         return timeout;
         
         }
         */
        if (recvCount==0) {
            response=[NSMutableString stringWithFormat:@"Timeout! Can't get Response From Robot,The Socket is DisConnect!"];
            [self closeSocket];
            self.isConnect=false;
            return response;
        }
        if(recvCount==-1)
        {
            printf("timeout\n");
            if (response.length==0) {
                response=[NSMutableString stringWithFormat:@"Timeout! Can't get Response From Robot"];
            }else
            {
                [response insertString:@"Timeout! The Response is:" atIndex:0];
            }
            return response;
            
        }
        
        
        NSData *data = [NSData dataWithBytes:buffer length:recvCount];
        NSString *recvMsg = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        //response=[NSMutableString stringWithFormat:@"%@",recvMsg];
        [response appendString:recvMsg];
        
         CTLog(CTLOG_LEVEL_INFO,@"Before:WDSyncSocketet 返回数据:%@,self.terminator=%@,self.dataTerminator=%@",response,self.terminator,self.dataTerminator);
        if ([response containsString:originMsg]&&([response containsString:self.terminator]
            ||[response containsString:self.dataTerminator]))
        {
            
            CTLog(CTLOG_LEVEL_INFO,@"After:WDSyncSocketet 返回数据:%@",response);
            return  response;
        }
    }
}



int connect_nonb(int sockfd, const struct sockaddr *addr, socklen_t addrlen, int nsec)
{
    int flags, n, error;
    socklen_t len;
    fd_set rset, wset;
    struct timeval tval;
    
    /* 调用fcntl把套接字设置为非阻塞 */
    flags = fcntl(sockfd, F_GETFL, 0);
    fcntl(sockfd, F_SETFL, flags | O_NONBLOCK);
    
    /* 发起非阻塞connect。期望的错误是EINPROGRESS，表示连接建立已经启动但是尚未完成  */
    error = 0;
    if ( (n = connect(sockfd, addr, addrlen)) < 0)
        if (errno != EINPROGRESS)
            return(-1);
    
    /* 如果非阻塞connect返回0，那么连接已经建立。当服务器处于客户端所在主机时这种情况可能发生 */
    if (n == 0)
        goto done; /* connect completed immediately */
    
    /* 调用select等待套接字变为可读或可写，如果select返回0，那么表示超时 */
    FD_ZERO(&rset);
    FD_SET(sockfd, &rset);
    wset = rset;
    tval.tv_sec = nsec;
    tval.tv_usec = 0;
    
    if ( (n = select(sockfd+1, &rset, &wset, NULL, nsec ? &tval : NULL)) == 0) {
        close(sockfd); /* timeout */
        errno = ETIMEDOUT;
        return(-1);
    }
    
    /* 检查可读或可写条件，调用getsockopt取得套接字的待处理错误，如果建立成功，该值将为0 */
    if (FD_ISSET(sockfd, &rset) || FD_ISSET(sockfd, &wset)) {
        len = sizeof(error);
        if (getsockopt(sockfd, SOL_SOCKET, SO_ERROR, &error, &len) < 0)
            return(-1); /* Solaris pending error */
    } else {
        perror("select error: sockfd not set");
        exit(1);
    }
    
    /* 恢复套接字的文件状态标志并返回 */
done:
    fcntl(sockfd, F_SETFL, flags); /* restore file status flags */
    if (error) {
        close(sockfd); /* just in case */
        errno = error;
        return(-1);
    }
    return(0);
}


-(BOOL)disConnectToServer
{
    BOOL isColsed=[self closeSocket];
    if (isColsed) {
        self.isConnect=false;
        NSLog(@"关闭了socket");
    }
    return isColsed;

}
-(BOOL)closeSocket
{
    //int isSucess= shutdown(self.clientSocket, 2);
    int isSucess = close(self.clientSocket);
    if (isSucess) {
        return true;
    }else
    {
        return false;
    }
}



-(NSString*)sendCommand:(NSString*)command timeout:(double)timeout
{
    usleep(10*1000);
    if (!self.isConnect) {
        [self closeSocket];
        usleep(10*1000);
        [self connectToServerIPAddress:self.ip port:self.port timeout:1 terminator:self.terminator dataTerminator:self.dataTerminator];
        usleep(10*1000);
        if (!self.isConnect) {
           return @"Socket is DisConnect!";
        }
    }
    return [self sendAndRecv:command withTimeout:timeout];

}
-(BOOL)connectToServerIPAddress:(NSString *)IP port:(int)port timeout:(double)timeout terminator:(NSString *)terminator dataTerminator:(NSString *)dataTerminator
{
    self.terminator=terminator;
    self.dataTerminator = dataTerminator;
    return [self connect:IP port:port withTimeout:timeout];
}



-(BOOL)isConnectWithAsk:(NSString *)ask reply:(NSString *)reply timeout:(double)timeout repeat:(int)repeat
{
    if (!self.isConnect) {
        return false;
    }
    //向服务器发送数据
    const char *msg = ask.UTF8String;
    //##当server 挂掉的时候（比如闪退关闭等等）
    
    sigset_t set;
    sigemptyset(&set);
    sigaddset(&set, SIGPIPE);
    sigprocmask(SIG_BLOCK, &set, NULL);
    //成功发送返回发送的字节数, 失败返回-1
    ssize_t sendCount = send(self.clientSocket, msg, strlen(msg), 0);
    NSLog(@"发送的字节数%zd", sendCount);
    
    
    if (sendCount==-1&&errno==EPIPE) {
        self.isConnect=false;
        [self closeSocket];
        return false;
    }
    
    struct timeval timeo={timeout,0};
    socklen_t len =sizeof(timeo);
    setsockopt(self.clientSocket, SOL_SOCKET, SO_RCVTIMEO, &timeo, len);
    NSMutableString *response;
    
    while (1) {
        repeat--;
        uint8_t buffer[1024];
        ssize_t recvCount = recv(self.clientSocket, buffer, sizeof(buffer),0);
        NSLog(@"接收的字节数%zd", recvCount);
        NSLog(@"errno:%d",errno);
        if (recvCount==0) {
            self.isConnect=false;
            [self closeSocket];
            return false;
        }
        if(recvCount==-1)
        {
            if (repeat==0) {
                 self.isConnect=false;
                 return false;;
            }
        }else
        {
            NSData *data = [NSData dataWithBytes:buffer length:recvCount];
            NSString *recvMsg = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            response=[NSMutableString stringWithFormat:@"%@",recvMsg];
            if ([response containsString:[NSString stringWithFormat:@"%@",reply]]) {
                return  true;
            }
        
        }


    }
 
}


@end
