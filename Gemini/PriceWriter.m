//
//  PriceWriter.m
//  Gemini
//
//  Created by Andrew Shackelford on 10/12/17.
//  Copyright © 2017 Golden Dog Productions. All rights reserved.
//

#import "PriceWriter.h"

@implementation PriceWriter

@synthesize priceData;
@synthesize btcPrice;
@synthesize ethPrice;

- (id) init {
    self = [super init];
    if (self)
    {
        NSString *destPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
        destPath = [destPath stringByAppendingPathComponent:@"prices.plist"];
        
        // If the file doesn't exist in the Documents Folder, copy it.
        NSFileManager *fileManager = [NSFileManager defaultManager];
        
        if (![fileManager fileExistsAtPath:destPath]) {
            NSString *sourcePath = [[NSBundle mainBundle] pathForResource:@"prices" ofType:@"plist"];
            [fileManager copyItemAtPath:sourcePath toPath:destPath error:nil];
        }
        
        // Load the Property List.
        priceData = [[NSMutableDictionary alloc] initWithContentsOfFile:destPath];
        
        btcPrice = [[priceData objectForKey:@"BTC"] floatValue];
        ethPrice = [[priceData objectForKey:@"ETH"] floatValue];
    }
    return self;
}

- (void) updateBtcPrice: (float)newPrice {
    self.btcPrice = newPrice;
    NSString *destPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    destPath = [destPath stringByAppendingPathComponent:@"prices.plist"];
    priceData = [[NSMutableDictionary alloc] initWithContentsOfFile:destPath];
    [priceData setValue:[NSNumber numberWithFloat:newPrice] forKey:@"BTC"];
    [priceData writeToFile:destPath atomically:YES];
}

- (void) updateEthPrice: (float)newPrice {
    self.ethPrice = newPrice;
    NSString *destPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    destPath = [destPath stringByAppendingPathComponent:@"prices.plist"];
    priceData = [[NSMutableDictionary alloc] initWithContentsOfFile:destPath];
    [priceData setValue:[NSNumber numberWithFloat:newPrice] forKey:@"ETH"];
    [priceData writeToFile:destPath atomically:YES];
}

@end
