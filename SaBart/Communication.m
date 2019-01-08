/*!
 *	Copyright 2015 Apple Inc. All rights reserved.
 *
 *	APPLE NEED TO KNOW CONFIDENTIAL
 */

#import "Communication.h"
#import "SerialPortTool.h"
#import "WDSyncSocket.h"
#import "Function.h"
#import "Folder.h"
#import "GetTimeDay.h"




/*----global----*/
#define KCommand   @"Command"
#define KDelay     @"Delay"
#define KDevice    @"Device"
#define KDebug     @"Debug"
#define KTestName  @"TestName"
#define KChoose    @"Choose"
#define KSN        @"SN"
#define KSuffix    @"Suffix"


@interface Communication()

/*
   以下是所有的公共控制
*/
@property(nonatomic,strong)SerialPortTool   * mainBoardPort;
@property(nonatomic,strong)SerialPortTool   * pressBoardPort;
@property(nonatomic,strong)WDSyncSocket     * wdSyncSocket;
@property(nonatomic,strong)Function         * function;
@property(nonatomic,strong)Folder           * fold;
@property(nonatomic,strong)GetTimeDay       * timeDay;



@property(nonatomic,strong)NSString            * mainBoardPortPath;
@property(nonatomic,strong)NSString            * pressBoardPortPath;
@property(nonatomic,strong)NSMutableDictionary * configParams;
@property(nonatomic,strong)NSMutableDictionary * valueDictionary;


//私有的IP地址
@property(nonatomic,strong)NSString         * IPString;
@property(nonatomic,strong)NSString         * PortString;
@property(nonatomic,strong)NSString         * debug;
@property(nonatomic,strong)NSString         * SN;
@property(nonatomic,strong)NSString         * DataPath;
@property(nonatomic,assign)BOOL               TestResult;     //测试的结果
@property(nonatomic,strong)NSString         * PressValue;     //压力值



@end



@implementation Communication

- (instancetype)init
{
    self = [super init];

    if (self)
    {
        // enter initialization code here
    }

    return self;
}



-(NSMutableDictionary *)valueDictionary
{
    if (_valueDictionary == nil) {
        
        _valueDictionary = [[NSMutableDictionary alloc] init];
    }
    
    return _valueDictionary;
}

-(SerialPortTool *)mainBoardPort
{
    if (_mainBoardPort == nil) {
        
        _mainBoardPort = [[SerialPortTool alloc]init];
    }

    return _mainBoardPort;
}


-(SerialPortTool *)pressBoardPort
{
    if (_pressBoardPort == nil) {
        
        _pressBoardPort = [[SerialPortTool alloc] init];
    }

    return _pressBoardPort;
}

-(WDSyncSocket *)wdSyncSocket{
  
    if (_wdSyncSocket == nil) {
        
        _wdSyncSocket = [[WDSyncSocket alloc] init];
    }

    return _wdSyncSocket;
}

-(Folder *)fold{

    if (_fold == nil) {
        
        _fold = [Folder shareInstance];
    }
    
    return _fold;
   
}

-(GetTimeDay *)timeDay{

    if (_timeDay == nil) {
        
        _timeDay = [GetTimeDay shareInstance];
    }
    
    return _timeDay;

}




// For plugins that implement this method, Atlas will log the returned CTVersion
// on plugin launch, otherwise Atlas will log the version info of the bundle
// containing the plugin.
 - (CTVersion *)version
 {
     return [[CTVersion alloc] initWithVersion:@"1"
                           projectBuildVersion:@"1"
                              shortDescription:@"My short description"];
 }



- (BOOL)setupWithContext:(CTContext *)context error:(NSError *__autoreleasing *)error
{
    CTLog(CTLOG_LEVEL_INFO,@"\n---------初始化---------\n");
    //处理方法
    self.function = [[Function alloc] init];
    
    //设置Uart参数
    NSMutableDictionary *parameters = [[NSMutableDictionary alloc] initWithDictionary:context.parameters];
    NSString  * fixtureUart = context.parameters[@"fixtureUart"];
    NSString  * pressUart   = context.parameters[@"pressUart"];
    NSString  * debug       = context.parameters[@"debug"];
    NSString  * ipStr       = context.parameters[@"ip"];
    NSString  * portStr     = context.parameters[@"port"];
    NSString  * path        = context.parameters[@"DataPath"];
    
    //设置串口参数
    [parameters setObject:@"OK@_@" forKey:@"reponseEndMark"];
    [parameters setObject:@"DA@_@" forKey:@"dataReponseEndMark"];
    [parameters setObject:@"2.0" forKey:@"timeout"];
    self.configParams = parameters;
    
    
    //设置
    self.mainBoardPortPath  = fixtureUart;
    self.pressBoardPortPath = pressUart;
    self.debug              = debug;
    self.IPString           = ipStr;
    self.PortString         = portStr;
    self.DataPath           = [NSString stringWithFormat:@"%@/%@/",path,[self.timeDay getCurrentDay]];
    self.TestResult         = YES;
    self.PressValue         = context.parameters[@"PressValue"];
    
    return YES;
}

