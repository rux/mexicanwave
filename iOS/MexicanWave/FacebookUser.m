//
//  FacebookUser.m
//  Facebook Friends
//
//  Created by Daniel Anderton on 28/05/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "FacebookUser.h"
@implementation FacebookUser
@synthesize fullname,profileImageURL,userID,profilePhoto;

-(id)initWithDictionary:(NSDictionary*)dict{
    if(!(self = [super init])) {
		return nil;
	}
    
    if(!dict){
        return nil;
    }
    
    
    self.fullname = [dict valueForKey:@"name"];
    self.userID = [dict valueForKey:@"id"];
    
    if([self.userID length]){
    
        self.profileImageURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://graph.facebook.com/%@/picture",self.userID]];
        [[SDWebImageManager sharedManager] downloadWithURL:self.profileImageURL delegate:self];
    }
    
    return self;
}

-(void)webImageManager:(SDWebImageManager *)imageManager didFinishWithImage:(UIImage *)image{
    self.profilePhoto = image;
}
-(void)dealloc{
    [profilePhoto release];
    [fullname release];
    [userID release];
    [profileImageURL release];
    [super dealloc];
}
@end
