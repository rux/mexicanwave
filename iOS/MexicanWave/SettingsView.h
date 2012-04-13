//
//  SettingsView.h
//  MexicanWave
//
//  Created by Daniel Anderton on 11/04/2012.
//  Copyright (c) 2012 Yell Group Plc. All rights reserved.
//

#import <UIKit/UIKit.h>

NSString* const kSettingsDidChange;

@interface SettingsView : UIView <UITableViewDataSource,UITableViewDelegate,UIGestureRecognizerDelegate>
@property (retain, nonatomic) IBOutlet UITableView *table;
@property (retain, nonatomic) IBOutlet UIButton *btnYellAppLink;
@property (retain, nonatomic) IBOutlet UIImageView *yellAnimation;

- (IBAction)didTapYellLink:(id)sender;
-(void)animateWave;
@end
