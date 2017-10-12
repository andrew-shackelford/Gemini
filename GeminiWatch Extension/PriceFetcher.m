//
//  PriceFetcher.m
//  Gemini
//
//  Created by Andrew Shackelford on 9/4/17.
//  Copyright © 2017 Golden Dog Productions. All rights reserved.
//

#import "PriceFetcher.h"
#import "CommonCrypto/CommonHMAC.h"

@implementation PriceFetcher

NSMutableDictionary *portfolioDict;
NSDictionary *bitcoinDict;
NSDictionary *ethereumDict;

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
    //NSMutableDictionary *portfolioDict = [[NSMutableDictionary alloc] init];
    NSURLSession *session = [NSURLSession sharedSession];
    
    [[session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable portfolioData,
                                                              NSURLResponse * _Nullable response,
                                                              NSError * _Nullable error) {
        
        NSString *portfolioStr=[[NSString alloc] initWithData:portfolioData encoding:NSUTF8StringEncoding];
        NSArray *portfolioArr = [NSJSONSerialization JSONObjectWithData:portfolioData options:NSJSONReadingMutableContainers error:nil];
        for (int i = 0; i < [portfolioArr count]; i++) {
            [portfolioDict setObject:portfolioArr[i][@"amount"] forKey:portfolioArr[i][@"currency"]];
        }
        // log data
        NSLog(@"Portfolio: %@", portfolioStr);
        
    }] resume];
    
    sleep(10);
    
    // return data
    return portfolioDict;
}

- (NSDictionary*)getEthereumPrice {
    // create request
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    [request setURL:[NSURL URLWithString:@"https://api.gemini.com/v1/pubticker/ethusd"]];
    [request setHTTPMethod:@"GET"];
    
    // get data
    //__block NSDictionary *ethereumDict = [[NSDictionary alloc] init];
    NSURLSession *session = [NSURLSession sharedSession];
    
    [[session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable ethereumData,
                                                              NSURLResponse * _Nullable response,
                                                              NSError * _Nullable error) {
        NSError *err;
        NSString *ethereumStr = [[NSString alloc] initWithData:ethereumData encoding:NSUTF8StringEncoding];
        ethereumDict = [NSJSONSerialization JSONObjectWithData:ethereumData options:NSJSONReadingMutableContainers error:&err];
        // log data
        NSLog(@"Ethereum: %@", ethereumStr);
        
    }] resume];
    
    sleep(10);

    // return data
    return ethereumDict;
}

- (NSDictionary*)getBitcoinPrice {
    // create request
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    [request setURL:[NSURL URLWithString:@"https://api.gemini.com/v1/pubticker/btcusd"]];
    [request setHTTPMethod:@"GET"];
    
    // get data
    //__block NSDictionary *bitcoinDict = [[NSDictionary alloc] init];
    NSURLSession *session = [NSURLSession sharedSession];
    
    [[session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable bitcoinData,
                                                              NSURLResponse * _Nullable response,
                                                              NSError * _Nullable error) {
        NSError *err;
        NSString *bitcoinStr = [[NSString alloc] initWithData:bitcoinData encoding:NSUTF8StringEncoding];
        bitcoinDict = [NSJSONSerialization JSONObjectWithData:bitcoinData options:NSJSONReadingMutableContainers error:&err];
        // log data
        NSLog(@"Bitcoin: %@", bitcoinStr);
        
    }] resume];
    
    sleep(10);
    
    // return data
    return bitcoinDict;
}

- (NSDictionary*)getPrices {
    
    NSDictionary *portfolioDict = [self getPortfolio];
    NSDictionary *ethereumDict = [self getEthereumPrice];
    NSDictionary *bitcoinDict = [self getBitcoinPrice];
    
    float bitcoinAmount = [portfolioDict[@"BTC"] floatValue] * [bitcoinDict[@"last"] floatValue];
    float ethereumAmount = [portfolioDict[@"ETH"] floatValue] * [ethereumDict[@"last"] floatValue];
    float cashAmount = [portfolioDict[@"USD"] floatValue];
    
    NSLog(@"Bitcoin: %f, Ethereum: %f, Cash: %f", bitcoinAmount, ethereumAmount, cashAmount);
    float totalAmount = bitcoinAmount + ethereumAmount + cashAmount;
    NSLog(@"Total is: %f", totalAmount);
    
    NSMutableDictionary *returnDict = [[NSMutableDictionary alloc] init];
    [returnDict setObject:[NSNumber numberWithFloat:bitcoinAmount] forKey:@"BTC"];
    [returnDict setObject:[NSNumber numberWithFloat:ethereumAmount] forKey:@"ETH"];
    [returnDict setObject:[NSNumber numberWithFloat:cashAmount] forKey:@"USD"];
    [returnDict setObject:[NSNumber numberWithFloat:totalAmount] forKey:@"Total"];
    
    return returnDict;
}

@end
