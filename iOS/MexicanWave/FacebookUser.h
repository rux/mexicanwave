//
//  FacebookUser.h
//  Facebook Friends
//
//  Created by Daniel Anderton on 28/05/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SDWebImageManager.h"

@interface FacebookUser : NSObject <SDWebImageManagerDelegate>

@property(nonatomic,retain) NSString* fullname;
@property(nonatomic,retain) NSString* userID;
@property(nonatomic,retain) NSURL* profileImageURL;
@property(nonatomic,retain) UIImage* profilePhoto;
-(id)initWithDictionary:(NSDictionary*)dict;

@end
