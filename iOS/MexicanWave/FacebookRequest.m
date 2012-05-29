//
//  FacebookRequest.m
//  MexicanWave
//
//  Created by Daniel Anderton on 29/05/2012.
//  Copyright (c) 2012 Yell Group Plc. All rights reserved.
//

#import "FacebookRequest.h"

@implementation FacebookRequest
@synthesize path,completionBlock;


-(id)initWithPath:(NSString*)facebookPath andBlock:(FacebookAPICallBack)completion{
    if(!(self = [super init])) {
        return nil;
    }

    self.path = facebookPath;
    self.completionBlock = completion;

    return self;
}

-(void)dealloc{
    [path release];
    [super dealloc];
}
@end
