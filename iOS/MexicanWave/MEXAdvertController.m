//
//  MEXAdvertController.m
//  MexicanWave
//
//  Created by Tom York on 25/04/2012.
//  Copyright (c) 2012 Yell Group Plc. All rights reserved.
//

#import "MEXAdvertController.h"
#import "UsageMetrics.h"

#define kNSLocaleKeyUK @"GB"
#define kNSLocaleKeyES @"ES"
#define kNSLocaleKeyUS @"US"

@implementation MEXAdvertController

@synthesize advertButton;
@synthesize hintTextLabel;

- (IBAction)didTapAdvertButton:(id)sender {
    NSString* countryCode = [self countryCodeForCurrentLocale];
    [[UsageMetrics sharedInstance] didFollowDownloadLinkForAppStore:countryCode];
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[self appstoreURLForCountryCode:countryCode]]];    
}

#pragma mark - Lifecycle


- (void)awakeFromNib {
    // Some button setup
    UIImage* background = [self.advertButton backgroundImageForState:UIControlStateNormal];
    UIImage* stretchyBackground = [background stretchableImageWithLeftCapWidth:0.5*background.size.width topCapHeight:0];
    [self.advertButton setBackgroundImage:stretchyBackground forState:UIControlStateNormal];
    
    [self.advertButton setTitle:NSLocalizedString(@"Download the Yell app to start finding", @"Download Yell app Title Button") forState:UIControlStateNormal];
    
    self.advertButton.titleLabel.textAlignment = UITextAlignmentCenter;
    
    // Hide the button if we are not in an area where the advert is useful - i.e outside UK, US, ES
    NSString* appStoreURL = [self appstoreURLForCountryCode:[self countryCodeForCurrentLocale]];
    const BOOL showLink = [[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:appStoreURL]];
    self.advertButton.hidden = !showLink;    
    [[UsageMetrics sharedInstance] didShowMainPageWithDownloadLink:showLink];
    
    hintTextLabel.text = NSLocalizedString(@"Create a mexican wave using your camera flash and capture that moment", @"Hint Text shown on first Launch");
    
    //animate out the text to the user and animate in the Yell advert button
    [UIView animateWithDuration:0.8 delay:7.0 options:UIViewAnimationOptionAllowUserInteraction animations:^{
        hintTextLabel.alpha = 0; 
    } completion:nil];
    
   
    
}
#pragma mark - Locale

- (NSString*)countryCodeForCurrentLocale {
    NSLocale* currentLocale = [NSLocale currentLocale];  // get the current locale.
    return [currentLocale objectForKey:NSLocaleCountryCode]; //get current locale as code.    
}

- (NSString*)appstoreURLForCountryCode:(NSString*)countryCode {    
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

-(void)dealloc{
    [advertButton release];
    [hintTextLabel release];
    [super dealloc];
}
@end
