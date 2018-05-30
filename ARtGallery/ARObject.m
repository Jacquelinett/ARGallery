//
//  ARObject.m
//  ARtGallery
//
//  Created by Jacqueline on 5/30/18.
//

#import "ARObject.h"

@implementation ARObject

- (instancetype) initWithID: (NSString*) id type:(AnchorType) type{
    self = [super init];
    if (self) {
        _id = id;
        _type = type;
    }
    return self;
}

@end
