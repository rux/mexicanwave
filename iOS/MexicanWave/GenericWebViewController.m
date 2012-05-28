//
//  GenericWebViewController.m
//  MexicanWave
//
//  Created by Daniel Anderton on 16/05/2012.
//  Copyright (c) 2012 Yell Group Plc. All rights reserved.
//

#import "GenericWebViewController.h"

@interface GenericWebViewController ()

@end

@implementation GenericWebViewController
@synthesize activityIndicator;
@synthesize webView,url;

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
    [webView loadData:[NSData dataWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Mexican Wave Legal" ofType:@"doc"]] MIMEType:@"application/msword" textEncodingName:@"UTF-8" baseURL:[NSURL URLWithString:@"http://www.yell.com"]];

    
    self.navigationController.navigationBar.translucent = YES;
    
   // [self.webView loadRequest:[NSURLRequest requestWithURL:url]];
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}

- (void)viewDidUnload
{
    [self setWebView:nil];
    [self setActivityIndicator:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)dealloc {
    [url release];
    [webView release];
    [activityIndicator release];
    [super dealloc];
}

-(void)didTapCancel{
    [self dismissModalViewControllerAnimated:YES];
}

#pragma mark UIWebView Delagate

-(void)webViewDidStartLoad:(UIWebView *)webView{
    [self.activityIndicator startAnimating];
}

-(void)webViewDidFinishLoad:(UIWebView *)webView{
    [self.activityIndicator stopAnimating];
}

-(void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error{
     [self.activityIndicator stopAnimating];
    
    UIAlertView* alert = [[UIAlertView alloc]initWithTitle:@"Error" message:[error localizedDescription] delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
    
    [alert show];
    [alert release];
    
}


@end
