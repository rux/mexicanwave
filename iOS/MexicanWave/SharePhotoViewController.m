//
//  SharePhotoViewController.m
//  MexicanWave
//
//  Created by Daniel Anderton on 16/04/2012.
//  Copyright (c) 2012 Yell Group Plc. All rights reserved.
//

#import "SharePhotoViewController.h"

@implementation SharePhotoViewController
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
    // Do any additional setup after loading the view from its nib.
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
        // Show error message...
        
    }
    else  // No errors
    {
        [self didTapCancel:nil];
    }
}
- (void)viewDidUnload
{
    [self setSnapshotImageView:nil];
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
    [super dealloc];
}
@end
