//
//  PurchaseManager.m
//
//
//  Created by Stas Zhukovskiy on 18.02.14.
//  Copyright (c) 2014 Stanislav Zhukovskiy. All rights reserved.
//

#import "PurchaseManager.h"
#import "SKProduct+ZSAdditions.h"

#define INAPP_PURCHASE_ID @"PLACE IN-APP PURCHASE ID HERE"

NSString * const PurchaseManagerSuccessNotification = @"PurchaseManagerSuccesfullyPurchased";
NSString * const PurchaseManagerFailedNotification = @"PurchaseManagerErrorWhilePurchasing";

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
        
        NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
        [numberFormatter setFormatterBehavior:NSNumberFormatterBehavior10_4];
        [numberFormatter setNumberStyle:NSNumberFormatterCurrencyStyle];
        [numberFormatter setLocale:self.fullVersionProduct.priceLocale];
        NSString *formattedPrice = [numberFormatter stringFromNumber:self.fullVersionProduct.price];
        
        NSLog(@"Product localized price: %@", formattedPrice);
        [[NSUserDefaults standardUserDefaults] setValue:formattedPrice forKey:@"LoalizedPriceForFullVersion"];
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
    if (result)
        return result;
    else
        return NO;
}

- (NSString *)getPriceForFullVersion {
    NSString *result = [[NSUserDefaults standardUserDefaults] stringForKey:@"LoalizedPriceForFullVersion"];
    if (!result)
        result = @"";
    return [NSString stringWithFormat:@"КУПИТЬ ЗА %@", [result uppercaseString]];
}

- (void)recordTransaction:(SKPaymentTransaction *)transaction {
    if ([transaction.payment.productIdentifier isEqualToString:INAPP_PURCHASE_ID])
        [[NSUserDefaults standardUserDefaults] setValue:transaction.transactionReceipt forKey:@"fullVersionTransactionReceipt"];
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
    else
        [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
}

- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions
{
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

@end
