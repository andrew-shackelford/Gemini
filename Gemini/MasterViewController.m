//
//  MasterViewController.m
//  Gemini
//
//  Created by Andrew Shackelford on 8/30/17.
//  Copyright © 2017 Golden Dog Productions. All rights reserved.
//

#import "MasterViewController.h"
#import "DetailViewController.h"
#import "PriceFetcher.h"
#import "PriceWriter.h"

@interface MasterViewController ()

@property NSMutableArray *objects;
@end

@implementation MasterViewController

PriceFetcher *fetcher;
PriceWriter *writer;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    fetcher = [[PriceFetcher alloc] init];
    writer = [[PriceWriter alloc] init];

    // create refresh control
    self.refreshControl = [[UIRefreshControl alloc] init];
    self.tableView.refreshControl = self.refreshControl;
    [self.refreshControl addTarget:self action:@selector(refresh:) forControlEvents:UIControlEventValueChanged];
    [self.refreshControl setAttributedTitle:[[NSAttributedString alloc] initWithString:@"Fetching Price Data..." attributes:nil]];
    
    // create refresh button
    UIBarButtonItem *refreshButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(refresh:)];
    self.navigationItem.rightBarButtonItem = refreshButton;
    
    self.detailViewController = (DetailViewController *)[[self.splitViewController.viewControllers lastObject] topViewController];
    [self refresh:self];
}

- (void)updateTableView:(NSDictionary*)priceDict {
    float bitcoinAmount = [[priceDict objectForKey:@"BTC"] floatValue];
    float ethereumAmount = [[priceDict objectForKey:@"ETH"] floatValue];
    float cashAmount = [[priceDict objectForKey:@"USD"] floatValue];
    if (!self.objects) {
        self.objects = [[NSMutableArray alloc] init];
        [self insertPriceObject:bitcoinAmount atIndex:0];
        [self insertPriceObject:ethereumAmount atIndex:1];
        [self insertPriceObject:cashAmount atIndex:2];
    } else {
        [self updatePriceObject:bitcoinAmount atIndex:0];
        [self updatePriceObject:ethereumAmount atIndex:1];
        [self updatePriceObject:cashAmount atIndex:2];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    self.clearsSelectionOnViewWillAppear = self.splitViewController.isCollapsed;
    [super viewWillAppear:animated];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)insertPriceObject:(float)price atIndex:(int)index {
    [self.objects insertObject:[NSString stringWithFormat:@"$%.2f", price] atIndex:index];
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
    [self.tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
}

- (void)updatePriceObject:(float)price atIndex:(int)index {
    [self.objects setObject:[NSString stringWithFormat:@"$%.2f", price] atIndexedSubscript:index];
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
    NSArray *indexPathArray = [NSArray arrayWithObjects:indexPath, nil];
    [self.tableView reloadRowsAtIndexPaths:indexPathArray withRowAnimation:UITableViewRowAnimationMiddle];
}

- (void)setUpdatedTime {
    // get date string
    NSDate *now = [NSDate date];
    NSString *dateStr = [NSDateFormatter localizedStringFromDate:now dateStyle:NSDateFormatterNoStyle timeStyle:NSDateFormatterMediumStyle];
    NSString *updateStr = @"Last updated at ";
    NSString *totalStr = [updateStr stringByAppendingString:dateStr];
    
    // assign to toolbar
    UILabel *toolbarLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    toolbarLabel.text = totalStr;
    [toolbarLabel sizeToFit];
    toolbarLabel.backgroundColor = [UIColor clearColor];
    toolbarLabel.textColor = [UIColor grayColor];
    toolbarLabel.textAlignment = NSTextAlignmentCenter;
    UIBarButtonItem *labelItem = [[UIBarButtonItem alloc] initWithCustomView:toolbarLabel];
    UIBarButtonItem *flexible = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    [self setToolbarItems:@[flexible, labelItem, flexible] animated:false];
}

- (void)updatePlist:(NSDictionary *)priceDict {
    float btcFloat = [[priceDict objectForKey:@"btcPrice"] floatValue];
    float ethFloat = [[priceDict objectForKey:@"ethPrice"] floatValue];
    [writer updateBtcPrice:btcFloat];
    [writer updateEthPrice:ethFloat];
    NSLog([NSString stringWithFormat:@"btc price is: %f", [writer btcPrice]]);
    NSLog([NSString stringWithFormat:@"eth price is: %f", [writer ethPrice]]);
}

- (void)refresh:(id)sender {
    NSDictionary *priceDict = [fetcher getPrices];
    [self updatePlist: priceDict];
    [self updateTableView:priceDict];
    [self setUpdatedTime];
    [self.refreshControl endRefreshing];
}

- (NSString*)getLabelForIndex:(NSInteger)index {
    switch (index) {
        case 0:
            return @"Bitcoin:";
        case 1:
            return @"Ethereum:";
        case 2:
            return @"Cash:";
        default:
            return @"Unknown:";
    }
}

#pragma mark - Segues

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([[segue identifier] isEqualToString:@"showDetail"]) {
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        NSString *object = self.objects[indexPath.row];
        DetailViewController *controller = (DetailViewController *)[[segue destinationViewController] topViewController];
        [controller setDetailItem:object];
        controller.navigationItem.leftBarButtonItem = self.splitViewController.displayModeButtonItem;
        controller.navigationItem.leftItemsSupplementBackButton = YES;
        controller.navigationItem.title = [self getLabelForIndex:indexPath.row];
    }
}


#pragma mark - Table View

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.objects.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
    NSString *object = self.objects[indexPath.row];
    cell.textLabel.text = [self getLabelForIndex:indexPath.row];;
    cell.detailTextLabel.text = [object description];
    return cell;
}


- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return NO;
}


- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        [self.objects removeObjectAtIndex:indexPath.row];
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
    }
}


@end
