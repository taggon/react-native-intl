//
//  RNIntl.m
//  RNIntl
//
//  Created by Taegon Kim on 2015. 12. 10..
//  Copyright © 2015 Taegon Kim. All rights reserved.
//

#import "RNIntl.h"
#import "GettextParser.h"

@implementation RNIntl

RCT_EXPORT_MODULE()

RCT_EXPORT_METHOD(formatNumber: (nonnull NSNumber *)number
                  localeCode: (NSString *)locale
                  options: (NSDictionary *)options
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)
{
    // use system locale by default
    NSString *localeIndentifier = locale;
    if ([localeIndentifier isEqualToString:@""]) {
        localeIndentifier = [self getSystemLocale];
    }
    localeIndentifier = [localeIndentifier stringByReplacingOccurrencesOfString:@"-" withString:@"_"];

    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    [formatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:localeIndentifier]];

    if (options) {
        // style
        NSString *style = [options valueForKey:@"style"] ? options[@"style"] : @"decimal";
        if ([style isEqualToString:@"currency"]) {
            [formatter setNumberStyle: NSNumberFormatterCurrencyStyle];
        } else if ([style isEqualToString:@"percent"]) {
            [formatter setNumberStyle: NSNumberFormatterPercentStyle];
        } else {
            [formatter setNumberStyle: NSNumberFormatterDecimalStyle];
        }

        // currency
        if ([options objectForKey:@"currency"]) {
            [formatter setCurrencyCode:options[@"currency"]];
        }

        // TODO: currencyDisplay

        // useGrouping
        [formatter setUsesGroupingSeparator:[options objectForKey:@"useGrouping"] ? options[@"useGrouping"] : @YES];
        
        // minimumIntegerDigits
        formatter.mimumIntegerDigits = ([options objectForKey:@"mimumIntegerDigits"] != nil) ? options[@"minimumIntegerDigits"] : 1;
        
        // minimumFractionDigits
        if ([options objectForKey:@"minimumFractionDigits"]) {
            formatter.minimumFractionDigits = options[@"minimumFractionDigits"];
        } else if (![style isEqualToString:@"currency"]) {
            formatter.minimumFractionDigits = 0;
        }
        
        // maximumFractionDigits
        if ([options objectForKey:@"maximumFractionDigits"]) {
            formatter.maximumFractionDigits = options[@"maximumFractionDigits"];
        }
        
        // minimumSignificantDigits
        formatter.minimumSignificantDigits = [options objectForKey:@"minimumSignificantDigits"] ? options[@"minimumSignificantDigits"] : 1;
  
        // maximumSignificantDigits
        if ([options objectForKey:@"maximumSignificantDigits"]) {
            formatter.maximumSignificantDigits = options[@"maximumSignificantDigits"];
        }
    }

    NSString *result = [formatter stringFromNumber:number];
    resolve(result);
}

RCT_EXPORT_METHOD(formatDate: (NSDate *) date
                  localeCode: (NSString *)locale
                  options: (NSDictionary *)options
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)
{
    // use system locale by default
    NSString *localeIndentifier = locale;
    if ([localeIndentifier isEqualToString:@""]) {
        localeIndentifier = [self getSystemLocale];
    }
    localeIndentifier = [localeIndentifier stringByReplacingOccurrencesOfString:@"-" withString:@"_"];

    NSLocale *currentLocale = [[NSLocale alloc] initWithLocaleIdentifier:localeIndentifier];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setLocale:currentLocale];
    [formatter setDateStyle:NSDateFormatterShortStyle];

    [formatter setDateFormat:[formatter.dateFormat stringByReplacingOccurrencesOfString:@"yy" withString:@"yyyy"]];

    if (options) {
        // calendar
        if ([options valueForKey:@"calendar"] != nil) {
            formatter.calendar = options[@"calendar"];
        }

        // timezone
        if ([options valueForKey:@"timeZone"] != nil) {
            [formatter setTimeZone:[[NSTimeZone alloc] initWithName:options[@"timeZone"]]];
        }

        // template
        if ([options valueForKey:@"template"] != nil) {
            [formatter setDateFormat:[NSDateFormatter dateFormatFromTemplate:options[@"template"] options:0 locale:currentLocale]];
        }

        // TODO: hour12
        if ([options valueForKey:@"hour12"] != nil) {
        }
    }

    NSString *result = [formatter stringFromDate:date];
    resolve(result);
}

RCT_EXPORT_METHOD(loadCatalog: (nonnull NSString *)localeCode
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)
{
    NSLocale *locale = [[NSLocale alloc] initWithLocaleIdentifier:localeCode];
    NSString *code = [locale localeIdentifier];
    NSString *filePath = [[NSBundle mainBundle] pathForResource:[locale localeIdentifier] ofType:@"mo" inDirectory:@"i18n"];
    BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:filePath];

    // fallback locale
    if (!fileExists) {
        code = [locale objectForKey:NSLocaleLanguageCode];
        filePath = [[NSBundle mainBundle] pathForResource:[locale objectForKey:NSLocaleLanguageCode] ofType:@"mo" inDirectory:@"i18n"];
        fileExists = [[NSFileManager defaultManager] fileExistsAtPath:filePath];
    }

    if (!fileExists) {
        NSError *error = [NSError
                          errorWithDomain: @"File not found"
                          code: 200
                          userInfo: @{}];
        reject( error );
        return;
    }

    GettextParser *parser = [[GettextParser alloc] initWithFileAtPath:filePath];

    if (parser.catalog != nil) {
        NSMutableDictionary *result = [[NSMutableDictionary alloc] initWithDictionary:parser.catalog];
        [result setValue:code forKey:@"locale"];

        resolve(result);
    } else {
        // TODO reject with error message
    }
}

- (NSString *) getSystemLocale {
    NSString *localeString = [[NSLocale preferredLanguages] firstObject];
    return [localeString stringByReplacingOccurrencesOfString:@"_" withString:@"-"];
}

- (NSArray *) getAvailableLocales {
    NSArray *allLocales = [NSLocale availableLocaleIdentifiers];
    NSMutableArray *result = [[NSMutableArray alloc] initWithCapacity:allLocales.count];

    for (int i = 0; i < allLocales.count; i++) {
        [result addObject:[[allLocales objectAtIndex:i] stringByReplacingOccurrencesOfString:@"_" withString:@"-"]];
    }

    return result;
}

- (NSDictionary *)constantsToExport {
    return @{
        @"systemLocale": [self getSystemLocale],
        @"languages": [NSLocale preferredLanguages],
        @"availableLocales": [self getAvailableLocales],
        @"availableCalendars": @{
                @"buddhist": NSCalendarIdentifierBuddhist,
                @"chinese": NSCalendarIdentifierChinese,
                @"coptic": NSCalendarIdentifierCoptic,
                @"ethioaa": NSCalendarIdentifierEthiopicAmeteAlem,
                @"ethiopic": NSCalendarIdentifierEthiopicAmeteMihret,
                @"gregory": NSCalendarIdentifierGregorian,
                @"hebrew": NSCalendarIdentifierHebrew,
                @"indian": NSCalendarIdentifierIndian,
                @"islamic": NSCalendarIdentifierIslamic,
                @"islamicc": NSCalendarIdentifierIslamicCivil,
                @"iso8601": NSCalendarIdentifierISO8601,
                @"japanese": NSCalendarIdentifierJapanese,
                @"persian": NSCalendarIdentifierPersian,
                @"roc": NSCalendarIdentifierRepublicOfChina }
    };
}

@end
