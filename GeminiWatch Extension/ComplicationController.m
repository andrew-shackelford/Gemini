//
//  ComplicationController.m
//  GeminiWatch Extension
//
//  Created by Andrew Shackelford on 9/4/17.
//  Copyright © 2017 Golden Dog Productions. All rights reserved.
//

#import "ComplicationController.h"
#import "PriceFetcher.h"

@interface ComplicationController ()

@end

@implementation ComplicationController

#pragma mark - Timeline Configuration

- (void)getSupportedTimeTravelDirectionsForComplication:(CLKComplication *)complication withHandler:(void(^)(CLKComplicationTimeTravelDirections directions))handler {
    handler(CLKComplicationTimeTravelDirectionForward|CLKComplicationTimeTravelDirectionBackward);
}

- (void)getTimelineStartDateForComplication:(CLKComplication *)complication withHandler:(void(^)(NSDate * __nullable date))handler {
    handler(nil);
}

- (void)getTimelineEndDateForComplication:(CLKComplication *)complication withHandler:(void(^)(NSDate * __nullable date))handler {
    handler(nil);
}

- (void)getPrivacyBehaviorForComplication:(CLKComplication *)complication withHandler:(void(^)(CLKComplicationPrivacyBehavior privacyBehavior))handler {
    handler(CLKComplicationPrivacyBehaviorShowOnLockScreen);
}

#pragma mark - Timeline Population

- (void)getCurrentTimelineEntryForComplication:(CLKComplication *)complication withHandler:(void(^)(CLKComplicationTimelineEntry * __nullable))handler {
    CLKComplicationTimelineEntry* entry = nil;
    NSDate* now = [NSDate date];
    
    PriceFetcher *fetcher = [[PriceFetcher alloc] init];
    NSDictionary *priceDict = [fetcher getPrices];
    float bitcoinAmount = [[priceDict objectForKey:@"BTC"] floatValue];
    float ethereumAmount = [[priceDict objectForKey:@"ETH"] floatValue];
    float cashAmount = [[priceDict objectForKey:@"USD"] floatValue];
    
    
    // Create the template and timeline entry.
    if (complication.family == CLKComplicationFamilyModularSmall) {
        // Modular Small Complication
        CLKComplicationTemplateModularSmallColumnsText* textTemplate =
        [[CLKComplicationTemplateModularSmallColumnsText alloc] init];
        textTemplate.row1Column1TextProvider = [CLKSimpleTextProvider textProviderWithText:@"BC"];
        textTemplate.row1Column2TextProvider = [CLKSimpleTextProvider
                                                textProviderWithText:[NSString stringWithFormat:@"%.2f", bitcoinAmount]];
        textTemplate.row2Column1TextProvider = [CLKSimpleTextProvider textProviderWithText:@"EH"];
        textTemplate.row2Column2TextProvider = [CLKSimpleTextProvider
                                                textProviderWithText:[NSString stringWithFormat:@"%.2f", ethereumAmount]];
        
        // Create the entry.
        entry = [CLKComplicationTimelineEntry entryWithDate:now
                                       complicationTemplate:textTemplate];
    } else if (complication.family == CLKComplicationFamilyModularLarge) {
        // Modular Large Complication
        CLKComplicationTemplateModularLargeColumns* textTemplate =
        [[CLKComplicationTemplateModularLargeColumns alloc] init];
        textTemplate.row1Column1TextProvider = [CLKSimpleTextProvider textProviderWithText:@"BTC"];
        textTemplate.row1Column2TextProvider = [CLKSimpleTextProvider
                                                textProviderWithText:[NSString stringWithFormat:@"$%.2f", bitcoinAmount]];
        textTemplate.row2Column1TextProvider = [CLKSimpleTextProvider textProviderWithText:@"ETH"];
        textTemplate.row2Column2TextProvider = [CLKSimpleTextProvider
                                                textProviderWithText:[NSString stringWithFormat:@"$%.2f", ethereumAmount]];
        textTemplate.row3Column1TextProvider = [CLKSimpleTextProvider textProviderWithText:@"USD"];
        textTemplate.row3Column2TextProvider = [CLKSimpleTextProvider
                                                textProviderWithText:[NSString stringWithFormat:@"$%.2f", cashAmount]];
        
        entry = [CLKComplicationTimelineEntry entryWithDate:now complicationTemplate:textTemplate];
    } else {
        // ...configure entries for other complication families.
    }
    
    
    // Call the handler with the current timeline entry
    handler(entry);
}

- (void)getTimelineEntriesForComplication:(CLKComplication *)complication beforeDate:(NSDate *)date limit:(NSUInteger)limit withHandler:(void(^)(NSArray<CLKComplicationTimelineEntry *> * __nullable entries))handler {
    // Call the handler with the timeline entries prior to the given date
    handler(nil);
}

- (void)getTimelineEntriesForComplication:(CLKComplication *)complication afterDate:(NSDate *)date limit:(NSUInteger)limit withHandler:(void(^)(NSArray<CLKComplicationTimelineEntry *> * __nullable entries))handler {
    // Call the handler with the timeline entries after to the given date
    handler(nil);
}

#pragma mark - Placeholder Templates

- (void)getLocalizableSampleTemplateForComplication:(CLKComplication *)complication withHandler:(void(^)(CLKComplicationTemplate * __nullable complicationTemplate))handler {
    // This method will be called once per supported complication, and the results will be cached
    handler(nil);
}

@end
