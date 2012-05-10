//
//  GenericTextViewControllerViewController.h
//  MexicanWave
//
//  Created by Daniel Anderton on 10/05/2012.
//  Copyright (c) 2012 Yell Group Plc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface GenericTextViewController : UIViewController

@property(nonatomic,retain) NSString* textToShow;
@property (retain, nonatomic) IBOutlet UITextView *textView;

@end