- (BOOL)teardownWithContext:(CTContext *)context error:(NSError *__autoreleasing *)error
{
    
    if (self.wdSyncSocket) {
        [self.wdSyncSocket disConnectToServer];
        self.wdSyncSocket = nil;
    }
    
    if (self.mainBoardPort) {
        
        [self.mainBoardPort close];
        self.mainBoardPort = nil;
    }
    
    if (self.pressBoardPort) {
        
        [self.pressBoardPort close];
        self.pressBoardPort = nil;
    }
    
   
    return YES;
}



- (CTCommandCollection *)commmandDescriptors
{
    // Collection contains descriptions of all the commands exposed by a plugin
    CTCommandCollection *collection = [CTCommandCollection new];
    
    
    //打开主控制板
    CTCommandDescriptor *command = [[CTCommandDescriptor alloc] initWithName:@"OpenUart" selector:@selector(OpenUart:) description:@"Open Uart"];
    [collection addCommand:command];
    
    //打开压力板
    command =  [[CTCommandDescriptor alloc] initWithName:@"OpenPressUart" selector:@selector(OpenPressUart:) description:@"OpenPressUart"];
    [collection addCommand:command];
    
    
    //控制板初始化各种动作
    command =  [[CTCommandDescriptor alloc] initWithName:@"MainUartInit" selector:@selector(MainUartInit:) description:@"MainUartInit"];
    [collection addCommand:command];
    
    //传递SN
    command =  [[CTCommandDescriptor alloc] initWithName:@"GetSN" selector:@selector(GetSN:) description:@"Get SN"];
    [collection addCommand:command];
    
    
    //打开网口通信
    command =  [[CTCommandDescriptor alloc] initWithName:@"OpenSocket" selector:@selector(OpenSocket:) description:@"Open Socket"];
     [collection addCommand:command];
    
    //读取串口数据
    command = [[CTCommandDescriptor alloc] initWithName:@"ReadSerailPort" selector:@selector(ReadSerailPort:) description:@"ReadSerailPort"];
     [collection addCommand:command];
    
    //读取网口数据
    command = [[CTCommandDescriptor alloc] initWithName:@"LanSendCommand" selector:@selector(LanSendCommand:) description:@"LanSendCommand"];
    [collection addCommand:command];
    
    //读取存储的数据
    command = [[CTCommandDescriptor alloc] initWithName:@"GetFromDictionary" selector:@selector(GetFromDictionary:) description:@"GetFromDictionary"];
    [collection addCommand:command];
    
    //获取测试结果
    command = [[CTCommandDescriptor alloc] initWithName:@"responseTestResult" selector:@selector(responseTestResult:) description:@"responseTestResult"];
    [collection addCommand:command];
    
    
    return collection;
}



#pragma mark-------OpenPort
-(void)OpenUart:(CTTestContext *)context{

    [context runTest:^CTRecordStatus (NSError *__autoreleasing *error) {
        
        //debug模式
        if ([self.debug isEqualToString:@"YES"]) {
            
            context.output = [NSString stringWithFormat:@"%u",arc4random()%100];
            CTLog(CTLOG_LEVEL_ALERT,@"self.debug=%@,OpenUart Success",self.debug);
            return CTRecordStatusPass;
        }
        
        if (self.mainBoardPortPath.length>2) {
            
            while (1) {
                
                BOOL  isMainPortConnect  = [self.mainBoardPort openSerialPortWithPath:self.mainBoardPortPath congfig:self.configParams];
                
                if (isMainPortConnect) {
                    
                    
                    CTLog(CTLOG_LEVEL_ALERT,@"主控板连接成功！");
                    break;
                    
                }
                else{
                    CTLog(CTLOG_LEVEL_INFO, @"主控制板连接失败！");
                }
            }
            
        }
        
        return CTRecordStatusPass;
    }];
}



