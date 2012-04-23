//
//  SettingsView.m
//  MexicanWave
//
//  Created by Daniel Anderton on 11/04/2012.
//  Copyright (c) 2012 Yell Group Plc. All rights reserved.
//

#import "SettingsView.h"
#import "OmnitureLogging.h"
#import "MEXWaveModel.h"
#define kNumberOfSettings 3
#define kSettingsKeyVibration NSLocalizedString(@"Vibration", @"Settings Table row title vibration")
#define kSettingsKeySounds NSLocalizedString(@"Sounds", @"Settings Table row title sounds")
#define kSettingsKeySpeed NSLocalizedString(@"Style", @"Settings Table row title Style")
#define kSettingsVibrationTag 0
#define kSettingsSoundsTag 1
#define kSwitchWidthOffset 20.0f

NSString* const kUserDefaultKeyVibration= @"sound_preference";
NSString* const kUserDefaultKeySound =@"vibration_preference";
NSString* const kSettingsDidChange = @"kSettingsDidChange";
NSString* const kSpeedSegementDidChange = @"kSpeedSegementDidChange";



@interface SettingsView ()
@end

@implementation SettingsView

@synthesize table;
- (void)dealloc {
    [table release];
    [super dealloc];
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

-(void)awakeFromNib{
    [self.table reloadData];
}
#pragma mark TableView Delegates

-(UIView*)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section{
    UILabel *label = [[UILabel alloc] init];
    label.frame = CGRectMake(10, 10, 300, 30);
    label.backgroundColor = [UIColor clearColor];
    label.textColor = [UIColor whiteColor];
    label.shadowColor = [UIColor blackColor];
    label.shadowOffset = CGSizeMake(1.0, 1.0);
    label.font = [UIFont boldSystemFontOfSize:16];
    label.text = NSLocalizedString(@"Wave Effects", @"Settings table header title");
    UIView* header = [[[UIView alloc]initWithFrame:CGRectMake(0, 0, 320, 40)]autorelease];
    header.backgroundColor = [UIColor clearColor];
    [header addSubview:label];
    [label release];
    
    return header;
}

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    return 40.0f;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return kNumberOfSettings;
}

-(UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
        cell.accessoryType = UITableViewCellAccessoryNone;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        //add a switch that enables the user to change the settings
        UISwitch* switchControl = [[[UISwitch alloc]init]autorelease];
        switchControl.tag = 99;
        switchControl.center = CGPointMake(320 - switchControl.frame.size.width*0.5 -kSwitchWidthOffset , cell.frame.size.height*0.5f);
        [switchControl addTarget:self action:@selector(didChangeTableSwitch:) forControlEvents:UIControlEventValueChanged];
        [cell addSubview:switchControl];
    }
    
    if(indexPath.row ==2){
        cell.textLabel.text = kSettingsKeySpeed;
        UISegmentedControl* speedControl = [[[UISegmentedControl alloc]initWithItems:[NSArray arrayWithObjects: NSLocalizedString(@"Fun",@"MEXSegement button title for Fun"),NSLocalizedString(@"Gig",@"MEXSegement button title for Gig"),NSLocalizedString(@"Stadium",@"MEXSegement button title for Stadium"), nil]]autorelease];
        speedControl.segmentedControlStyle = UISegmentedControlStyleBar;
        speedControl.tintColor = [UIColor colorWithWhite:0.45 alpha:1];
        speedControl.selectedSegmentIndex = [[NSUserDefaults standardUserDefaults] integerForKey:MEXWaveSpeedSettingsKey];
        [speedControl sizeToFit];
        [speedControl addTarget:self action:@selector(didTapSegment:) forControlEvents:UIControlEventValueChanged];
        speedControl.center = CGPointMake(300 - 0.5f*speedControl.frame.size.width, cell.frame.size.height*0.5f);
        [cell addSubview:speedControl];
        return cell;
    }
    
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    //get the switch for row and update the  labels and switch from userdefaults
    UISwitch* currentSwitch = (UISwitch*)[cell viewWithTag:99];
    currentSwitch.tag = indexPath.row;
    currentSwitch.on = (indexPath.row == kSettingsVibrationTag) ? [defaults boolForKey:kUserDefaultKeyVibration] : [defaults boolForKey:kUserDefaultKeySound];
    cell.textLabel.text = (indexPath.row == kSettingsVibrationTag) ? kSettingsKeyVibration : kSettingsKeySounds;
    return cell;
}
- (void)didTapSegment:(id)sender {
    const NSUInteger indexOfSegment = ((UISegmentedControl*)sender).selectedSegmentIndex;
    if(indexOfSegment != NSNotFound) {
        [[NSNotificationCenter defaultCenter] postNotificationName:kSpeedSegementDidChange object:[NSNumber numberWithInteger:indexOfSegment]];
    }
}
-(void)didChangeTableSwitch:(UISwitch*)currentSwitch{
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    
    //update the correct nsuserdefault
    if(currentSwitch.tag == kSettingsSoundsTag){
        [defaults setBool:currentSwitch.isOn forKey:kUserDefaultKeySound];
    }
    //if its not sound lets double check its vibration
    else if(currentSwitch.tag == kSettingsVibrationTag){
        [defaults setBool:currentSwitch.isOn forKey:kUserDefaultKeyVibration];
    }
        
    [defaults synchronize];
    [[NSNotificationCenter defaultCenter] postNotificationName:kSettingsDidChange object:nil];
}



/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
