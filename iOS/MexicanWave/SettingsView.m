//
//  SettingsView.m
//  MexicanWave
//
//  Created by Daniel Anderton on 11/04/2012.
//  Copyright (c) 2012 Yell Group Plc. All rights reserved.
//

#import "SettingsView.h"
#import "OmnitureLogging.h"

#define kNumberOfSettings 2
#define kSettingsKeyVibration NSLocalizedString(@"Vibration", @"Settings Table row title vibration")
#define kSettingsKeySounds NSLocalizedString(@"Sounds", @"Settings Table row title sounds")
#define kUserDefaultKeySound @"sound_preference"
#define kUserDefaultKeyVibration @"vibration_preference"
#define kSettingsVibrationTag 0
#define kSettingsSoundsTag 1
#define kNSLocaleKeyUK @"GB"
#define kNSLocaleKeyES @"ES"
#define kNSLocaleKeyUS @"US"
#define kSwitchWidthOffset 20.0f

NSString* const kSettingsDidChange = @"kSettingsDidChange";

@interface SettingsView ()
-(NSString*)appstoreURLForCurrentLocale;
-(void)commonInitialisation;
@end

@implementation SettingsView

@synthesize btnYellAppLink;
@synthesize table;
- (void)dealloc {
    [table release];
    [btnYellAppLink release];
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
    [self commonInitialisation];
}

-(void)commonInitialisation{

    btnYellAppLink.titleLabel.numberOfLines = 2;
    btnYellAppLink.titleLabel.lineBreakMode = UILineBreakModeWordWrap;
    btnYellAppLink.titleLabel.textAlignment = UITextAlignmentCenter;
    [btnYellAppLink setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [btnYellAppLink setTitleShadowColor:[UIColor blackColor] forState:UIControlStateNormal];

    //if we are in a geography we have an app present it
    if([[self appstoreURLForCurrentLocale] length]){
        [[OmnitureLogging sharedInstance] postEventLinkIsVisible];
        btnYellAppLink.hidden = NO;
        [btnYellAppLink setTitle:NSLocalizedString(@"Download The Yell App\n to start finding",@"Yell tag line button Link to appstore") forState:UIControlStateNormal];
    }

}

#pragma mark TableView Delegates

-(UIView*)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section{
    UILabel *label = [[UILabel alloc] init];
    label.frame = CGRectMake(10, 10, 300, 30);
    label.backgroundColor = [UIColor clearColor];
    label.textColor = [UIColor whiteColor];
    label.shadowColor = [UIColor blackColor];
    label.shadowOffset = CGSizeMake(0.0, 1.0);
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
    
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    
    //get the switch for row and update the  labels and switch from userdefaults
    UISwitch* currentSwitch = (UISwitch*)[cell viewWithTag:99];
    currentSwitch.tag = indexPath.row;
    currentSwitch.on = (indexPath.row == kSettingsVibrationTag) ? [defaults boolForKey:kUserDefaultKeyVibration] : [defaults boolForKey:kUserDefaultKeySound];
    cell.textLabel.text = (indexPath.row == kSettingsVibrationTag) ? kSettingsKeyVibration : kSettingsKeySounds;
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
    
    [defaults synchronize];
    [[NSNotificationCenter defaultCenter] postNotificationName:kSettingsDidChange object:nil];
}

- (IBAction)didTapYellLink:(id)sender {
    [[OmnitureLogging sharedInstance] postEventLinkPressed];
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[self appstoreURLForCurrentLocale]]];
}

-(NSString*)appstoreURLForCurrentLocale{
    NSLocale* currentLocale = [NSLocale currentLocale];  // get the current locale.
    NSString* countryCode = [currentLocale objectForKey:NSLocaleCountryCode]; //get current locale as code.
    
    //compare codes to get correct url for app store.
    if([countryCode isEqualToString:kNSLocaleKeyUK]){
        return @"http://itunes.apple.com/gb/app/yell-search-find-local-uk/id329334877?mt=8";
    }
    else if([countryCode isEqualToString:kNSLocaleKeyUS]){
        return @"http://itunes.apple.com/us/app/us-yellow-pages/id306599340?mt=8";
    }
    else if([countryCode isEqualToString:kNSLocaleKeyES]){
        return @"http://itunes.apple.com/es/app/paginasamarillas.es-cerca/id303686830?mt=8";
    }
    
    return nil;
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
