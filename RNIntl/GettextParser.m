//
//  GettextParser.m
//  RNIntl
//
//  Created by Taegon Kim on 2015. 12. 12..
//  Copyright © 2015 Taegon Kim. All rights reserved.
//

#import "GettextParser.h"

#define MAGIC_NUMBER 0x950412de

typedef struct {
    uint32_t magic;
    uint32_t revision;
    uint32_t stringCount;
    uint32_t originalStringOffset;
    uint32_t translationStringOffset;
    uint32_t hashTableSize;
    uint32_t hashTableOffset;
} MoHeader;

typedef struct {
    uint32_t length;
    uint32_t offset;
} Position;

@implementation GettextParser

@synthesize lastError;
@synthesize catalog;

- (instancetype)initWithFileAtPath:(nonnull NSString *)filepath {
    if (self = [super init]) {
        [self loadFileAtPath:filepath];
    }
    return self;
}

- (BOOL)loadFileAtPath:(NSString *)filepath {
    MoHeader header = { 0 };
    NSError *err = nil;
    NSData *data = [NSData dataWithContentsOfFile:filepath options:NSDataReadingMappedIfSafe error:&err];

    if (err != nil) {
      lastError = err;
      return NO;
    }

    // get header
    [data getBytes:&header length:sizeof(header)];

    // check magic number
    if (header.magic != MAGIC_NUMBER && header.magic != OSSwapInt32(MAGIC_NUMBER)) {
      return NO;
    }

    NSDictionary *headers = nil;
    NSMutableDictionary *messages = [[NSMutableDictionary alloc] init];
    for (uint i = 0; i < header.stringCount; i++) {
        Position pos = { 0 };
        uint32_t offset = 0;

        // msgid - original string
        offset = header.originalStringOffset + i * sizeof(pos);
        [data getBytes:&pos range:NSMakeRange(offset, sizeof(pos))];
        NSArray *idList = [self getStringsFromData:[data subdataWithRange:NSMakeRange(pos.offset, pos.length)]];

        // msgstr - translation string
        offset = header.translationStringOffset + i * sizeof(pos);
        [data getBytes:&pos range:NSMakeRange(offset, sizeof(pos))];
        NSArray *translationList = [self getStringsFromData:[data subdataWithRange:NSMakeRange(pos.offset, pos.length)]];

        for (uint j = 0; j < idList.count; j++) {
            if ([[idList objectAtIndex:0] isEqualToString:@""]) {
                headers = [self parseHeader:[translationList objectAtIndex:0]];
            } else {
                [messages setValue:translationList forKey:[idList objectAtIndex:j]];
            }
        }
    }

    catalog = @{ @"headers": headers, @"translations": messages };

    return YES;
}

- (NSDictionary *)parseHeader:(nonnull NSString *)headerString {
    NSArray *_headers = [headerString componentsSeparatedByString:@"\n"];
    NSMutableDictionary *headers = [[NSMutableDictionary alloc] init];

    for (int i=0; i < _headers.count; i++) {
        NSRange range = [_headers[i] rangeOfString:@":"];
        if (range.location == NSNotFound) continue;

        NSString *key = [_headers[i] substringToIndex:range.location];
        NSString *value = [_headers[i] substringFromIndex:range.location+range.length];

        key = [key stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        value = [value stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];

        [headers setValue:value forKey:key];
    }

    return headers;
}

- (NSDictionary *)getCatalog {
    return catalog;
}

- (NSArray *)getStringsFromData:(nonnull NSData *) data{
    NSMutableArray *result = [[NSMutableArray alloc] init];
    NSData *pattern = [[NSData alloc] initWithBytes:(unsigned char[]){0x04} length:1];
    NSRange range = [data rangeOfData:pattern options:0 range:NSMakeRange(0, data.length)];
    NSUInteger from = 0;

    // strip context
    if (range.location != NSNotFound) {
        data = [data subdataWithRange:NSMakeRange(0, range.location)];
    }

    // null pattern
    pattern = [[NSData alloc] initWithBytes:(unsigned char[]){0x00} length:1];

    do {
        range = [data rangeOfData:pattern options:0 range:NSMakeRange(from, data.length - from)];
        if (range.location == NSNotFound) break;

        NSString *str = [[NSString alloc] initWithData:[data subdataWithRange:NSMakeRange(from, range.location - from)] encoding:NSUTF8StringEncoding];
        [result addObject:str];

        from = range.location + range.length;
    } while (TRUE);

    if (result.count == 0 && data.length == 0) {
        [result addObject:@""];
    } else {
        if (from > 0) {
            data = [data subdataWithRange:NSMakeRange(from, data.length - from)];
        }
        [result addObject:[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]];
    }

    return result;
}

@end
