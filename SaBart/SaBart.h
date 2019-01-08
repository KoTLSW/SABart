/*!
 *	Copyright 2015 Apple Inc. All rights reserved.
 *
 *	APPLE NEED TO KNOW CONFIDENTIAL
 *
 *  SaBart.h
 *  SaBart
 *
 */

 #import <CoreTestFoundation/CoreTestFoundation.h>

@interface SaBart : CTPluginBaseFactory <CTPluginFactory>

- (void)registerBundlePlugins;

@end