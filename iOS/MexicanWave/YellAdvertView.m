//
//  YellAdvertView.m
//  MexicanWave
//
//  Created by Daniel Anderton on 18/04/2012.
//  Copyright (c) 2012 Yell Group Plc. All rights reserved.
//

#import "YellAdvertView.h"
#import "UsageMetrics.h"

#define kScaleFactor 0.92f

#define kNSLocaleKeyUK @"GB"
#define kNSLocaleKeyES @"ES"
#define kNSLocaleKeyUS @"US"

@implementation YellAdvertView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self commonInitialisation];
    }
    return self;
}
-(void)awakeFromNib{
    [self commonInitialisation];
}

-(void)commonInitialisation{
    self.backgroundColor = [UIColor clearColor];
    
    //add the uiimage to our control
    UIImageView* advertImage = [[UIImageView alloc]initWithImage:[UIImage imageNamed:@"Yell-Advert.png"]];
    advertImage.frame = CGRectMake(0, 0, 250, 54);
    [self addSubview:advertImage];
    [advertImage release];
    
    //hide oursleves if we are not in an area where the advert is usefull - i.e outside UK, US, ES
    NSString* appStoreURL = [self appstoreURLForCountryCode:[self countryCodeForCurrentLocale]];
    if([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:appStoreURL]]) {
        self.hidden = NO;
        [[UsageMetrics sharedInstance] didShowDownloadLink];
    }
    else {
        self.hidden = YES;        
    }
    [self addTarget:self action:@selector(didTapYellLink:) forControlEvents:UIControlEventTouchUpInside];
    
}

- (void)setHighlighted:(BOOL)highlighted {
    [super setHighlighted:highlighted];
    
    if(highlighted) {
        self.transform = CGAffineTransformMakeScale(kScaleFactor, kScaleFactor);
    }
    else {
        self.transform = CGAffineTransformIdentity;
    }
}

- (NSString*)countryCodeForCurrentLocale {
    NSLocale* currentLocale = [NSLocale currentLocale];  // get the current locale.
    return [currentLocale objectForKey:NSLocaleCountryCode]; //get current locale as code.    
}

-(NSString*)appstoreURLForCountryCode:(NSString*)countryCode {    
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

- (void)didTapYellLink:(id)sender {
    NSString* countryCode = [self countryCodeForCurrentLocale];
    [[UsageMetrics sharedInstance] didFollowDownloadLinkForAppStore:countryCode];
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[self appstoreURLForCountryCode:countryCode]]];
}
@end