#pragma mark-------打开压力控制板
-(void)OpenPressUart:(CTTestContext *)context{
    
    
     CTLog(CTLOG_LEVEL_INFO,@"self.pressBoardPortPath HHHHHHHHHH");
   __block int status = 1;
    
    [context runTest:^CTRecordStatus (NSError *__autoreleasing *error) {
        
        
        if (self.pressBoardPortPath.length>2)
        {
  
                for (int i=0;i<500;i++) {
                    
                    [NSThread sleepForTimeInterval:0.01];
                    
                    CTLog(CTLOG_LEVEL_INFO,@"self.pressBoardPortPath = %@",self.pressBoardPortPath);
                    
                    
                    BOOL  isPressPortConnect = [self.pressBoardPort openSerialPortWithPath:self.pressBoardPortPath congfig:self.configParams];
                    
                    if (isPressPortConnect) {
                        
                        CTLog(CTLOG_LEVEL_INFO, @"压力板连接成功！");
                        break;
                    }
                    
                    if (i == 499) {
                        
                        CTLog(CTLOG_LEVEL_INFO, @"压力控制板连接失败！,请检查");
                        
                        status = 0;
                        
                        break;
                    }

                    
                }
        }
        
        if (status == 0) {
            
            return CTRecordStatusError;
        }
    

        return CTRecordStatusPass;
    }];

}


#pragma mark-------初始化控制板动作
-(void)MainUartInit:(CTTestContext *)context{

    [context runTest:^CTRecordStatus (NSError *__autoreleasing *error) {
        //下面的动作
        //1.点亮灯管，发送黄灯
        //2.获取硬件版本
        //3.获取治具ID
        //4.复位控制板
        //5.检测板子是否Ready
        //6.检测门径开关
        //7.检测气缸下压
        //8.将气缸下压到位
        NSArray  *  commands = @[@{@"LED_Out_Yellow":@"OK@_@"},
                                 @{@"ControBoard_Hardware_Version":@"OK@_@"},
                                 @{@"Fixture_ID":@"OK@_@"},
                                 @{@"Reset_Control_PCB":@"OK@_@"},
                                 @{@"Check_Control_PCB_Ready":@"OK@_@"},
                                 @{@"Check_Door":@"OK@_@"},
                                 @{@"Carrier_Hold_Down":@"OK@_@"},
                                 ];
        
        for (int i=0 ;i < [commands count];i++) {
            
            CTLog(CTLOG_LEVEL_ALERT,@"1*******command:i=%d",i);
            NSDictionary  * dic = [commands objectAtIndex:i];
            CTLog(CTLOG_LEVEL_ALERT,@"2*******command:i=%d",i);
            NSString *response;
        
            while (1) {

                [NSThread sleepForTimeInterval:0.2];
                
                response = [self.mainBoardPort sendCommand:[dic allKeys][0] timeout:4];
                
                if ([response containsString:[dic allValues][0]])
                {
                    CTLog(CTLOG_LEVEL_ALERT,@"Success===Command:%@,response:%@",[dic allKeys][0],response);
                    
                    break;
                }
                else
                {
                    CTLog(CTLOG_LEVEL_ALERT,@"Fail===Command:%@,response:%@",[dic allKeys][0],response);
                    //return CTRecordStatusError;
                    
                }
            }
            
            CTLog(CTLOG_LEVEL_ALERT,@"command:i=%d",i);
            
            if(i == [commands count] -1){
                
                CTLog(CTLOG_LEVEL_ALERT,@"%@",@"MainUartInit 初始化完成");
                break;
            }
            
            
            
        }

        
         [NSThread sleepForTimeInterval:1];
    
            while (1) {
                
                [NSThread sleepForTimeInterval:0.2];
                
                NSString * response = [self.mainBoardPort sendCommand:@"Check_Hold_Down" timeout:4];
                
                if ([response containsString:@"OK@_@"])
                {
                      CTLog(CTLOG_LEVEL_ALERT,@"下压已经到位");
                    break;
                }
                else
                {
                    CTLog(CTLOG_LEVEL_ALERT,@"下压未到位");
                    
                }
            }
        
        return CTRecordStatusPass;
    }];

}

