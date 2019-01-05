//
//  ARVideoNode.m
//  ARtGallery
//
//  Created by Jacqueline Tran on 11/19/18.
//

#import "ARVideoNode.h"

@implementation ARVideoNode

- (instancetype)initWithURL:(NSURL*)url {
    self = [super init];
    if (self) {
        _video = [SKVideoNode videoNodeWithURL:url];
        _url = url;
        _vidScene = [SKScene sceneWithSize:CGSizeMake(640, 480)];
        [_vidScene addChild:_video];
        
        _video.position = CGPointMake(_vidScene.size.width / 2, _vidScene.size.height / 2);
        _video.size = _vidScene.size;
        
        [_video play];
        
        SCNPlane * plane = [SCNPlane planeWithWidth: 0.128 height: 0.096];
        plane.firstMaterial.diffuse.contents = _vidScene;
        
        self.geometry = plane;
    }
    return self;
}

- (void)playVideo {
    [_vidScene removeAllChildren];
    _video = [SKVideoNode videoNodeWithURL:_url];
    [_vidScene addChild:_video];
    _video.position = CGPointMake(_vidScene.size.width / 2, _vidScene.size.height / 2);
    _video.size = _vidScene.size;
    [_video play];
}

@end
