//
//  SKProduct+ZSAdditions.h
//  Yoga
//
//  Created by Stas Zhukovskiy on 16.02.14.
//  Copyright (c) 2014 Stas Zhukovskiy. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>

@interface SKProduct (ZSAdditions)

@property (nonatomic, readonly) NSString *localizedPrice;

@end
