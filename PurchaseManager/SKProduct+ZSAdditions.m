//
//  SKProduct+ZSAdditions.m
//  Yoga
//
//  Created by Stas Zhukovskiy on 16.02.14.
//  Copyright (c) 2014 Stas Zhukovskiy. All rights reserved.
//

#import "SKProduct+ZSAdditions.h"

@implementation SKProduct (ZSAdditions)

- (NSString *)localizedPrice {
    NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
    [numberFormatter setFormatterBehavior:NSNumberFormatterBehavior10_4];
    [numberFormatter setNumberStyle:NSNumberFormatterCurrencyStyle];
    [numberFormatter setLocale:self.priceLocale];
    return [numberFormatter stringFromNumber:self.price];
}

@end
