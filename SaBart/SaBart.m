/*!
 *	Copyright 2015 Apple Inc. All rights reserved.
 *
 *	APPLE NEED TO KNOW CONFIDENTIAL
 *
 *  SaBart.h
 *  SaBart
 *
 */

#import "SaBart.h"
#import "Communication.h"

@implementation SaBart

- (void)registerBundlePlugins
{
	[self registerPluginName:@"Communication" withPluginCreator:^id<CTPluginProtocol>(){
		return [[Communication alloc] init];
	}];
}

@end
