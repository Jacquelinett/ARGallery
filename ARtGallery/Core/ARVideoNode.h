//
//  ARVideoNode.h
//  ARtGallery
//
//  Created by Jacqueline Tran on 11/19/18.
//

#import <SceneKit/SceneKit.h>
#import <ARKit/ARKit.h>
#import <SpriteKit/SpriteKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface ARVideoNode : SCNNode

@property (strong, nonatomic) SKVideoNode *video;
@property (strong, nonatomic) NSURL *url;
@property (strong, nonatomic) SKScene *vidScene;

- (instancetype)initWithURL:(NSURL*)url;
- (void) playVideo;

@end

NS_ASSUME_NONNULL_END
