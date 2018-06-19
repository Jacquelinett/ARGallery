//
//  ARObject.m
//  ARtGallery
//
//  Created by Jacqueline on 5/30/18.
//

#import "ARObject.h"

@implementation ARObject

- (instancetype) initWithID: (NSString*) anchor resource:(NSString*) resource type:(AnchorType) type {
    self = [super init];
    if (self) {
        _anchorID = anchor;
        _resourceID = resource;
        _type = type;
    }
    return self;
}

- (NSString *) getAnchorID {
    return _anchorID;
}

- (NSString *) getResourceID {
    return _resourceID;
}

- (AnchorType) getType {
    return _type;
}

@end