#pragma mark-------获取SN
-(void)GetSN:(CTTestContext *)context{

    
    [context runTest:^CTRecordStatus (NSError *__autoreleasing *error) {
        
        self.SN = context.parameters[KSN];
        CTLog(CTLOG_LEVEL_INFO,@"GetSN:context.output = %@",self.SN);
        
        self.DataPath = [NSString stringWithFormat:@"%@%@",self.DataPath,self.SN];
        //生成文件夹的路径
        if ([self.fold Folder_Creat:self.DataPath]) {
            
            CTLog(CTLOG_LEVEL_ALERT,@"文件夹创建成功=%@",self.DataPath);
        }
        
        return CTRecordStatusPass;
    }];

    
    
}



#pragma mark--------读取port数据
-(void)ReadSerailPort:(CTTestContext *)context{
    
    if ([context.parameters[KDevice] containsString:@"FIXPRESSDevice"]) {
        
        [self sendCommandWithDevice:self.pressBoardPort command:context.parameters[KCommand] context:context isPress:YES];
    }else{
        
        [self sendCommandWithDevice:self.mainBoardPort command:context.parameters[KCommand] context:context isPress:NO];
    }
}



#pragma mark-------OpenSocket
-(void)OpenSocket:(CTTestContext *)context{
    
    [context runTest:^CTRecordStatus (NSError *__autoreleasing *error) {

        //debug模式@
        if ([self.debug isEqualToString:@"YES"]) {
            context.output = [NSString stringWithFormat:@"%u",arc4random()%100];
            CTLog(CTLOG_LEVEL_ALERT,@"self.debug=%@,OpenSocket Success",self.debug);
            return CTRecordStatusPass;
        }
    
        while (1) {
            
            BOOL  isSocketConnect  = [self.wdSyncSocket connectToServerIPAddress:self.IPString port:[self.PortString intValue] timeout:1.0 terminator:@"OK@_@" dataTerminator:@"DA@_@"];
            
            if (isSocketConnect) {
                 CTLog(CTLOG_LEVEL_ALERT,@"网络连接成功！");
                
                 //复位测试板子
                NSString * resetCommand = [self.wdSyncSocket sendCommand:@"Reset_Test_PCB()" timeout:1.0];
                
                CTLog(CTLOG_LEVEL_ALERT,@"resetCommand=========%@",resetCommand);
                
                if ([resetCommand containsString:@"Reset_Test_PCB() OK@_@\r\n"]) {
                    
                      CTLog(CTLOG_LEVEL_ALERT,@"测试板复位成功！");
                    
                       break;
                }
                else
                {
                       CTLog(CTLOG_LEVEL_ALERT,@"测试板复位失败！");
                }
                
                //检测测试板是否Ready=======此指令没反应
                NSString * readyCommand = [self.wdSyncSocket sendCommand:@"Check_Test_PCB_Ready()" timeout:1.0];
                if ([readyCommand containsString:@"Check_Test_PCB_Ready() OK@_@\r\n"]) {
                    
                    CTLog(CTLOG_LEVEL_ALERT,@"测试板已经准备OK！");
                    break;
                }
                else
                {
                    CTLog(CTLOG_LEVEL_ALERT,@"测试板没有准备好！");
                }
            }
            else{
                
                    CTLog(CTLOG_LEVEL_ALERT,@"网络连接失败！");
            }
         }
        
        return CTRecordStatusPass;
    }];
}



