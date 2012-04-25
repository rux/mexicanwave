//
//  SettingsView.h
//  MexicanWave
//
//  Created by Daniel Anderton on 11/04/2012.
//  Copyright (c) 2012 Yell Group Plc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UserGuideView.h"

NSString* const kUserDefaultKeyVibration;
NSString* const kUserDefaultKeySound;

@interface SettingsView : UIView <UITableViewDataSource,UITableViewDelegate,UIGestureRecognizerDelegate>
@property (retain, nonatomic) IBOutlet UITableView *table;
@property (retain, nonatomic) IBOutlet UserGuideView *userGuide;

@end
