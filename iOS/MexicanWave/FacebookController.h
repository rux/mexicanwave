//
//  FacebookController.h
//  Facebook Friends
//
//  Created by Daniel Anderton on 28/05/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Facebook.h"
#import "FacebookRequest.h"

@interface FacebookController : NSObject <FBSessionDelegate, FBRequestDelegate>

+ (id)sharedController;
-(void)startFacebookRequest;
-(void)facebookRequestWithPath:(NSString*)path withCompletion:(FacebookAPICallBack)callback;

@property(nonatomic,retain)NSMutableArray* facebookRequestQueue;
@property(nonatomic,retain) Facebook* facebook;
@property(nonatomic,getter = isFetching) BOOL fetching;

@end
