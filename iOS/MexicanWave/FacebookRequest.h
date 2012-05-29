//
//  FacebookRequest.h
//  MexicanWave
//
//  Created by Daniel Anderton on 29/05/2012.
//  Copyright (c) 2012 Yell Group Plc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Facebook.h"
typedef void(^FacebookAPICallBack)(FBRequest* request, NSError* error, NSData* data);

@interface FacebookRequest : NSObject

@property (nonatomic,copy) FacebookAPICallBack completionBlock;
@property (nonatomic,retain) NSString* path;

-(id)initWithPath:(NSString*)facebookPath andBlock:(FacebookAPICallBack)completion;

@end
