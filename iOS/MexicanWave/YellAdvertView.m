//
//  YellAdvertView.m
//  MexicanWave
//
//  Created by Daniel Anderton on 18/04/2012.
//  Copyright (c) 2012 Yell Group Plc. All rights reserved.
//

#import "YellAdvertView.h"
#import "OmnitureLogging.h"
#define kScaleFactor 0.92f

#define kNSLocaleKeyUK @"GB"
#define kNSLocaleKeyES @"ES"
#define kNSLocaleKeyUS @"US"
@implementation YellAdvertView

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
    self.backgroundColor = [UIColor clearColor];
    
    //add the uiimage to our control
    UIImageView* advertImage = [[UIImageView alloc]initWithImage:[UIImage imageNamed:@"Yell-Advert.png"]];
    advertImage.frame = CGRectMake(0, 0, 250, 54);
    [self addSubview:advertImage];
    [advertImage release];
    
    //hide oursleves if we are not in an area where the advert is usefull - i.e outside UK, US, ES
    self.hidden = [[self appstoreURLForCurrentLocale]length] ? NO : YES;   
    !self.hidden ? [[OmnitureLogging sharedInstance] postEventLinkIsVisible] : nil;
    [self addTarget:self action:@selector(didTapYellLink:) forControlEvents:UIControlEventTouchUpInside];
    
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/
- (void)setHighlighted:(BOOL)highlighted {
    [super setHighlighted:highlighted];
    
    if(highlighted) {
        self.transform = CGAffineTransformMakeScale(kScaleFactor, kScaleFactor);
    }
    else {
        self.transform = CGAffineTransformIdentity;
    }
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
- (void)didTapYellLink:(id)sender {
    [[OmnitureLogging sharedInstance] postEventLinkPressed];
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[self appstoreURLForCurrentLocale]]];
}
@end
