//
//  PriceWriter.h
//  Gemini
//
//  Created by Andrew Shackelford on 10/12/17.
//  Copyright © 2017 Golden Dog Productions. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PriceWriter : NSObject

@property (nonatomic, strong) NSDictionary *priceData;
@property (readwrite, nonatomic) float btcPrice;
@property (readwrite, nonatomic) float ethPrice;

- (void) updateBtcPrice: (float)newPrice;
- (void) updateEthPrice: (float)newPrice;

@end
