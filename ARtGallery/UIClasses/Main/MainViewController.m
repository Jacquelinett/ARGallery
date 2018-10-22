/*
 * Copyright 2018 Google Inc. All Rights Reserved.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#import "MainViewController.h"

typedef NS_ENUM(NSInteger, DialogType) {
    DialogTypeRename
};

@implementation MainViewController

#pragma mark - Overriding UIViewController

- (BOOL)prefersStatusBarHidden {
    return NO;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.parent = (NavigationViewController *)self.tabBarController;
    
    // These just initialize scene/storyboard stuff + firebase and google stuff
    self.sceneView.delegate = self;
    self.sceneView.session.delegate = self;
    self.gSession = [GARSession sessionWithAPIKey:@"X"
                                 bundleIdentifier:@"X"
                                            error:nil];
    
    self.gSession.delegate = self;
    self.gSession.delegateQueue = dispatch_get_main_queue();
    
    self.configuration = [ARWorldTrackingConfiguration new];
    [self.configuration setWorldAlignment:ARWorldAlignmentGravity];
    [self.configuration setPlaneDetection:ARPlaneDetectionHorizontal];
    
    self.drawAnchors = [NSMutableArray new];
    self.drawnAnchors = [NSMutableDictionary new];
    self.cloudAnchors = [NSMutableArray new];
    self.loadList = [NSMutableDictionary new];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self.sceneView.session runWithConfiguration:self.configuration];
    
}

- (void)viewDidAppear:(BOOL)animated {
    
}

- (void)session:(ARSession *)session cameraDidChangeTrackingState:(ARCamera *)camera {
    if (camera.trackingState == ARTrackingStateNormal) {
        [self.loadList removeAllObjects];
        [NSTimer scheduledTimerWithTimeInterval:1
                                         target:self
                                       selector:@selector(loadRemainingAnchors)
                                       userInfo:nil
                                        repeats:NO];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.sceneView.session pause];
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    if (touches.count >= 1 && self.state == ProgramStateAddingToRoom) {
        UITouch *touch = [[touches allObjects] firstObject];
        CGPoint touchLocation = [touch locationInView:self.sceneView];
        
        NSArray *hitTestResults =
        [self.sceneView hitTest:touchLocation
                          types:ARHitTestResultTypeExistingPlane |
         ARHitTestResultTypeExistingPlaneUsingExtent |
         ARHitTestResultTypeEstimatedHorizontalPlane];
        
        if (hitTestResults.count > 0) {
            ARHitTestResult *result = [hitTestResults firstObject];
            [self addTemporaryAnchor:result.worldTransform];
        }
    }
}

# pragma mark - Actions

#pragma mark room actions

- (ViewType)getViewType {
    return self.viewType;
}

- (IBAction)btnCancelAdd_pressed:(id)sender {
    [self.sceneView.session removeAnchor:self.arAnchor];
    [self.drawAnchors removeObject:self.arAnchor];
    
    [self enterState:ProgramStateEdittingRoom];
}

- (IBAction)btnConfirmAdd_pressed:(id)sender {
    if (self.state == ProgramStateAddConfirm) {
        [self confirmAnchor];
    }
}

- (void)addTemporaryAnchor:(matrix_float4x4)transform {
    self.arAnchor = [[ARAnchor alloc] initWithTransform:transform];
    [self.sceneView.session addAnchor:self.arAnchor];
    [self.drawAnchors addObject:self.arAnchor];
    
    [self enterState:ProgramStateAddConfirm];
}

- (IBAction)sldSize_valueChanged:(id)sender {
    //[_imgAddView setFrame: self.imgFrame];
    self.scalingFactor = self.sldSize.value / 100;
    //_imgToAdd.size = CGRectMake(0, 0, _imageWidth * _scalingFactor, _imageHeight * _scalingFactor);

    self.currentNode.scale = SCNVector3Make(self.scalingFactor, self.scalingFactor, self.scalingFactor);
}

- (void)initialize {
    self.room = self.parent.room;
    self.viewType = self.parent.viewType;
    
    if (!self.socket) {
        self.socket = self.parent.socket;
        
        [self.socket on:@"ARObjectCreatedSuccessful" callback:^(NSArray* data, SocketAckEmitter* ack) {
            self.message = @"Object successfully saved to the server";
            
            self.storage.imageDictionary[[data objectAtIndex:0]] = self.imgToAdd;
            
            ARObject * newObject = [[ARObject alloc] initWithID:self.garAnchor.cloudIdentifier resource:[data objectAtIndex:0] scaling:self.scalingFactor type:ResourceTypeImage];
            
            [self.room.objectList addObject:newObject];
            [self.room.objectReferences setValue:[NSNumber numberWithUnsignedInteger:self.room.objectList.count] forKey:self.garAnchor.cloudIdentifier];
            
            [self enterState:ProgramStateEdittingRoom];
        }];
        
        [self.socket on:@"ARObjectRemovedSuccessful" callback:^(NSArray* data, SocketAckEmitter* ack) {

        }];
    }
    
    if (!self.storage) {
        self.storage = self.parent.storage;
    }
    
    [self loadRoom];
}

- (void) initializeAddMode:(UIImage *)toAdd{
    //self.imgAddView.image = toAdd;
    self.imgToAdd = toAdd;
    self.scalingFactor = 1;
    self.sldSize.value = 100;
    //[_imgAddView setFrame: self.imgFrame];
    
    [self enterState:ProgramStateAddingToRoom];
}

- (void)loadRoom{
    [self clearScreen];
    
    switch (self.viewType) {
        case ViewTypeEdit:
            [self enterState:ProgramStateEdittingRoom];
            break;
        case ViewTypeJoin:
            [self enterState:ProgramStateViewingRoom];
    }
    
    [self queueAllAnchors];
}

- (void)queueAllAnchors {
    // A little bit hacky
    for (ARObject * arObj in self.room.objectList) {
        self.loadList[arObj.anchorID] = arObj.anchorID;
    }
}

- (void)loadRemainingAnchors {
    for(id key in self.loadList) {
        [self resolveAnchorWithIdentifier:self.loadList[key]];
        [self.loadList removeObjectForKey:key];
    }
}

- (void)removeARObject : (NSString*) identifier{
    [self.sceneView.session removeAnchor:self.drawnAnchors[identifier]];
    [self.drawAnchors removeObject:self.drawnAnchors[identifier]];
}


- (void)resolveAnchorWithIdentifier:(NSString *)identifier {
    if (identifier) {
        NSLog(@"Attempted to load");
        GARAnchor * anchor = [self.gSession resolveCloudAnchorWithIdentifier:identifier error:nil];
        if (anchor)
            [self.loadList setValue:identifier forKey:[anchor.identifier UUIDString]];
    }
}

- (void)confirmAnchor {
    [self enterState:ProgramStateSaving];
    //[self enterState:ProgramStateEdittingRoom];
    
    // To share an anchor, we call host anchor here on the ARCore session.
    // session:disHostAnchor: session:didFailToHostAnchor: will get called appropriately.
    self.garAnchor = [self.gSession hostCloudAnchor:self.arAnchor error:nil];
}

#pragma mark - GARSessionDelegate

- (void)session:(GARSession *)session didHostAnchor:(GARAnchor *)anchor {
    
    // This function run the anchor is soccessfully hosted
    if (self.state != ProgramStateSaving || ![anchor isEqual:self.garAnchor]) {
        return;
    }
    
    self.garAnchor = anchor;
    
    [self.cloudAnchors addObject:anchor];
    
    self.drawnAnchors[anchor.cloudIdentifier] = self.arAnchor;
    
    NSData *imageData = UIImagePNGRepresentation(self.imgToAdd);
    NSString * base64String = [imageData base64EncodedStringWithOptions:0];
    
    [self.socket emit: @"addARObject" with: @[anchor.cloudIdentifier, base64String, @(self.scalingFactor), @0]];
}

- (void)session:(GARSession *)session didFailToHostAnchor:(GARAnchor *)anchor {
    // Run when anchor can't be hosted
    if (self.state != ProgramStateSaving || ![anchor isEqual:self.garAnchor]) {
        return;
    }
    
    // Sample code just consider it to be a fail experiment, don't do anything and just change the state
    self.garAnchor = anchor;
    [self.sceneView.session removeAnchor:self.arAnchor];
    [self.drawAnchors removeObject:self.arAnchor];
    [self enterState:ProgramStateEdittingRoom];
}

- (void)session:(GARSession *)session didResolveAnchor:(GARAnchor *)anchor {
    NSLog(@"Succeeded");
    self.garAnchor = anchor;
    [self.cloudAnchors addObject: anchor];
    [self.loadList removeObjectForKey:[anchor.identifier UUIDString]];
    
    ARObject *r = [self.room.objectList objectAtIndex:[[self.room.objectReferences objectForKey:anchor.cloudIdentifier] integerValue]];
    
    self.scalingFactor = r.scaling;
    
    // We check if the resource exist already (by checking the cache
    self.imgToAdd = [self.storage.imageDictionary objectForKey:r.resourceID];
    self.arAnchor = [[ARAnchor alloc] initWithTransform:anchor.transform];
    
    [self.sceneView.session addAnchor:self.arAnchor];
    [self.drawAnchors addObject:self.arAnchor];
    
    self.drawnAnchors[anchor.cloudIdentifier] = self.arAnchor;
}

- (void)session:(GARSession *)session didFailToResolveAnchor:(GARAnchor *)anchor {
    NSLog(@"Failed");
    [self resolveAnchorWithIdentifier: self.loadList[[anchor.identifier UUIDString]]];
}


#pragma mark - ARSessionDelegate

- (void)session:(ARSession *)session didUpdateFrame:(ARFrame *)frame {
    // Not exactly sure what this does yet
    
    // Forward ARKit's update to ARCore session
    [self.gSession update:frame error:nil];
}


# pragma mark - Helper Methods
// These belows are pretty self-explanatory

- (void)updateMessageLabel {
    [self.messageLabel setText:self.message];
    self.lblRoomName.text = [NSString stringWithFormat:@"Room: %@", self.room.name];
}

- (void)toggleButton:(UIButton *)button enabled:(BOOL)enabled title:(NSString *)title {
    button.enabled = enabled;
    [button setTitle:title forState:UIControlStateNormal];
}

- (NSString *)cloudStateString:(GARCloudAnchorState)cloudState {
    switch (cloudState) {
        case GARCloudAnchorStateNone:
            return @"None";
        case GARCloudAnchorStateSuccess:
            return @"Success";
        case GARCloudAnchorStateErrorInternal:
            return @"ErrorInternal";
        case GARCloudAnchorStateTaskInProgress:
            return @"TaskInProgress";
        case GARCloudAnchorStateErrorNotAuthorized:
            return @"ErrorNotAuthorized";
        case GARCloudAnchorStateErrorResourceExhausted:
            return @"ErrorResourceExhausted";
        case GARCloudAnchorStateErrorServiceUnavailable:
            return @"ErrorServiceUnavailable";
        case GARCloudAnchorStateErrorHostingDatasetProcessingFailed:
            return @"ErrorHostingDatasetProcessingFailed";
        case GARCloudAnchorStateErrorCloudIdNotFound:
            return @"ErrorCloudIdNotFound";
        case GARCloudAnchorStateErrorResolvingSdkVersionTooNew:
            return @"ErrorResolvingSdkVersionTooNew";
        case GARCloudAnchorStateErrorResolvingSdkVersionTooOld:
            return @"ErrorResolvingSdkVersionTooOld";
        case GARCloudAnchorStateErrorResolvingLocalizationNoMatch:
            return @"ErrorResolvingLocalizationNoMatch";
    }
}

- (void)clearScreen {
    for (ARAnchor * anchor in self.drawAnchors) {
        [self.sceneView.session removeAnchor:anchor];
    }
    
    for (GARAnchor * anchor in self.cloudAnchors) {
        [self.gSession removeAnchor:anchor];
    }
    
    [self.drawAnchors removeAllObjects];
    [self.cloudAnchors removeAllObjects];
}

- (void)enterState:(ProgramState)state {
    
    self.sldSize.hidden = YES;
    self.btnCancelAdd.hidden = YES;
    self.btnConfirmAdd.hidden = YES;
    
    switch (state) {
        case ProgramStateDefault:
            [self clearScreen];
            
            self.room = nil;
            self.message = @"";
            
            break;
        case ProgramStateAddingToRoom:
            self.message = @"Tap anywhere on the screen to add image";
            break;
        case ProgramStateAddConfirm:
            self.message = @"Press confirm to confirm location";
            self.sldSize.hidden = NO;
            self.btnCancelAdd.hidden = NO;
            self.btnConfirmAdd.hidden = NO;
            break;
        case ProgramStateViewingRoom:
            self.message = [@"Viewing " stringByAppendingString:self.room.name];
            break;
        case ProgramStateEdittingRoom:
            self.message = [@"Editting " stringByAppendingString:self.room.name];
            break;
        case ProgramStateSaving:
            self.message = @"Saving anchor... Please hold still";
            break;
        case ProgramStateSavingFinished:
            self.message =
            [NSString stringWithFormat:@"Finished saving: %@",
             [self cloudStateString:self.garAnchor.cloudState]];
            break;
        case ProgramStateResolving:
            [self dismissViewControllerAnimated:NO completion:^{}];
            self.message = @"Resolving anchor...";
            //[self toggleButton:self.hostButton enabled:NO title:@"HOST"];
            //[self toggleButton:self.resolveButton enabled:YES title:@"CANCEL"];
            break;
        case ProgramStateResolvingFinished:
            self.message =
            [NSString stringWithFormat:@"Finished resolving: %@",
             [self cloudStateString:self.garAnchor.cloudState]];
            break;
    }
    self.state = state;
    [self updateMessageLabel];
}

#pragma mark - ARSCNViewDelegate

// This is where you handle adding in the

- (nullable SCNNode *)renderer:(id<SCNSceneRenderer>)renderer
                 nodeForAnchor:(ARAnchor *)anchor {
    if ([anchor isKindOfClass:[ARPlaneAnchor class]] == NO) {
        //SCNScene *scene = [SCNScene sceneNamed:@"example.scnassets/andy.scn"];
        //return [[scene rootNode] childNodeWithName:@"andy" recursively:NO];
        //UIImage * test = [UIImage imageNamed: @"Elon_Musk_2015"];
        NSLog(@"%f %f", self.imgToAdd.size.width, self.imgToAdd.size.height);
        SCNPlane * plane = [SCNPlane planeWithWidth: self.imgToAdd.size.width / 5000 height: self.imgToAdd.size.height / 5000];
        plane.firstMaterial.diffuse.contents = self.imgToAdd;
        SCNNode * node = [SCNNode nodeWithGeometry:plane];
        node.scale = SCNVector3Make(self.scalingFactor, self.scalingFactor, self.scalingFactor);
        self.currentNode = node;
        return node;
    } else {
        return [[SCNNode alloc] init];
    }
}

// These are exclusively for the plane

- (void)renderer:(id<SCNSceneRenderer>)renderer
      didAddNode:(SCNNode *)node
       forAnchor:(ARAnchor *)anchor {
    if ([anchor isKindOfClass:[ARPlaneAnchor class]]) {
        ARPlaneAnchor *planeAnchor = (ARPlaneAnchor *)anchor;
        
        CGFloat width = planeAnchor.extent.x;
        CGFloat height = planeAnchor.extent.z;
        SCNPlane *plane = [SCNPlane planeWithWidth:width height:height];
        
        plane.materials.firstObject.diffuse.contents =
        [UIColor colorWithRed:0.0f green:0.0f blue:1.0f alpha:0.3f];
        
        SCNNode *planeNode = [SCNNode nodeWithGeometry:plane];
        
        CGFloat x = planeAnchor.center.x;
        CGFloat y = planeAnchor.center.y;
        CGFloat z = planeAnchor.center.z;
        planeNode.position = SCNVector3Make(x, y, z);
        planeNode.eulerAngles = SCNVector3Make(-M_PI / 2, 0, 0);
        
        [node addChildNode:planeNode];
    }
}

- (void)renderer:(id<SCNSceneRenderer>)renderer
   didUpdateNode:(SCNNode *)node
       forAnchor:(ARAnchor *)anchor {
    if ([anchor isKindOfClass:[ARPlaneAnchor class]]) {
        ARPlaneAnchor *planeAnchor = (ARPlaneAnchor *)anchor;
        
        SCNNode *planeNode = node.childNodes.firstObject;
        SCNPlane *plane = (SCNPlane *)planeNode.geometry;
        
        CGFloat width = planeAnchor.extent.x;
        CGFloat height = planeAnchor.extent.z;
        plane.width = width;
        plane.height = height;
        
        CGFloat x = planeAnchor.center.x;
        CGFloat y = planeAnchor.center.y;
        CGFloat z = planeAnchor.center.z;
        planeNode.position = SCNVector3Make(x, y, z);
    }
}

- (void)renderer:(id<SCNSceneRenderer>)renderer
   didRemoveNode:(SCNNode *)node
       forAnchor:(ARAnchor *)anchor {
    if ([anchor isKindOfClass:[ARPlaneAnchor class]]) {
        SCNNode *planeNode = node.childNodes.firstObject;
        [planeNode removeFromParentNode];
    }
}

@end
