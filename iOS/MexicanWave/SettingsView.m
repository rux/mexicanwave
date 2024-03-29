//
//  SettingsView.m
//  MexicanWave
//
//  Created by Daniel Anderton on 11/04/2012.
//  Copyright (c) 2012 Yell Group Plc. All rights reserved.
//

#import "SettingsView.h"
#import "UsageMetrics.h"
#import "MEXWaveModel.h"
#import "MEXAppDelegate.h"
#import "MEXWavingViewController.h"

#define kSettingsKeyVibration NSLocalizedString(@"Vibration", @"Settings Table row title vibration")
#define kSettingsKeySounds NSLocalizedString(@"Sounds", @"Settings Table row title sounds")
#define kSettingsKeyStadium NSLocalizedString(@"Stadium", @"Settings Table row title Style")
#define kSettingsKeyLegal NSLocalizedString(@"Legal", @"The label text shown in the Legal button on the main settings page")
#define kSettingsKeyVersion NSLocalizedString(@"Version", @"The label text shown in the version display on the main settings page")
#define kSettingsKeyGameMode NSLocalizedString(@"Game Mode",@"Title for Game Mode")
#define kSettingsKeyCustomCactus NSLocalizedString(@"Custom Cactus",@"Title for Custom Cactus")


#define kSettingsVibrationTag 0
#define kSettingsSoundsTag 1
#define kSettingsStadiumTag 2
#define kSettingsGameModeTag 3
#define kSettingsCustomCactusTag 4
#define kSwitchWidthOffset 20.0f

NSString* const kUserDefaultKeyVibration = @"sound_preference";
NSString* const kUserDefaultKeySound = @"vibration_preference";
NSString* const kUserDefaultKeyGameMode = @"gameMode";
NSString* const kUserDefaultKeyCustomCactus = @"customCactus";
NSString* const kUserDefaultKeyCustomCactusImages = @"customCactusImages";
NSString* const kSpeedSegementDidChange = @"kSpeedSegementDidChange";
NSString* const kGameModeDidChange = @"kGameModeDidChange";
NSString* const kCustomCactusImagesDidChange = @"kCustomCactusImagesDidChange";

@interface SettingsView ()

@property(nonatomic,retain) NSArray* userSettingOptions;
@property(nonatomic,retain) NSArray* appOptions;

@end

@implementation SettingsView

