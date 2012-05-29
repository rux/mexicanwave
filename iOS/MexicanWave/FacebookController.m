//
//  FacebookController.m
//  Facebook Friends
//
//  Created by Daniel Anderton on 28/05/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "FacebookController.h"
#import "JSON.h"
#import "FacebookUser.h"
#import "FacebookRequest.h"
@implementation FacebookController
@synthesize facebook;
@synthesize facebookRequestQueue,fetching;
static NSString* kAppId = @"223708291010693";

-(void)dealloc{
    [facebook release];
    [facebookRequestQueue release];
    [super dealloc];
}

+ (id)sharedController {
	static dispatch_once_t token;
	static id instance = nil;	
	dispatch_once(&token, ^{ instance = [[self alloc] init]; });
	return instance;		
}

- (id)init {
	if(!(self = [super init])) {
		return nil;
	}
    
    facebook = [[Facebook alloc] initWithAppId:kAppId andDelegate:self];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if ([defaults objectForKey:@"FBAccessTokenKey"] 
        && [defaults objectForKey:@"FBExpirationDateKey"]) {
        facebook.accessToken = [defaults objectForKey:@"FBAccessTokenKey"];
        facebook.expirationDate = [defaults objectForKey:@"FBExpirationDateKey"];
    }
    if (![facebook isSessionValid]) {
        [facebook authorize:nil];
    }  
    facebookRequestQueue = [[NSMutableArray alloc]init];
    
    return self;
}

-(void)facebookRequestWithPath:(NSString*)path withCompletion:(FacebookAPICallBack)callback{
    if (![facebook isSessionValid]) {
        [facebook authorize:nil];
        FacebookRequest* newRequest = [[FacebookRequest alloc]initWithPath:path andBlock:callback];
        [facebookRequestQueue addObject:newRequest];
        [newRequest release];
        return;
    }
    
    FacebookRequest* newRequest = [[FacebookRequest alloc]initWithPath:path andBlock:callback];
    [facebookRequestQueue addObject:newRequest];
    [newRequest release];

    [facebook isSessionValid] ? [self startFacebookRequest] : nil;
}

-(void)startFacebookRequest{
    if(self.isFetching){
        return;
    }
    
    if (![self.facebookRequestQueue count]) {
        return;
    }
    
    self.fetching = YES;
    FacebookRequest* request = (FacebookRequest*)[facebookRequestQueue objectAtIndex:0];
    [facebook requestWithGraphPath:request.path andDelegate:self];
        
}

#pragma mark Facebook Delagates

- (void)fbDidLogin {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:[facebook accessToken] forKey:@"FBAccessTokenKey"];
    [defaults setObject:[facebook expirationDate] forKey:@"FBExpirationDateKey"];
    [defaults synchronize];
    [self startFacebookRequest];
    
}
-(void)fbDidExtendToken:(NSString *)accessToken expiresAt:(NSDate *)expiresAt{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:[facebook accessToken] forKey:@"FBAccessTokenKey"];
    [defaults setObject:[facebook expirationDate] forKey:@"FBExpirationDateKey"];
    [self startFacebookRequest];
    [defaults synchronize];
}
-(void)fbDidLogout{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:nil forKey:@"FBAccessTokenKey"];
    [defaults setObject:nil forKey:@"FBExpirationDateKey"];
    [defaults synchronize];
}
-(void)fbDidNotLogin:(BOOL)cancelled{
    
}
-(void)fbSessionInvalidated{
    
}
- (void)request:(FBRequest *)request didLoadRawResponse:(NSData *)data{
   
    FacebookRequest* fbRequest = (FacebookRequest*)[facebookRequestQueue objectAtIndex:0];
    
    if(!fbRequest.completionBlock){
        [self.facebookRequestQueue removeObject:fbRequest];
        return;
    }
    fbRequest.completionBlock(request,nil,data);
    [self.facebookRequestQueue removeObject:fbRequest];
    self.fetching = NO;
    [self startFacebookRequest];

}

-(void)request:(FBRequest *)request didFailWithError:(NSError *)error{
    FacebookRequest* fbRequest = (FacebookRequest*)[facebookRequestQueue objectAtIndex:0];
    
    
    if(!fbRequest.completionBlock){
        [self.facebookRequestQueue removeObject:fbRequest];
        return;
    }

    fbRequest.completionBlock(request,error,nil);
    [self.facebookRequestQueue removeObject:fbRequest];
    self.fetching = NO;
    [self startFacebookRequest];

}

@end
