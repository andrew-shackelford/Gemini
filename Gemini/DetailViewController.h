//
//  DetailViewController.h
//  Gemini
//
//  Created by Andrew Shackelford on 8/30/17.
//  Copyright © 2017 Golden Dog Productions. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DetailViewController : UIViewController

@property (strong, nonatomic) NSDate *detailItem;
@property (weak, nonatomic) IBOutlet UILabel *detailDescriptionLabel;

@end