#pragma mark-------LanSendCommand
-(void)LanSendCommand:(CTTestContext *)context{
    
    float delay = [context.parameters[KDelay] floatValue];
    NSString  * testName      =  context.parameters[KTestName];
    NSString  * command       =  context.parameters[KCommand];
    NSString  * Suffix        =  context.parameters[KSuffix];
    
    
    
    CTLog(CTLOG_LEVEL_INFO,@"Socket testName Before in Plugin:%@,command:%@,suffix=%@",testName,command,Suffix);

    
    [context runTest:^CTRecordStatus (NSError *__autoreleasing *error) {
        
        
        if ([self.debug isEqualToString:@"YES"]) {
            
            context.output = [NSString stringWithFormat:@"%u",arc4random()%100];
            //将数据存储到plist文件中
            if ([context.parameters[KChoose] isEqualToString:@"WriteToPlist"]) {
                
                CTLog(CTLOG_LEVEL_INFO,@"Debug:testName = %@;KChoose=%@;WriteToPlist",testName,context.parameters[KChoose]);
            }
            //将数据存储到字典中
            if ([context.parameters[KChoose] isEqualToString:@"SaveToDictionary"]) {
                
                CTLog(CTLOG_LEVEL_INFO,@"testName = %@;KType=%@;SaveToDictionary",testName,context.parameters[KChoose]);
                
                NSString  * backStr = [NSString stringWithFormat:@"%@ 50 10 5 11 DA@_@\r\n",command];
                
                NSString  * simpleResponse = [self.function rangeofString:backStr Prefix:[NSString stringWithFormat:@"%@ ",command] Suffix:@" DA@_@\r\n"];
                
                CTLog(CTLOG_LEVEL_INFO,@"testName = %@,simpleResponse = %@",testName,simpleResponse);
                
                NSArray   *  arr =[simpleResponse componentsSeparatedByString:@" "];
                
                CTLog(CTLOG_LEVEL_INFO,@"arr:%lu",(unsigned long)[arr count]);
                
                [self.valueDictionary setObject:arr[0] forKey:[NSString stringWithFormat:@"%@_MAX",testName]];
                [self.valueDictionary setObject:arr[1] forKey:[NSString stringWithFormat:@"%@_MIN",testName]];
                [self.valueDictionary setObject:arr[2] forKey:[NSString stringWithFormat:@"%@_VPP",testName]];
                [self.valueDictionary setObject:arr[3] forKey:[NSString stringWithFormat:@"%@_STD",testName]];
                CTLog(CTLOG_LEVEL_INFO,@"Debug:value insert into Dictionary:%@",self.valueDictionary);
            }
            return CTRecordStatusPass;
        }
        
        
        //正式发送数据
        NSString *response=[self.wdSyncSocket sendCommand:context.parameters[KCommand] timeout:4];
        usleep(delay*1000);
        CTLog(CTLOG_LEVEL_INFO,@"Socket SendCommand After:%@  response in Plugin:%@",context.parameters[KCommand],response);
        
        if([response containsString:@"DA@_@"]){
            
            //将数据存储到plist文件中
            if ([context.parameters[KChoose] isEqualToString:@"WriteToPlist"]) {
                
                 CTLog(CTLOG_LEVEL_INFO,@"1111111111111111111111111");
                
                CTLog(CTLOG_LEVEL_INFO,@"WriteToPlist:testName = %@;KType=%@",testName,context.parameters[KChoose]);
                
                [response writeToFile:[NSString stringWithFormat:@"%@/%@_%@.txt",self.DataPath,testName,self.SN] atomically:YES encoding:NSUTF8StringEncoding error:nil];
            }
            
            //将数据存储到字典中
            else if([context.parameters[KChoose] isEqualToString:@"SaveToDictionary"]) {
                
                CTLog(CTLOG_LEVEL_INFO,@"2222222222222222222222222");
                
                NSString  * simpleResponse = [self.function rangeofString:response Prefix:[NSString stringWithFormat:@"%@ ",command] Suffix:@" DA@_@\r\n"];
                
           
                
                NSArray   *  arr =[simpleResponse componentsSeparatedByString:@" "];
                
                CTLog(CTLOG_LEVEL_INFO,@"arr count:%lu,1==%@,2=%@,3=%@,4=%@",(unsigned long)[arr count],arr[0],arr[1],arr[2],arr[3]);
                [self.valueDictionary setObject:arr[0] forKey:[NSString stringWithFormat:@"%@_MAX",testName]];
                [self.valueDictionary setObject:arr[1] forKey:[NSString stringWithFormat:@"%@_MIN",testName]];
                [self.valueDictionary setObject:arr[2] forKey:[NSString stringWithFormat:@"%@_VPP",testName]];
                [self.valueDictionary setObject:arr[3] forKey:[NSString stringWithFormat:@"%@_STD",testName]];
                
            }
            else{
                
                CTLog(CTLOG_LEVEL_INFO,@"3333333333333333333333333333333");
                
                context.output = [self.function rangeofString:response Prefix:[NSString stringWithFormat:@"%@ ",command] Suffix:@" DA@_@\r\n"];
                [self GetTestResult:context];
                CTLog(CTLOG_LEVEL_INFO,@"返回====数据，以DA@_@结尾:response=%@",response);
            }
            
            
        }
        else if ([response containsString:@"OK@_@"]){
            
            CTLog(CTLOG_LEVEL_INFO,@"返回====数据，以OK@_@结尾:response=%@",response);
        }
        else{
            return CTRecordStatusError;
            
        }
        
        return CTRecordStatusPass;
    }];
    
}


