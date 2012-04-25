//
//  Metrics.h
//  MexicanWave
//
//  Created by Daniel Anderton on 12/04/2012.
//  Copyright (c) 2012 Yell Group Plc. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 Metrics tracking wrapper so we can change the service underneath without impacting the metricsed code.
 */
@interface UsageMetrics : NSObject

+ (UsageMetrics*)sharedInstance;                                    //!< Singleton for easy access.
- (void)didShowMainPageWithDownloadLink:(BOOL)showsDownloadLink;    //!< Event is posted when the app screen is visable
- (void)didFollowDownloadLinkForAppStore:(NSString*)appStore;       //!< Event is posted when the user taps the download link for the Yell store
@end
