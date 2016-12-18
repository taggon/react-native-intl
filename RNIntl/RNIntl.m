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

RCT_EXPORT_METHOD(formatNumber: (double)number
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

    NSNumber *num = [NSNumber numberWithDouble:number];

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
        [formatter setUsesGroupingSeparator: [options objectForKey:@"useGrouping"] ? [options[@"useGrouping"] boolValue] : YES ];

        // minimumIntegerDigits
        [formatter setMinimumIntegerDigits:[options objectForKey:@"mimumIntegerDigits"] ? (int)options[@"minimumIntegerDigits"] : 1];

        // minimumFractionDigits
        if ([options objectForKey:@"minimumFractionDigits"]) {
            [formatter setMinimumFractionDigits: (int)options[@"minimumFractionDigits"]];
        } else if (![style isEqualToString:@"currency"]) {
            [formatter setMinimumFractionDigits:0];
        }

        // maximumFractionDigits
        if ([options objectForKey:@"maximumFractionDigits"]) {
            [formatter setMaximumFractionDigits: (int)options[@"maximumFractionDigits"]];
        }

        // minimumSignificantDigits
        if ([options objectForKey:@"minimumSignificantDigits"]) {
            [formatter setMinimumSignificantDigits: (int)options[@"minimumSignificantDigits"]];
        }

        // maximumSignificantDigits
        if ([options objectForKey:@"maximumSignificantDigits"]) {
            [formatter setMaximumSignificantDigits: (int)options[@"maximumSignificantDigits"]];
        }
    }

    NSString *result = [formatter stringFromNumber:num];
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
        NSString *template = options[@"template"];

        // calendar
        if ([options valueForKey:@"calendar"] != nil) {
            formatter.calendar = options[@"calendar"];
        }

        // timezone
        if ([options valueForKey:@"timeZone"] != nil) {
            [formatter setTimeZone:[[NSTimeZone alloc] initWithName:options[@"timeZone"]]];
        }

        // hour12
        if ([options objectForKey:@"hour12"]) {
            if ((bool)options[@"hour12"]) {
                template = [template stringByReplacingOccurrencesOfString:@"H" withString:@"h"];
            } else {
                template = [template stringByReplacingOccurrencesOfString:@"h" withString:@"H"];
            }
        }

        // template
        [formatter setDateFormat:[NSDateFormatter dateFormatFromTemplate:template options:0 locale:currentLocale]];
    }

    NSString *result = [formatter stringFromDate:date];
    resolve(result);
}

RCT_EXPORT_METHOD(loadCatalog: (nonnull NSString *)localeCode
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)
{
    localeCode = [localeCode stringByReplacingOccurrencesOfString:@"-" withString:@"_"];
    NSLocale *locale = [[NSLocale alloc] initWithLocaleIdentifier:localeCode];
    NSString *code = locale.localeIdentifier;
    NSString *filePath = [[NSBundle mainBundle] pathForResource:code ofType:@"mo" inDirectory:@"i18n"];
    BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:filePath];

    // fallback locale
    if (!fileExists) {
        filePath = [[NSBundle mainBundle] pathForResource:[locale objectForKey:NSLocaleLanguageCode] ofType:@"mo" inDirectory:@"i18n"];
        fileExists = [[NSFileManager defaultManager] fileExistsAtPath:filePath];
    }

    if (!fileExists) {
        NSError *error = [NSError
                          errorWithDomain: @"File not found"
                          code: 404
                          userInfo: @{ @"locale": localeCode }];
        reject(@"no_file", @"File not found", error);
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
