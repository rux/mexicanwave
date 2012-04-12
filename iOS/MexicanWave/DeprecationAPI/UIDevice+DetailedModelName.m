//
//  UIDevice+DetailedModelName.m
//  Loyalty
//
//  Created by Tom York on 12/08/2011.
//  Copyright 2011 Yell Group Plc. All rights reserved.
//

#import "UIDevice+DetailedModelName.h"
#include <sys/sysctl.h>


@implementation UIDevice (DetailedModelName)

- (NSString*)detailedModelName {
	// Determine how much space we need to provide to hold the returned machine name.
	size_t responseLength;
	sysctlbyname("hw.machine", NULL, &responseLength, NULL, 0);
	if(responseLength == 0) {
		// Fall back to the -[UIDevice model] call.
		return [self model];
	}
	
	// Allocate enough space to hold the machine name and issue the call to retrieve it.
	char* response = malloc(responseLength);
    sysctlbyname("hw.machine", response, &responseLength, NULL, 0);
	// Construct a NSString from the raw machine name.
    NSString* detailedName = [NSString stringWithCString:response encoding:NSUTF8StringEncoding];
	// Clean up the allocated storage and return the name.
	free(response);
	return detailedName;	
}

@end
