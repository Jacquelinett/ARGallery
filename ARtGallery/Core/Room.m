//
//  Room.m
//  ARtGallery
//
//  Created by Jacqueline on 5/30/18.
//

#import "Room.h"

@implementation Room

- (instancetype)initWithName:(NSString *)roomName {
    self = [super init];
    if (self) {
        self.name = roomName;
        self.objectList = [NSMutableArray new];
        self.objectReferences = [NSMutableDictionary new];
    }
    return self;
}

- (instancetype)initWithDictionary:(NSDictionary *)dictionary {
    self = [super init];
    if (self) {
        self.name = dictionary[@"name"];
        self.objectList = [NSMutableArray new];
        self.objectReferences = [NSMutableDictionary new];
        
        NSDictionary *objectList = dictionary[@"object_list"];
        if (![objectList isEqual:[NSNull null]]) {
            for(id key in objectList) {
                NSDictionary * value = [objectList objectForKey:key];
                
                NSString *anchor = value[@"anchor_identifier"];
                NSString *resource = value[@"resource_identifier"];
                float scaling = [value[@"scaling"] floatValue];
                int type = [value[@"type"] intValue];
                
                id arObj = [[ARObject alloc] initWithID:anchor resource:resource scaling:scaling type:type];
                if (arObj) {
                    [self.objectReferences setValue:[NSNumber numberWithUnsignedInteger:self.objectList.count] forKey:anchor];
                    [self.objectList addObject:arObj];
                }
            }
        }
    }
    return self;
}

@end
