//
//  ARObject.h
//  ARtGallery
//
//  Created by Jacqueline on 5/30/18.
//

#import <Foundation/Foundation.h>
#import "ResourceType.h"

@interface ARObject : NSObject

@property (strong, nonatomic) NSString *anchorID;
@property (strong, nonatomic) NSString *resourceID;
@property (assign, nonatomic) float scaling;
@property (assign, nonatomic) ResourceType type;

- (instancetype)initWithID:(NSString*)anchor resource:(NSString*)resource scaling:(float)scale type:(ResourceType)type;

@end
