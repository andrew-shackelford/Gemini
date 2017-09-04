//
//  TodayViewController.m
//  PriceTracker
//
//  Created by Andrew Shackelford on 9/3/17.
//  Copyright © 2017 Golden Dog Productions. All rights reserved.
//

#import "TodayViewController.h"
#import <NotificationCenter/NotificationCenter.h>
#import "PriceFetcher.h"

@interface TodayViewController () <NCWidgetProviding>

@end

@implementation TodayViewController

NSDictionary *priceDict;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    NSArray *keyArray = [[NSArray alloc] initWithObjects:@"BTC", @"ETH", @"USD", @"Total", nil];
    NSArray *objArray = [[NSArray alloc] initWithObjects:[NSNumber numberWithFloat:0.5], [NSNumber numberWithFloat:0.25], [NSNumber numberWithFloat:0.1], [NSNumber numberWithFloat:0.85], nil];
    priceDict = [[NSDictionary alloc] initWithObjects:objArray forKeys:keyArray];
    
    [self currencyControlChanged:self];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)widgetPerformUpdateWithCompletionHandler:(void (^)(NCUpdateResult))completionHandler {
    // Perform any setup necessary in order to update the view.
    
    [self currencyControlChanged:self];
    
    // If an error is encountered, use NCUpdateResultFailed
    // If there's no update required, use NCUpdateResultNoData
    // If there's an update, use NCUpdateResultNewData

    completionHandler(NCUpdateResultNewData);
}

- (IBAction)currencyControlChanged:(id)sender {
    float displayValue = 0.;
    switch ([_currencyControl selectedSegmentIndex]) {
        case 0:
            displayValue = [[priceDict objectForKey:@"BTC"] floatValue];
            break;
        case 1:
            displayValue = [[priceDict objectForKey:@"ETH"] floatValue];
            break;
        case 2:
            displayValue = [[priceDict objectForKey:@"USD"] floatValue];
            break;
        case 3:
            displayValue = [[priceDict objectForKey:@"Total"] floatValue];
            break;
        default:
            break;
    }
    NSString *displayStr = [NSString stringWithFormat:@"%.2f", displayValue];
    [_priceLabel setText:displayStr];
    
}
@end
