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

/*Facebook Graph API Docs can be found: https://developers.facebook.com/tools/explorer
 SDK can be found at https://developers.facebook.com/docs/reference/iossdk/
 */

static NSString* kAppId = @"223708291010693";

@interface FacebookController()

@property(nonatomic,retain)NSMutableArray* facebookRequestQueue;
@property(nonatomic,retain) Facebook* facebook;
@property(nonatomic,getter = isFetching) BOOL fetching;

-(void)startFacebookRequests; 

@end


@implementation FacebookController
@synthesize facebook;
@synthesize facebookRequestQueue,fetching;

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
    
    
    //Set up facebook
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
    
    //if we are not authized - add the current request to the queue and go authoize
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

    [self startFacebookRequests];
    
}

-(void)startFacebookRequests{
    /*
     Check if we are already completing a request
     Make sure there is requests in th queue
     Take the first item of the queue and request its path with facebook
     */
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
    [self startFacebookRequests];
    
}

-(void)fbDidExtendToken:(NSString *)accessToken expiresAt:(NSDate *)expiresAt{
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:[facebook accessToken] forKey:@"FBAccessTokenKey"];
    [defaults setObject:[facebook expirationDate] forKey:@"FBExpirationDateKey"];
    [self startFacebookRequests];
    [defaults synchronize];
}

-(void)fbDidLogout{
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:nil forKey:@"FBAccessTokenKey"];
    [defaults setObject:nil forKey:@"FBExpirationDateKey"];
    [defaults synchronize];
}

-(void)fbDidNotLogin:(BOOL)cancelled{
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:nil forKey:@"FBAccessTokenKey"];
    [defaults setObject:nil forKey:@"FBExpirationDateKey"];
    [self startFacebookRequests];
    [defaults synchronize];
}

-(void)fbSessionInvalidated{
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:nil forKey:@"FBAccessTokenKey"];
    [defaults setObject:nil forKey:@"FBExpirationDateKey"];
    [self startFacebookRequests];
    [defaults synchronize];
}

- (void)request:(FBRequest *)request didLoadRawResponse:(NSData *)data{
   
    //Find the request - and send the response through the completion handler
    FacebookRequest* fbRequest = (FacebookRequest*)[facebookRequestQueue objectAtIndex:0];
    
    if(fbRequest.completionBlock){
        fbRequest.completionBlock(request,nil,data);
    }
        
    [self.facebookRequestQueue removeObject:fbRequest];
    self.fetching = NO;
    [self startFacebookRequests];

}

-(void)request:(FBRequest *)request didFailWithError:(NSError *)error{
    
    FacebookRequest* fbRequest = (FacebookRequest*)[facebookRequestQueue objectAtIndex:0];
        
    if(fbRequest.completionBlock){
        fbRequest.completionBlock(request,error,nil);
    }

    fbRequest.completionBlock(request,error,nil);
    [self.facebookRequestQueue removeObject:fbRequest];
    self.fetching = NO;
    [self startFacebookRequests];

}

@end
