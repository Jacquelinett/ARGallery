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

// Future to do:
// Add lists of currently connected users

- (instancetype) initWithName:(NSString *) roomName;

- (void) addARObject : (ARObject *) object;

- (void) setName : (NSString *) name;
- (NSString *) getName;

@end


