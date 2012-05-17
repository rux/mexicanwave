//
//  GenericWebViewController.h
//  MexicanWave
//
//  Created by Daniel Anderton on 16/05/2012.
//  Copyright (c) 2012 Yell Group Plc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface GenericWebViewController : UIViewController

@property (retain, nonatomic) IBOutlet UIWebView *webView;
@property (nonatomic,retain) NSURL* url;
@end