#pragma mark---------GetFromDictionary
-(void)GetFromDictionary:(CTTestContext *)context{
   
    [context runTest:^CTRecordStatus (NSError *__autoreleasing *error) {
        
        if ([self.debug isEqualToString:@"YES"]) {
            
            NSString  * testName = context.parameters[KTestName];
            context.output = [self.valueDictionary objectForKey:testName];
            CTLog(CTLOG_LEVEL_INFO,@"context.output = %@",context.output);
            //context.output = [NSString stringWithFormat:@"%u",arc4random()%100];
            return CTRecordStatusPass;
        }
        
        NSString  * testName = context.parameters[KTestName];
        context.output = [self.valueDictionary objectForKey:testName];
        //判断测试结果
        [self GetTestResult:context];
        
        return CTRecordStatusPass;
    }];
    
}



#pragma mark ----Private Function called by self---------

-(void)sendCommandWithDevice:(SerialPortTool*)device command:(NSString*)command context:(CTTestContext*)context isPress:(BOOL)isOK{
    
    float delay = [context.parameters[KDelay] floatValue];
    
    NSString  * suffix = context.parameters[KSuffix];
    
    CTLog(CTLOG_LEVEL_INFO,@"command in Plugin:%@,current device:%@,suffix=%@",command,device,suffix);
    
    /*---- 检查位，有些串口动作需要用相应的字符串判断指令是否执行成功,如果这个数值不为nil,需要做判断 */
    
    [context runTest:^CTRecordStatus(NSError *__autoreleasing *failureInfo) {
    
        if ([self.debug isEqualToString:@"YES"]) {
            
            CTLog(CTLOG_LEVEL_INFO,@"Debug,sendCommandWithDevice");
            context.output = [NSString stringWithFormat:@"%u",arc4random()%100];
            
            return CTRecordStatusPass;
        }
        
        if (isOK) {
            
            while (1) {
                
                usleep(delay*1000);
                NSString *response=[device sendCommand:command timeout:2.0];
                usleep(delay*1000);
                CTLog(CTLOG_LEVEL_INFO,@"response in Plugin:%@",response);
                
                float value = [[response substringFromIndex:2] floatValue];
                
                if (value >[self.PressValue floatValue]) {
                    
                    context.output = [NSString stringWithFormat:@"%f",value];
                    break;
                }
            }
            
        }else
        {
            CTLog(CTLOG_LEVEL_INFO,@"MainBoard send Command：%@；suffix=%@",command,suffix);
            NSString *response=[device sendCommand:command timeout:8.0];
            usleep(delay*1000);
            CTLog(CTLOG_LEVEL_INFO,@"MainBoard receive response：%@；suffix=%@",response,suffix);
            context.output = response;
            
        }
        
         return CTRecordStatusPass;
     
    }];
}


#pragma mark----------------增加判断测试结果方法
-(void)GetTestResult:(CTTestContext*)context{
    
       CTLog(CTLOG_LEVEL_INFO,@"Print testName:%@,Max=%@,Min=%@",context.parameters[KTestName],context.parameters[@"Max"],context.parameters[@"Min"]);
    
        if (([context.output floatValue]<[context.parameters[@"Min"] floatValue])||
            ([context.output floatValue]>[context.parameters[@"Max"] floatValue])) {
            
            self.TestResult = NO;
        }
}


#pragma mark-----------------点亮灯光
-(void)responseTestResult:(CTTestContext*)context{

    [context runTest:^CTRecordStatus(NSError *__autoreleasing *failureInfo) {
        
        if (self.TestResult) { //发送绿灯
            
            [self.mainBoardPort sendCommand:@"LED_Out_Green" timeout:1.0];
            
        }
        else{//发送红灯
            
            
            [self.mainBoardPort sendCommand:@"LED_Out_Red" timeout:1.0];
            
        }
        return CTRecordStatusPass;
        
     }];
}
@end
