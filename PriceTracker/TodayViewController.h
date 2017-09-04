//
//  TodayViewController.h
//  PriceTracker
//
//  Created by Andrew Shackelford on 9/3/17.
//  Copyright © 2017 Golden Dog Productions. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TodayViewController : UIViewController

@property (weak, nonatomic) IBOutlet UISegmentedControl *currencyControl;
- (IBAction)currencyControlChanged:(id)sender;
@property (weak, nonatomic) IBOutlet UILabel *priceLabel;

@end
