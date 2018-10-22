//
//  Storage.m
//  ARtGallery
//
//  Created by Jacqueline Tran on 10/21/18.
//

#import "Storage.h"

@implementation Storage

- (instancetype)initDefault {
    self = [super init];
    if (self) {
        _imageDictionary = [NSMutableDictionary new];
        _soundDictionary = [NSMutableDictionary new];
        _videoDictionary = [NSMutableDictionary new];
    }
    return self;
}

@end
