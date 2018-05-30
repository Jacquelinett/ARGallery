//
//  Room.m
//  ARtGallery
//
//  Created by Jacqueline on 5/30/18.
//

#import "Room.h"

@implementation Room

- (instancetype) initWithName:(NSString *) roomName {
    self = [super init];
    if (self) {
        _name = roomName;
        _objectList = [NSMutableArray new];
    }
    return self;
}

- (void) addARObject : (ARObject *) object {
    [_objectList addObject:object];
}

- (void) setName : (NSString *) name {
    _name = name;
}

- (NSString *) getName {
    return _name;
}

@end
