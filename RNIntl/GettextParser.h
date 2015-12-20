//
//  GettextParser.h
//  RNIntl
//
//  Created by Taegon Kim on 2015. 12. 12..
//  Copyright © 2015 Taegon Kim. All rights reserved.
//

#ifndef GettextParser_h
#define GettextParser_h

#import <Foundation/Foundation.h>

@interface GettextParser: NSObject

@property (nonatomic, retain, nullable) NSError *lastError;
@property (nonatomic, retain, nullable) NSDictionary *catalog;

- (instancetype)initWithFileAtPath:(nonnull NSString *)filepath;
- (BOOL)loadFileAtPath:(nonnull NSString *)filepath;

@end


#endif /* GettextParser_h */
