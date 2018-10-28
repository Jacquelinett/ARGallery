//
//  Storage.h
//  ARtGallery
//
//  Created by Jacqueline Tran on 10/21/18.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface Storage : NSObject

@property (strong, nonatomic) NSMutableDictionary *imageDictionary;
@property (strong, nonatomic) NSMutableDictionary *soundDictionary;
@property (strong, nonatomic) NSMutableDictionary *videoDictionary;

- (instancetype)initDefault;

@end

NS_ASSUME_NONNULL_END
