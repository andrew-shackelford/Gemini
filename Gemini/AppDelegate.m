//
//  AppDelegate.m
//  Gemini
//
//  Created by Andrew Shackelford on 8/30/17.
//  Copyright © 2017 Golden Dog Productions. All rights reserved.
//

#import "AppDelegate.h"
#import "DetailViewController.h"
#import "CommonCrypto/CommonHMAC.h"

@interface AppDelegate () <UISplitViewControllerDelegate>

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    UISplitViewController *splitViewController = (UISplitViewController *)self.window.rootViewController;
    UINavigationController *navigationController = [splitViewController.viewControllers lastObject];
    navigationController.topViewController.navigationItem.leftBarButtonItem = splitViewController.displayModeButtonItem;
    splitViewController.delegate = self;
    
    // some testing
    
    NSError *err;
    NSString *path = [[NSBundle mainBundle] pathForResource:@"key" ofType:@"json"];
    NSData *keyData = [NSData dataWithContentsOfFile:path];
    NSDictionary *keyDict = [NSJSONSerialization JSONObjectWithData:keyData options:NSJSONReadingMutableContainers error:&err];
    
    NSString *gemini_api_key = keyDict[@"key"];
    NSString *gemini_api_secret = keyDict[@"secret"];
    
    NSMutableDictionary *req = [[NSMutableDictionary alloc] init];
    [req setObject:@"/v1/balances" forKey:@"request"];
    CFAbsoluteTime nonceTime = CFAbsoluteTimeGetCurrent();
    NSString *nonce = [NSString stringWithFormat:@"%f", nonceTime];
    [req setObject:nonce forKey:@"nonce"];
    
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:req options:NSJSONWritingPrettyPrinted error:&error];
    NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    NSString *fixedString = [jsonString stringByReplacingOccurrencesOfString:@"\\/" withString:@"/"];
    NSLog(fixedString);
    NSData *b64 = [fixedString dataUsingEncoding:NSUTF8StringEncoding];
    NSString *b64Str = [b64 base64EncodedStringWithOptions:0];
    
    
    const char *cKey  = [gemini_api_secret cStringUsingEncoding:NSASCIIStringEncoding];
    const char *cData = [b64Str cStringUsingEncoding:NSASCIIStringEncoding];
    
    
    
    unsigned char cHMAC[CC_SHA384_DIGEST_LENGTH];
    CCHmac(kCCHmacAlgSHA384, cKey, strlen(cKey), cData, strlen(cData), cHMAC);
    NSData *HMAC = [[NSData alloc] initWithBytes:cHMAC length:sizeof(cHMAC)];
    
    NSUInteger capacity = HMAC.length * 2;
    NSMutableString *sbuf = [NSMutableString stringWithCapacity:capacity];
    const unsigned char *buf = HMAC.bytes;
    NSInteger i;
    for (i=0; i<HMAC.length; ++i) {
        [sbuf appendFormat:@"%02X", (NSUInteger)buf[i]];
    }
    
    NSString *hash = sbuf;


    NSString *post = b64Str;
    NSData *postData = [post dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
    NSString *postLength = [NSString stringWithFormat:@"%lu", (unsigned long)[postData length]];
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    [request setURL:[NSURL URLWithString:@"https://api.gemini.com/v1/balances"]];
    [request setHTTPMethod:@"POST"];
    [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    [request setHTTPBody:postData];
    
    [request setValue:@"text/plain" forHTTPHeaderField:@"Content-Type"];
    [request setValue:@"0" forHTTPHeaderField:@"Content-Length"];
    [request setValue:gemini_api_key forHTTPHeaderField:@"X-GEMINI-APIKEY"];
    [request setValue:b64Str forHTTPHeaderField:@"X-GEMINI-PAYLOAD"];
    [request setValue:hash forHTTPHeaderField:@"X-GEMINI-SIGNATURE"];
    [request setValue:@"no-cache" forHTTPHeaderField:@"Cache-Control"];
    
    NSData *portfolioData=[NSURLConnection sendSynchronousRequest:request returningResponse:nil error:&err];
    NSString *portfolioStr=[[NSString alloc] initWithData:portfolioData encoding:NSUTF8StringEncoding];
    NSArray *portfolioArr = [NSJSONSerialization JSONObjectWithData:portfolioData options:NSJSONReadingMutableContainers error:&err];
    NSMutableDictionary *portfolioDict = [[NSMutableDictionary alloc] init];
    for (int i = 0; i < [portfolioArr count]; i++) {
        [portfolioDict setObject:portfolioArr[i][@"amount"] forKey:portfolioArr[i][@"currency"]];
    }
    
    NSLog(@"Portfolio String is %@", portfolioStr);
    
    request = [[NSMutableURLRequest alloc] init];
    [request setURL:[NSURL URLWithString:@"https://api.gemini.com/v1/pubticker/ethusd"]];
    [request setHTTPMethod:@"GET"];
    NSData *ethereumData = [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:&err];
    NSString *ethereumStr = [[NSString alloc] initWithData:ethereumData encoding:NSUTF8StringEncoding];
    NSDictionary *ethereumDict = [NSJSONSerialization JSONObjectWithData:ethereumData options:NSJSONReadingMutableContainers error:&err];
    NSLog(@"Ethereum String is %@", ethereumStr);
    
    request = [[NSMutableURLRequest alloc] init];
    [request setURL:[NSURL URLWithString:@"https://api.gemini.com/v1/pubticker/btcusd"]];
    [request setHTTPMethod:@"GET"];
    NSData *bitcoinData = [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:&err];
    NSDictionary *bitcoinDict = [NSJSONSerialization JSONObjectWithData:bitcoinData options:NSJSONReadingMutableContainers error:&err];
    NSString *bitcoinStr = [[NSString alloc] initWithData:bitcoinData encoding:NSUTF8StringEncoding];
    NSLog(@"Bitcoin String is %@", bitcoinStr);
    
    float bitcoinAmount = [portfolioDict[@"BTC"] floatValue] * [bitcoinDict[@"last"] floatValue];
    float ethereumAmount = [portfolioDict[@"ETH"] floatValue] * [ethereumDict[@"last"] floatValue];
    float cashAmount = [portfolioDict[@"USD"] floatValue];
    
    NSLog(@"Bitcoin: %f, Ethereum: %f, Cash: %f", bitcoinAmount, ethereumAmount, cashAmount);
    float totalAmount = bitcoinAmount + ethereumAmount + cashAmount;
    NSLog(@"Total is: %f", totalAmount);

    
    return YES;
}


- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}


- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}


#pragma mark - Split view

- (BOOL)splitViewController:(UISplitViewController *)splitViewController collapseSecondaryViewController:(UIViewController *)secondaryViewController ontoPrimaryViewController:(UIViewController *)primaryViewController {
    if ([secondaryViewController isKindOfClass:[UINavigationController class]] && [[(UINavigationController *)secondaryViewController topViewController] isKindOfClass:[DetailViewController class]] && ([(DetailViewController *)[(UINavigationController *)secondaryViewController topViewController] detailItem] == nil)) {
        // Return YES to indicate that we have handled the collapse by doing nothing; the secondary controller will be discarded.
        return YES;
    } else {
        return NO;
    }
}

@end
