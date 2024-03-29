//
//  FacebookViewController.m
//  MexicanWave
//
//  Created by Daniel Anderton on 29/05/2012.
//  Copyright (c) 2012 Yell Group Plc. All rights reserved.
//

#import "FacebookViewController.h"
#import "FacebookController.h"
#import "FacebookUser.h"
#import "JSON.h"
#import "UIImageView+WebCache.h"
#import "SettingsView.h"
#import "QuartzCore/QuartzCore.h"
@interface FacebookViewController ()
@property(nonatomic,retain) NSMutableArray* facebookUsers;
@property(nonatomic,retain) NSMutableArray* selectedUsers;
@property(nonatomic,retain) FacebookUser *userProfile;
@property(nonatomic,retain) UIView* loadingView;
@property(nonatomic,retain) UITableView* tableView;
-(void)fetchFriends;
-(void)shouldShowLoadingScreen:(BOOL)loading;

@end

@implementation FacebookViewController
@synthesize facebookUsers,userProfile,selectedUsers,loadingView;
@synthesize tableView;

-(void)dealloc{
    [tableView release];
    [facebookUsers release];
    [selectedUsers release];
    [userProfile release];
    [loadingView release];
    [super dealloc];
}


- (void)viewDidLoad
{
    
    tableView = [[UITableView alloc]initWithFrame:self.view.bounds];
    tableView.dataSource = self;
    tableView.delegate = self;
    [self.view addSubview:tableView];
    [super viewDidLoad];

    // Uncomment the following line to preserve selection between presentations.
    
      
    UIBarButtonItem* save = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(didTapSave)];
    self.navigationItem.rightBarButtonItem = save;
    [save release];
    
    UIBarButtonItem* cancel = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(didTapCancel)];
    self.navigationItem.leftBarButtonItem = cancel;
    [cancel release];

    selectedUsers = [[NSMutableArray alloc]init];
    
    
}


-(void)shouldShowLoadingScreen:(BOOL)loading{
    if(!loadingView){
        loadingView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, 100, 100)];
        loadingView.backgroundColor = [UIColor blackColor];
        loadingView.alpha = 0; 
        loadingView.layer.cornerRadius = 10.0f;
        
        UIActivityIndicatorView* activity = [[UIActivityIndicatorView alloc]initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        activity.center = loadingView.center;
        [activity startAnimating];
        [loadingView addSubview:activity];
        loadingView.center = CGPointMake(self.view.frame.size.width*0.5, self.view.frame.size.height*0.5);
        
        [self.view insertSubview:loadingView aboveSubview:self.tableView];
    }
 
    if(loading){
        [UIView animateWithDuration:0.2 animations:^{
            loadingView.alpha = 1; 
        }];
    }
    else {
        [UIView animateWithDuration:0.3 animations:^{
            loadingView.alpha = 0; 
        }];
    }

}

-(void)viewWillAppear:(BOOL)animated{
    [self didTapReload];
}
-(void)didTapCancel{
    [self dismissModalViewControllerAnimated:YES];
    [[NSNotificationCenter defaultCenter] postNotificationName:kCustomCactusImagesDidChange object:nil];
}

-(void)didTapSave{
    
    [self dismissViewControllerAnimated:YES completion:^{
        NSMutableArray* images = [NSMutableArray array];
        for (NSIndexPath* indexPath in selectedUsers){
            FacebookUser* user = (FacebookUser*)[facebookUsers objectAtIndex:indexPath.row];
            [images addObject:UIImagePNGRepresentation(user.profilePhoto)];
        }
        [images insertObject:UIImagePNGRepresentation(userProfile.profilePhoto) atIndex:0];
        [[NSUserDefaults standardUserDefaults] setObject:images forKey:kUserDefaultKeyCustomCactusImages];
        [[NSNotificationCenter defaultCenter] postNotificationName:kCustomCactusImagesDidChange object:nil];
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kUserDefaultKeyCustomCactus];

    }];
}