@synthesize table,userSettingOptions,appOptions;
- (void)dealloc {
    [appOptions release];
    [userSettingOptions release];
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
    
    self.userSettingOptions= [NSArray arrayWithObjects:kSettingsKeyVibration,kSettingsKeySounds,kSettingsKeyStadium,kSettingsKeyGameMode,kSettingsKeyCustomCactus, nil];
    NSString* version = [NSString stringWithFormat:@"%@: %@",kSettingsKeyVersion,[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"]];
    self.appOptions= [NSArray arrayWithObjects:kSettingsKeyLegal,version, nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didTapReload) name:kCustomCactusImagesDidChange object:nil];

    [self.table reloadData];
}


-(void)didTapReload{
    [self.table reloadData];
}
#pragma mark TableView Delegates

-(UIView*)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section{
    
    if(section !=0){
        return nil;
    }
    
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
    return section == 0 ? [userSettingOptions count] : [appOptions count];
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 2;
}

-(UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
        cell.textLabel.font = [UIFont boldSystemFontOfSize:17];
    }
    
        
    cell.textLabel.text = indexPath.section == 0 ? [userSettingOptions objectAtIndex:indexPath.row] : [appOptions objectAtIndex:indexPath.row];
    cell.accessoryType = (indexPath.section == 1 && indexPath.row == 0) ? UITableViewCellAccessoryDisclosureIndicator : UITableViewCellAccessoryNone;
    cell.selectionStyle = (indexPath.section == 1 && indexPath.row == 0) ? UITableViewCellSelectionStyleBlue : UITableViewCellSelectionStyleNone;
    
     
    if(indexPath.section == 1){
        return cell;
    }
    
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    UISwitch* switchControl = [[[UISwitch alloc]init]autorelease];
    switchControl.tag = indexPath.row;
    switchControl.center = CGPointMake(320 - switchControl.frame.size.width*0.5 -kSwitchWidthOffset , cell.frame.size.height*0.5f);
    [switchControl addTarget:self action:@selector(didChangeTableSwitch:) forControlEvents:UIControlEventValueChanged];
    [cell addSubview:switchControl];
        
    cell.accessoryType = UITableViewCellAccessoryNone;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;   
    const BOOL speedSelection = ([[[NSUserDefaults standardUserDefaults] valueForKey:MEXWaveSpeedSettingsKey] integerValue] == 0) ? NO : YES;

    switch (indexPath.row) {
        case kSettingsVibrationTag:
            switchControl.on = [defaults boolForKey:kUserDefaultKeyVibration];
            break;
        case kSettingsSoundsTag:
            switchControl.on = [defaults boolForKey:kUserDefaultKeySound];
            break;
        case kSettingsStadiumTag:
            switchControl.on = speedSelection;
            break; 
        case kSettingsGameModeTag:
            switchControl.on = [defaults boolForKey:kUserDefaultKeyGameMode];
            break; 
        case kSettingsCustomCactusTag:
            switchControl.on = [defaults boolForKey:kUserDefaultKeyCustomCactus];
            break; 
    }
    
    return cell;
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
    else if(currentSwitch.tag == kSettingsStadiumTag){
        const NSInteger selection = currentSwitch.isOn ? 2 : 0;
        [[NSNotificationCenter defaultCenter] postNotificationName:kSpeedSegementDidChange object:[NSNumber numberWithInteger:selection]];
    }
    else if(currentSwitch.tag == kSettingsGameModeTag){
        [defaults setBool:currentSwitch.isOn forKey:kUserDefaultKeyGameMode];
        [[NSNotificationCenter defaultCenter] postNotificationName:kGameModeDidChange object:nil];
        if(currentSwitch.isOn){
            UIAlertView* alert = [[UIAlertView alloc]initWithTitle:NSLocalizedString(@"Game Mode",@"Title for Game Mode") message:NSLocalizedString(@"Tap the screen in time to make your cactus be part of the wave", @"Hint Text shown on first Launch for Game Mode")
 delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", @"Dismiss button of alert view") otherButtonTitles:nil];
            [alert show];
            [alert release];       
        }
        
    }
    
    else if(currentSwitch.tag == kSettingsCustomCactusTag){
        
        if(currentSwitch.isOn){

            UIAlertView* alert = [[UIAlertView alloc]initWithTitle:NSLocalizedString(@"Use Facebook Profile Photos",@"Title for Custom Catucs Alert View") message:NSLocalizedString(@"Would you like to replace the cactuses with a photo of you and your friends?", @"Hint Text when changing custom cactus") delegate:self cancelButtonTitle:NSLocalizedString(@"No", @"Dismiss button of alert view") otherButtonTitles:NSLocalizedString(@"Yes", "@Confirmation of alertView"),nil];
            alert.tag = kSettingsCustomCactusTag;
            [alert show];
            [alert release];   
        }
        else{
            [defaults setBool:currentSwitch.isOn forKey:kUserDefaultKeyCustomCactus];
            [[NSUserDefaults standardUserDefaults] setObject:nil forKey:kUserDefaultKeyCustomCactusImages];
            [[NSNotificationCenter defaultCenter] postNotificationName:kCustomCactusImagesDidChange object:nil];
        }
    }

    
        
    [defaults synchronize];
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    
    if(indexPath.row == 0 && indexPath.section == 1){   
        
        MEXAppDelegate* appDelagate = (MEXAppDelegate*)[[UIApplication sharedApplication] delegate];
        [appDelagate.viewController didTapLegelButton:self];
        
    }
}

-(void)alertView:(UIAlertView *)alertView willDismissWithButtonIndex:(NSInteger)buttonIndex{
    if(alertView.tag == kSettingsCustomCactusTag && alertView.cancelButtonIndex != buttonIndex){
        MEXAppDelegate* appDelagate = (MEXAppDelegate*)[[UIApplication sharedApplication] delegate];
        [appDelagate.viewController didTapFacebook:self];
    }
    
    [self.table reloadData];
}


@end
