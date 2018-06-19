//
//  ARObject.h
//  ARtGallery
//
//  Created by Jacqueline on 5/30/18.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, AnchorType) {
    AnchorTypeDefault = 0,
    AnchorTypePicture = 1,
    AnchorTypeVideo = 2
};

@interface ARObject : NSObject

@property (strong, nonatomic) NSString *anchorID;
@property (strong, nonatomic) NSString *resourceID;
@property (assign, nonatomic) AnchorType type;

- (instancetype) initWithID: (NSString*) anchor resource:(NSString*) resource type:(AnchorType) type;

- (NSString *) getAnchorID;
- (NSString *) getResourceID;
- (AnchorType) getType;

@end
