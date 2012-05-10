//
//  GenericTextViewControllerViewController.m
//  MexicanWave
//
//  Created by Daniel Anderton on 10/05/2012.
//  Copyright (c) 2012 Yell Group Plc. All rights reserved.
//

#import "GenericTextViewController.h"

@interface GenericTextViewController ()

@end

@implementation GenericTextViewController
@synthesize textToShow;
@synthesize textView;
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    textView.text = textToShow;
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}

- (void)viewDidUnload
{
    [self setTextView:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

-(void)didTapCancel{
    [self dismissModalViewControllerAnimated:YES];
}
-(void)dealloc{
    [textToShow release];
    [textView release];
    [super dealloc];
}
@end