-(void)didTapReload{
    [self shouldShowLoadingScreen:YES];
    [[FacebookController sharedController] facebookRequestWithPath:@"me" withCompletion:^(FBRequest *request, NSError *error, NSData *data) {
        
        if(error){
            UIAlertView* alert = [[UIAlertView alloc]initWithTitle:NSLocalizedString(@"Error", @"Title for Error on Alert View") message:NSLocalizedString(@"An error has occured, Would you like to try again?",@"Message shown on Facebook Error Alert") delegate:self cancelButtonTitle:@"No" otherButtonTitles:NSLocalizedString(@"OK", @"Dismiss button of alert view"),nil];
            [alert show];
            [alert release];
            
            return;
        }
        
        NSString* response = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
        id jsonResponse = [response JSONValue];
        [response release];
        
        userProfile = [[FacebookUser alloc]initWithDictionary:(NSDictionary*)jsonResponse];
        [[self tableView] reloadData];
        [self shouldShowLoadingScreen:NO];

    }];
    
    [self fetchFriends];

   
}
-(void)fetchFriends{
    if(!facebookUsers){
        facebookUsers = [[NSMutableArray alloc]init];
    }
    [self shouldShowLoadingScreen:YES];

    [[FacebookController sharedController] facebookRequestWithPath:@"me/friends" withCompletion:^(FBRequest *request, NSError *error, NSData *data) {
        
        if(error){
            UIAlertView* alert = [[UIAlertView alloc]initWithTitle:NSLocalizedString(@"Error", @"Title for Error on Alert View") message:NSLocalizedString(@"An error has occured, Would you like to try again?",@"Message shown on Facebook Error Alert") delegate:self cancelButtonTitle:@"No" otherButtonTitles:NSLocalizedString(@"OK", @"Dismiss button of alert view"),nil];
            [alert show];
            [alert release];
                        
            return;
        }
        
        [facebookUsers removeAllObjects];
        [selectedUsers removeAllObjects];
        NSString* response = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
        id jsonResponse = [response JSONValue];
        
        
        if([jsonResponse isKindOfClass:[NSDictionary class]]){
            NSArray* dataResponse = [(NSDictionary*)jsonResponse valueForKey:@"data"];
            
            
            for(NSDictionary* user in dataResponse){
                FacebookUser* newUser = [[FacebookUser alloc]initWithDictionary:user];
                [facebookUsers addObject:newUser];
                [newUser release];
            }
        }
        
        [response release];
        [self.tableView reloadData];
        [self shouldShowLoadingScreen:NO];
    }];

}

-(NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
    
    if(section == 1 && [facebookUsers count]){
        return NSLocalizedString(@"Choose your friends",@"Table View header for choosing facebook Profile");
    }
    
    return userProfile ? NSLocalizedString(@"Your Profile",@"Facebook table Header for your profie") : @"";
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    if(section == 0){
        return userProfile ? 1 :0;
    }
    return [facebookUsers count];
}

- (UITableViewCell *)tableView:(UITableView *)table cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [table dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier] autorelease];
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    
    
     if(indexPath.section == 0){
         cell.selectionStyle = UITableViewCellSelectionStyleNone;
         cell.accessoryType = UITableViewCellAccessoryCheckmark;
         cell.textLabel.text = userProfile.fullname;
         [cell.imageView setImageWithURL:userProfile.profileImageURL placeholderImage:[UIImage imageNamed:@"placeholder"]];
         return cell;
     }
    
    FacebookUser* user  = (FacebookUser*)[facebookUsers objectAtIndex:indexPath.row];
    cell.accessoryType = UITableViewCellAccessoryNone;
    cell.textLabel.text = user.fullname;
    [cell.imageView setImageWithURL:user.profileImageURL placeholderImage:[UIImage imageNamed:@"placeholder"]];
    cell.selectionStyle = UITableViewCellSelectionStyleBlue;    
    
    for (NSIndexPath* path in selectedUsers){
        if(path.row == indexPath.row){
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
        }
    }
    
    return cell;
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)table didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    if(indexPath.section ==0){
        return;
    }
    
    
    UITableViewCell* cell = [table cellForRowAtIndexPath:indexPath];
    
    if(cell.accessoryType == UITableViewCellAccessoryNone){
        
        if([selectedUsers count]==4){
            UIAlertView* alert = [[UIAlertView alloc]initWithTitle:NSLocalizedString(@"Oops",@"Title shown when user has tapped to many friends") message:NSLocalizedString(@"You can only add 4 friends",@"Alert Body for when the user has selected too many friends") delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
            [alert show];
            [alert release];
            return;   
        }
        
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
        [selectedUsers addObject:indexPath];
    }
    else{
        cell.accessoryType = UITableViewCellAccessoryNone;
        [selectedUsers removeObject:indexPath];
    }
    
   
}

-(void)alertView:(UIAlertView *)alertView willDismissWithButtonIndex:(NSInteger)buttonIndex{
    if(alertView.cancelButtonIndex == buttonIndex){
        [self didTapCancel];
    }
    else {
        [self didTapReload];
    }
    
}

@end
