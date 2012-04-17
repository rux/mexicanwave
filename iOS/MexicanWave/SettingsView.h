//
//  SettingsView.h
//  MexicanWave
//
//  Created by Daniel Anderton on 11/04/2012.
//  Copyright (c) 2012 Yell Group Plc. All rights reserved.
//

#import <UIKit/UIKit.h>

NSString* const kSettingsDidChange;
NSString* const kSpeedSegementDidChange;
NSString* const kUserDefaultKeyVibration;
NSString* const kUserDefaultKeySound;

@interface SettingsView : UIView <UITableViewDataSource,UITableViewDelegate,UIGestureRecognizerDelegate>
@property (retain, nonatomic) IBOutlet UITableView *table;

@end
