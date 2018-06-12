//
//  ARObject.m
//  ARtGallery
//
//  Created by Jacqueline on 5/30/18.
//

#import "ARObject.h"

@implementation ARObject

- (instancetype) initWithID: (NSString*) id type:(AnchorType) type resName:(NSString*) resName {
    self = [super init];
    if (self) {
        _id = id;
        _type = type;
        _resourceName = resName;
    }
    return self;
}

- (NSString *) getID {
    return _id;
}

- (NSString *) getResourceName {
    return _resourceName;
}

- (AnchorType) getType {
    return _type;
}

@end
