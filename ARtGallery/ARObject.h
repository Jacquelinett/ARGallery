//
//  ARObject.h
//  ARtGallery
//
//  Created by Jacqueline on 5/30/18.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, AnchorType) {
    AnchorTypeDefault,
    AnchorTypePicture,
    AnchorTypeVideo
};

@interface ARObject : NSObject

@property (strong, nonatomic) NSString *id;
@property (assign, nonatomic) AnchorType type;

- (instancetype) initWithID: (NSString*) id type:(AnchorType) type;

@end
