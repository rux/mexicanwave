//
//  SharePhotoViewController.m
//  MexicanWave
//
//  Created by Daniel Anderton on 16/04/2012.
//  Copyright (c) 2012 Yell Group Plc. All rights reserved.
//

#import "SharePhotoViewController.h"
@implementation SharePhotoViewController
@synthesize progressView;
@synthesize snapshotImageView,takenphoto;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    self.navigationController.navigationBar.barStyle = UIBarStyleBlackTranslucent;
    self.snapshotImageView.image = takenphoto;
    UIBarButtonItem* cancel = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(didTapCancel:)];
    self.navigationItem.leftBarButtonItem = cancel;
    [cancel release];
    
    UIBarButtonItem* share = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(didTapSave:)];
    self.navigationItem.rightBarButtonItem = share;
    [share release];
    
    [super viewDidLoad];
   
    //Set up the HUD for when the user saves a photo - this show a progress via whilst saving the photo.
    progressView = [[ProgressView alloc]initWithFrame:CGRectMake(0, 0, 125, 125)];
    progressView.center = CGPointMake(self.view.frame.size.width*0.5, self.view.frame.size.height*0.5);
    progressView.customImage = [UIImage imageNamed:@"tick"];
    [self.view addSubview:progressView];
       
}

-(void)didTapCancel:(id)sender{
    [self dismissModalViewControllerAnimated:YES];
}

-(void)didTapSave:(id)sender{
    UIAlertView* alert = [[UIAlertView alloc]initWithTitle:NSLocalizedString(@"Save Photo",@"Title of confirmation of sharing photo") message:NSLocalizedString(@"Would you like to save this photo to the camera roll",@"Message body for saving photo to camera roll") delegate:self cancelButtonTitle:NSLocalizedString(@"No Thanks",@"Alert button title to cancel saving photo to camera roll") otherButtonTitles:NSLocalizedString(@"Yes",@"Confirmation of saving photo to camera roll"), nil];
    [alert show];
    [alert release];
}
-(void)alertView:(UIAlertView *)alertView willDismissWithButtonIndex:(NSInteger)buttonIndex{

    if(buttonIndex != alertView.cancelButtonIndex){
        progressView.titleText = NSLocalizedString(@"Saving", @"Title Shown When saving to camera roll");
        [progressView showWithAnimation:YES];
        UIImageWriteToSavedPhotosAlbum(self.takenphoto, self, 
                                       @selector(image:didFinishSavingWithError:contextInfo:), nil);
    }
}
- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error 
  contextInfo:(void *)contextInfo
{
    // Was there an error?
    if (error)
    {
        [progressView hideWithAnimatiom:NO];
        UIAlertView * alert = [[UIAlertView alloc]initWithTitle:NSLocalizedString(@"Save Error", @"Title of saving photo error")  message:NSLocalizedString(@"An error saving your photo has occured. Please try again",@"Message body of saving photo error") delegate:nil cancelButtonTitle:NSLocalizedString(@"Ok",@"Dismiss button of alert view") otherButtonTitles:nil];
        [alert show];
        [alert release];
    }
    else  // No errors
    {
        progressView.titleText = NSLocalizedString(@"Save Successful", @"Completed message shown when save was completed");
        [progressView changeMode:kProgressModeImage];
        [progressView hideWithAnimatiom:YES withDelay:0.8];
    }
}
- (void)viewDidUnload
{
    [self setSnapshotImageView:nil];
    [self setProgressView:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)dealloc {
    [takenphoto release];
    [snapshotImageView release];
    [progressView release];
    [super dealloc];
}
@end
