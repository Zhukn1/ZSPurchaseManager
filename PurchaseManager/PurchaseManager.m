//
//  PurchaseManager.m
//
//
//  Created by Stas Zhukovskiy on 18.02.14.
//  Copyright (c) 2014 Stanislav Zhukovskiy. All rights reserved.
//

#import "PurchaseManager.h"

#define INAPP_PURCHASE_ID @"fullVersion"

NSString * const PurchaseManagerSuccessNotification = @"PurchaseManagerSuccesfullyPurchased";
NSString * const PurchaseManagerFailedNotification = @"PurchaseManagerErrorWhilePurchasing";
NSString * const PurchaseManagerCanceledNotification = @"PurchaseManagerCanceledNotification";

@interface PurchaseManager ()

@property (strong, nonatomic) SKProduct *fullVersionProduct;
@property (strong, nonatomic) SKProductsRequest *productsRequest;

@end

@implementation PurchaseManager

+ (PurchaseManager *)sharedManager {
	static PurchaseManager *sharedManager;
	if (sharedManager == nil)
		sharedManager = [PurchaseManager new];
	return sharedManager;
}

- (void)requestProductData {
    NSSet *productIdentifiers = [NSSet setWithObject:INAPP_PURCHASE_ID];
    self.productsRequest = [[SKProductsRequest alloc] initWithProductIdentifiers:productIdentifiers];
    self.productsRequest.delegate = self;
    [self.productsRequest start];
}

- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response {
    NSArray *products = response.products;
    self.fullVersionProduct = (products.count == 1) ? [products firstObject] : nil;
    if (self.fullVersionProduct) {
        NSLog(@"Product title: %@" , self.fullVersionProduct.localizedTitle);
        NSLog(@"Product description: %@" , self.fullVersionProduct.localizedDescription);
        NSLog(@"Product price: %@" , self.fullVersionProduct.price);
        NSLog(@"Product id: %@" , self.fullVersionProduct.productIdentifier);
        
        NSLog(@"Product localized price: %@", self.fullVersionProduct.localizedPrice);
        [[NSUserDefaults standardUserDefaults] setValue:[self.fullVersionProduct.localizedPrice stringByReplacingOccurrencesOfString:@",00" withString:@""] forKey:@"LoalizedPriceForFullVersion"];
    }
    
    for (NSString *invalidProductId in response.invalidProductIdentifiers) {
        NSLog(@"Invalid product id: %@" , invalidProductId);
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"FetchedProductData" object:self userInfo:nil];
}

- (void)loadStore {
    [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
    [self requestProductData];
}

- (BOOL)canMakePurchases {
    return [SKPaymentQueue canMakePayments];
}

- (void)purchaseFullVersion {
    SKPayment *payment = [SKPayment paymentWithProduct:self.fullVersionProduct];
    [[SKPaymentQueue defaultQueue] addPayment:payment];
}

- (void)restorePurchases {
    [[SKPaymentQueue defaultQueue] restoreCompletedTransactions];
}

- (BOOL)isFullVersionPurchased {
    BOOL result = [[NSUserDefaults standardUserDefaults] boolForKey:@"isFullVersionPurchased"];
    if (!result)
        result = NO;
    return result;
}

- (NSString *)getPriceForFullVersion {
    NSString *price = [[NSUserDefaults standardUserDefaults] stringForKey:@"LoalizedPriceForFullVersion"];
    NSString *result = @"КУПИТЬ";
    if (price)
        result = [result stringByAppendingString:[NSString stringWithFormat:@" ЗА %@", [price uppercaseString]]];
    return result;
}

- (void)recordTransaction:(SKPaymentTransaction *)transaction {
    if ([transaction.payment.productIdentifier isEqualToString:INAPP_PURCHASE_ID])
        [[NSUserDefaults standardUserDefaults] setValue:[NSData dataWithContentsOfURL:[[NSBundle mainBundle] appStoreReceiptURL]] forKey:@"fullVersionTransactionReceipt"];
}

- (void)provideContent:(NSString *)productId {
    if ([productId isEqualToString:INAPP_PURCHASE_ID])
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"isFullVersionPurchased"];
}

- (void)finishTransaction:(SKPaymentTransaction *)transaction wasSuccessful:(BOOL)wasSuccessful {
    [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
    NSDictionary *userInfo = @{@"transaction": transaction};
    if (wasSuccessful)
        [[NSNotificationCenter defaultCenter] postNotificationName:PurchaseManagerSuccessNotification object:self userInfo:userInfo];
    else
        [[NSNotificationCenter defaultCenter] postNotificationName:PurchaseManagerFailedNotification object:self userInfo:userInfo];
}

- (void)completeTransaction:(SKPaymentTransaction *)transaction {
    [self provideContent:transaction.payment.productIdentifier];
    [self recordTransaction:transaction];
    [self finishTransaction:transaction wasSuccessful:YES];
}

- (void)restoreTransaction:(SKPaymentTransaction *)transaction {
    [self provideContent:transaction.originalTransaction.payment.productIdentifier];
    [self recordTransaction:transaction.originalTransaction];
    [self finishTransaction:transaction wasSuccessful:YES];
}

- (void)failedTransaction:(SKPaymentTransaction *)transaction {
    if (transaction.error.code != SKErrorPaymentCancelled)
        [self finishTransaction:transaction wasSuccessful:NO];
    else {
        [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
        [[NSNotificationCenter defaultCenter] postNotificationName:PurchaseManagerCanceledNotification object:self];
    }
    
}

- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions {
    for (SKPaymentTransaction *transaction in transactions)
    {
        switch (transaction.transactionState)
        {
            case SKPaymentTransactionStatePurchased: [self completeTransaction:transaction]; break;
            case SKPaymentTransactionStateFailed: [self failedTransaction:transaction]; break;
            case SKPaymentTransactionStateRestored: [self restoreTransaction:transaction]; break;
            default: break;
        }
    }
}

- (void)paymentQueue:(SKPaymentQueue *)queue restoreCompletedTransactionsFailedWithError:(NSError *)error {
    [[NSNotificationCenter defaultCenter] postNotificationName:PurchaseManagerCanceledNotification object:self];
}

@end
