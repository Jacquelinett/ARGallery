//
//  Room.h
//  CloudAnchorExample
//
//  Created by Jacqueline on 5/29/18.
//

#import <Foundation/Foundation.h>
#import "ARObject.h"

@interface Room : NSObject

@property (strong, nonatomic) NSString *name;
@property (strong, nonatomic) NSMutableArray *objectList;
@property (strong, nonatomic) NSMutableDictionary *objectReferences;

// Future to do:
// Add lists of currently connected users

- (instancetype)initWithName:(NSString *)roomName;
- (instancetype)initWithDictionary:(NSDictionary *)dictionary;

@end


