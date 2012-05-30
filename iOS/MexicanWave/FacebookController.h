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
-(void)facebookRequestWithPath:(NSString*)path withCompletion:(FacebookAPICallBack)callback; // Add a request to the queue - Path relates to FB Graph API 
@property(nonatomic,retain) Facebook* facebook;



@end
