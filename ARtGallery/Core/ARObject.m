//
//  ARObject.m
//  ARtGallery
//
//  Created by Jacqueline on 5/30/18.
//

#import "ARObject.h"

@implementation ARObject

- (instancetype)initWithID:(NSString*)anchor resource:(NSString*)resource scaling:(float)scale type:(ResourceType)type {
    self = [super init];
    if (self) {
        self.anchorID = anchor;
        self.resourceID = resource;
        self.scaling = scale;
        self.type = type;
    }
    return self;
}

@end
