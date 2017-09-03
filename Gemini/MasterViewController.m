//
//  MasterViewController.m
//  Gemini
//
//  Created by Andrew Shackelford on 8/30/17.
//  Copyright © 2017 Golden Dog Productions. All rights reserved.
//

#import "MasterViewController.h"
#import "DetailViewController.h"
#import "CommonCrypto/CommonHMAC.h"

@interface MasterViewController ()

@property NSMutableArray *objects;
@end

@implementation MasterViewController

float cashAmount = 0.;
float bitcoinAmount = 0.;
float ethereumAmount = 0.;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.

    UIBarButtonItem *refreshButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(refresh:)];
    self.navigationItem.rightBarButtonItem = refreshButton;
    self.detailViewController = (DetailViewController *)[[self.splitViewController.viewControllers lastObject] topViewController];
    [self refresh:self];
}

- (void)updateTableView {
    [self insertPriceObject:bitcoinAmount atIndex:0];
    [self insertPriceObject:ethereumAmount atIndex:1];
    [self insertPriceObject:cashAmount atIndex:2];
}

- (NSDictionary*)getPortfolio {
    
    // load api keys
    NSError *err;
    NSString *path = [[NSBundle mainBundle] pathForResource:@"key" ofType:@"json"];
    NSData *keyData = [NSData dataWithContentsOfFile:path];
    NSDictionary *keyDict = [NSJSONSerialization JSONObjectWithData:keyData options:NSJSONReadingMutableContainers error:&err];
    NSString *gemini_api_key = keyDict[@"key"];
    NSString *gemini_api_secret = keyDict[@"secret"];
    
    // create request values
    NSMutableDictionary *req = [[NSMutableDictionary alloc] init];
    [req setObject:@"/v1/balances" forKey:@"request"];
    CFAbsoluteTime nonceTime = CFAbsoluteTimeGetCurrent();
    NSString *nonce = [NSString stringWithFormat:@"%f", nonceTime];
    [req setObject:nonce forKey:@"nonce"];
    
    // create base64 values
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:req options:NSJSONWritingPrettyPrinted error:&err];
    NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    NSString *fixedString = [jsonString stringByReplacingOccurrencesOfString:@"\\/" withString:@"/"];
    NSData *b64 = [fixedString dataUsingEncoding:NSUTF8StringEncoding];
    NSString *b64Str = [b64 base64EncodedStringWithOptions:0];
    
    // create signature
    const char *cKey  = [gemini_api_secret cStringUsingEncoding:NSASCIIStringEncoding];
    const char *cData = [b64Str cStringUsingEncoding:NSASCIIStringEncoding];
    unsigned char cHMAC[CC_SHA384_DIGEST_LENGTH];
    CCHmac(kCCHmacAlgSHA384, cKey, strlen(cKey), cData, strlen(cData), cHMAC);
    NSData *HMAC = [[NSData alloc] initWithBytes:cHMAC length:sizeof(cHMAC)];
    
    // create hex signature
    NSUInteger capacity = HMAC.length * 2;
    NSMutableString *hash = [NSMutableString stringWithCapacity:capacity];
    const unsigned char *buf = HMAC.bytes;
    NSInteger i;
    for (i=0; i<HMAC.length; ++i) {
        [hash appendFormat:@"%02lX", (unsigned long)buf[i]];
    }
    
    // create http post string
    NSData *postData = [b64Str dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
    NSString *postLength = [NSString stringWithFormat:@"%lu", (unsigned long)[postData length]];
    
    // create request
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    [request setURL:[NSURL URLWithString:@"https://api.gemini.com/v1/balances"]];
    [request setHTTPMethod:@"POST"];
    [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    [request setHTTPBody:postData];
    
    // set request headers
    [request setValue:@"text/plain" forHTTPHeaderField:@"Content-Type"];
    [request setValue:@"0" forHTTPHeaderField:@"Content-Length"];
    [request setValue:gemini_api_key forHTTPHeaderField:@"X-GEMINI-APIKEY"];
    [request setValue:b64Str forHTTPHeaderField:@"X-GEMINI-PAYLOAD"];
    [request setValue:hash forHTTPHeaderField:@"X-GEMINI-SIGNATURE"];
    [request setValue:@"no-cache" forHTTPHeaderField:@"Cache-Control"];
    
    // get data
    NSData *portfolioData=[NSURLConnection sendSynchronousRequest:request returningResponse:nil error:&err];
    NSString *portfolioStr=[[NSString alloc] initWithData:portfolioData encoding:NSUTF8StringEncoding];
    NSArray *portfolioArr = [NSJSONSerialization JSONObjectWithData:portfolioData options:NSJSONReadingMutableContainers error:&err];
    NSMutableDictionary *portfolioDict = [[NSMutableDictionary alloc] init];
    for (int i = 0; i < [portfolioArr count]; i++) {
        [portfolioDict setObject:portfolioArr[i][@"amount"] forKey:portfolioArr[i][@"currency"]];
    }
    
    // log and return data
    NSLog(@"Portfolio: %@", portfolioStr);
    return portfolioDict;
}

- (NSDictionary*)getEthereumPrice {
    // create request
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    NSError *err;
    [request setURL:[NSURL URLWithString:@"https://api.gemini.com/v1/pubticker/ethusd"]];
    [request setHTTPMethod:@"GET"];
    
    // get data
    NSData *ethereumData = [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:&err];
    NSString *ethereumStr = [[NSString alloc] initWithData:ethereumData encoding:NSUTF8StringEncoding];
    NSDictionary *ethereumDict = [NSJSONSerialization JSONObjectWithData:ethereumData options:NSJSONReadingMutableContainers error:&err];
    
    // log and return data
    NSLog(@"Ethereum: %@", ethereumStr);
    return ethereumDict;
}

- (NSDictionary*)getBitcoinPrice {
    // create request
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    NSError *err;
    [request setURL:[NSURL URLWithString:@"https://api.gemini.com/v1/pubticker/btcusd"]];
    [request setHTTPMethod:@"GET"];
    
    // get data
    NSData *bitcoinData = [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:&err];
    NSDictionary *bitcoinDict = [NSJSONSerialization JSONObjectWithData:bitcoinData options:NSJSONReadingMutableContainers error:&err];
    NSString *bitcoinStr = [[NSString alloc] initWithData:bitcoinData encoding:NSUTF8StringEncoding];
    
    // log and return data
    NSLog(@"Bitcoin: %@", bitcoinStr);
    return bitcoinDict;
}

- (void)updatePrices {
    NSDictionary *portfolioDict = [self getPortfolio];
    NSDictionary *ethereumDict = [self getEthereumPrice];
    NSDictionary *bitcoinDict = [self getBitcoinPrice];
    
    bitcoinAmount = [portfolioDict[@"BTC"] floatValue] * [bitcoinDict[@"last"] floatValue];
    ethereumAmount = [portfolioDict[@"ETH"] floatValue] * [ethereumDict[@"last"] floatValue];
    cashAmount = [portfolioDict[@"USD"] floatValue];
    
    NSLog(@"Bitcoin: %f, Ethereum: %f, Cash: %f", bitcoinAmount, ethereumAmount, cashAmount);
    float totalAmount = bitcoinAmount + ethereumAmount + cashAmount;
    NSLog(@"Total is: %f", totalAmount);
}

- (void)viewWillAppear:(BOOL)animated {
    self.clearsSelectionOnViewWillAppear = self.splitViewController.isCollapsed;
    [super viewWillAppear:animated];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)insertNewObject:(id)sender {
    if (!self.objects) {
        self.objects = [[NSMutableArray alloc] init];
    }
    [self.objects insertObject:@"hi" atIndex:0];
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
    [self.tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
}

- (void)insertPriceObject:(float)price atIndex:(int)index {
    if (!self.objects) {
        self.objects = [[NSMutableArray alloc] init];
    }
    [self.objects insertObject:[NSString stringWithFormat:@"$%.2f", price] atIndex:index];
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
    [self.tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
}



- (void)refresh:(id)sender {
    [self updatePrices];
    [self updateTableView];
}


#pragma mark - Segues

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([[segue identifier] isEqualToString:@"showDetail"]) {
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        NSDate *object = self.objects[indexPath.row];
        DetailViewController *controller = (DetailViewController *)[[segue destinationViewController] topViewController];
        [controller setDetailItem:object];
        controller.navigationItem.leftBarButtonItem = self.splitViewController.displayModeButtonItem;
        controller.navigationItem.leftItemsSupplementBackButton = YES;
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

    NSDate *object = self.objects[indexPath.row];
    cell.textLabel.text = [object description];
    return cell;
}


- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
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
