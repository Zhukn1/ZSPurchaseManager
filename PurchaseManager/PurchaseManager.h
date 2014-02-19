//
//  PurschaseManager.h
//
//
//  Created by Stas Zhukovskiy on 18.02.14.
//  Copyright (c) 2014 Stanislav Zhukovskiy. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>

extern NSString * const PurchaseManagerSuccessNotification;
extern NSString * const PurchaseManagerFailedNotification;

@interface PurchaseManager : NSObject <SKProductsRequestDelegate, SKPaymentTransactionObserver>

+ (PurchaseManager *)sharedManager;
- (void)requestProductData;

- (void)loadStore;
- (BOOL)canMakePurchases;
- (void)purchaseFullVersion;
- (void)restorePurchases;
- (BOOL)isFullVersionPurchased;

@end
