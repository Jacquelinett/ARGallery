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

#import <dispatch/dispatch.h>

#import <ARKit/ARKit.h>
#import <FirebaseDatabase/FirebaseDatabase.h>
#import <ARCore/ARCore.h>
#import <ModelIO/ModelIO.h>
#import <SceneKit/ModelIO.h>

typedef NS_ENUM(NSInteger, AnchorType) {
    AnchorTypeDefault,
    AnchorTypePicture,
    AnchorTypeVideo
};

typedef NS_ENUM(NSInteger, ProgramState) {
    ProgramStateDefault,
    ProgramStateCreatingRoom,
    ProgramStateRoomCreated,
    ProgramStateInRoom,
    ProgramStateHosting,
    ProgramStateHostingFinished,
    ProgramStateEnterRoomCode,
    ProgramStateResolving,
    ProgramStateResolvingFinished
};

@interface MainViewController () <ARSCNViewDelegate, ARSessionDelegate, GARSessionDelegate>

@property(nonatomic, strong) GARSession *gSession;

@property(nonatomic, strong) FIRDatabaseReference *firebaseReference;

@property(nonatomic, strong) ARAnchor *arAnchor;
@property(nonatomic, strong) GARAnchor *garAnchor;

@property(nonatomic, assign) ProgramState state;

@property(nonatomic, strong) NSString *roomCode;
@property(nonatomic, strong) NSString *message;

@end

@implementation MainViewController

#pragma mark - Overriding UIViewController

- (BOOL)prefersStatusBarHidden {
    return NO;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // These just initialize scene/storyboard stuff + firebase and google stuff
    
    self.firebaseReference = [[FIRDatabase database] reference];
    self.sceneView.delegate = self;
    self.sceneView.session.delegate = self;
    self.gSession = [GARSession sessionWithAPIKey:@"XXXXX"
                                 bundleIdentifier:@"XXXXX"
                                            error:nil];
    self.gSession.delegate = self;
    self.gSession.delegateQueue = dispatch_get_main_queue();
    
    // Once finish initializing, enter the default state
    [self enterState:ProgramStateDefault];
}

- (void)viewWillAppear:(BOOL)animated {
    // This just set up the configuration
    // To be honest I don't understand what's going on behind the screen
    // But I know it work
    [super viewWillAppear:animated];
    
    ARWorldTrackingConfiguration *configuration = [ARWorldTrackingConfiguration new];
    [configuration setWorldAlignment:ARWorldAlignmentGravity];
    [configuration setPlaneDetection:ARPlaneDetectionHorizontal];
    
    [self.sceneView.session runWithConfiguration:configuration];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.sceneView.session pause];
}


- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    if (touches.count < 1 || self.state != ProgramStateRoomCreated) {
        return;
    }
    
    // This is where the magic of placing an anchor happen
    // No mention of placing the actual image, just the anchor
    // TODO: Turn this to a drag and drop
    
    UITouch *touch = [[touches allObjects] firstObject];
    CGPoint touchLocation = [touch locationInView:self.sceneView];
    
    NSArray *hitTestResults =
    [self.sceneView hitTest:touchLocation
                      types:ARHitTestResultTypeExistingPlane |
     ARHitTestResultTypeExistingPlaneUsingExtent |
     ARHitTestResultTypeEstimatedHorizontalPlane];
    
    if (hitTestResults.count > 0) {
        ARHitTestResult *result = [hitTestResults firstObject];
        [self addAnchorWithTransform:result.worldTransform];
    }
}

#pragma mark - Anchor Hosting / Resolving

- (void)resolveAnchorWithRoomCode:(NSString *)roomCode {
    
    // When this function is called, you pass in a room code as an argument
    self.roomCode = roomCode;
    [self enterState:ProgramStateResolving];
    __weak MainViewController *weakSelf = self; // self referencing
    
    
    // child: @name of sub-table of the database
    [[[self.firebaseReference child:@"hotspot_list"] child:roomCode]
     
     // How Firebase listen for every data: https://firebase.google.com/docs/database/ios/read-and-write
     observeEventType:FIRDataEventTypeValue
     withBlock:^(FIRDataSnapshot *snapshot) {
         
         // Again, I don't know what going on behind screen
         // But from my understanding this is essentially create a new thread or something and run asynchronously in the background
         // To grab and process information without intefering with the program
         dispatch_async(dispatch_get_main_queue(), ^{
             MainViewController *strongSelf = weakSelf;
             
             // Since this is now running asynchronously and in the background
             // We will need to check everytime it run to be sure that
             // The view is not faulty (not nil) and in the correct state
             if (strongSelf == nil || strongSelf.state != ProgramStateResolving ||
                 ![strongSelf.roomCode isEqualToString:roomCode]) {
                 return;
             }
             
             
             // Create a null anchor and attempt to load it with read information from database
             NSString *anchorId = nil;
             if ([snapshot.value isKindOfClass:[NSDictionary class]]) {
                 NSDictionary *value = (NSDictionary *)snapshot.value;
                 anchorId = value[@"hosted_anchor_id"];
             }
             
             if (anchorId) {
                 [[[strongSelf.firebaseReference child:@"hotspot_list"] child:roomCode]
                  removeAllObservers];
                 [strongSelf resolveAnchorWithIdentifier:anchorId];
             }
         });
     }];
}

- (void)resolveAnchorWithIdentifier:(NSString *)identifier {
    // Now that we have the anchor ID from firebase, we resolve the anchor.
    // Success and failure of this call is handled by the delegate methods
    
    // session:didResolveAnchor and session:didFailToResolveAnchor appropriately.
    self.garAnchor = [self.gSession resolveCloudAnchorWithIdentifier:identifier error:nil];
}

- (void)addAnchorWithTransform:(matrix_float4x4)transform {
    self.arAnchor = [[ARAnchor alloc] initWithTransform:transform];
    [self.sceneView.session addAnchor:self.arAnchor];
    
    // To share an anchor, we call host anchor here on the ARCore session.
    // session:disHostAnchor: session:didFailToHostAnchor: will get called appropriately.
    self.garAnchor = [self.gSession hostCloudAnchor:self.arAnchor error:nil];
    [self enterState:ProgramStateHosting];
}


# pragma mark - Actions

- (IBAction)hostButtonPressed {
    if (self.state == ProgramStateDefault) {
        [self enterState:ProgramStateCreatingRoom];
        [self createRoom];
    } else {
        [self enterState:ProgramStateDefault];
    }
}

- (IBAction)resolveButtonPressed {
    if (self.state == ProgramStateDefault) {
        [self enterState:ProgramStateEnterRoomCode];
    } else {
        [self enterState:ProgramStateDefault];
    }
}

#pragma mark - GARSessionDelegate

- (void)session:(GARSession *)session didHostAnchor:(GARAnchor *)anchor {
    
    // This function run the anchor is soccessfully hosted
    if (self.state != ProgramStateHosting || ![anchor isEqual:self.garAnchor]) {
        return;
    }
    self.garAnchor = anchor;
    [self enterState:ProgramStateHostingFinished];
    // Write room + anchor to firebase
    [[[[self.firebaseReference child:@"hotspot_list"] child:self.roomCode] child:@"hosted_anchor_id"]
     setValue:anchor.cloudIdentifier];
    
    // Write timestamp to firebase
    long long timestampInteger = (long long)([[NSDate date] timeIntervalSince1970] * 1000);
    NSNumber *timestamp = [NSNumber numberWithLongLong:timestampInteger];
    [[[[self.firebaseReference child:@"hotspot_list"] child:self.roomCode]
      child:@"updated_at_timestamp"] setValue:timestamp];
}

- (void)session:(GARSession *)session didFailToHostAnchor:(GARAnchor *)anchor {
    // Run when anchor can't be hosted
    if (self.state != ProgramStateHosting || ![anchor isEqual:self.garAnchor]) {
        return;
    }
    
    // Sample code just consider it to be a fail experiment, don't do anything and just change the state
    self.garAnchor = anchor;
    [self enterState:ProgramStateHostingFinished];
}

- (void)session:(GARSession *)session didResolveAnchor:(GARAnchor *)anchor {
    
    // Same thing as the successful host anchor but this is for resolve
    // The anchor is passed back as an argument
    if (self.state != ProgramStateResolving || ![anchor isEqual:self.garAnchor]) {
        return;
    }
    
    // Set up anchor
    // IMPORTANT: GARAnchor is what being send/receive as data, probably exclusively a ARCore thing
    // ARAnchor on the other hand, I THINK (not confirmed) is an ARKit thing, as ARCore is built
    // on ARKit, and thus the rendering is handle by ARKit hence use ARKit's ARAnchor
    self.garAnchor = anchor;
    self.arAnchor = [[ARAnchor alloc] initWithTransform:anchor.transform];
    [self.sceneView.session addAnchor:self.arAnchor];
    [self enterState:ProgramStateResolvingFinished];
}

- (void)session:(GARSession *)session didFailToResolveAnchor:(GARAnchor *)anchor {
    if (self.state != ProgramStateResolving || ![anchor isEqual:self.garAnchor]) {
        return;
    }
    self.garAnchor = anchor;
    [self enterState:ProgramStateResolvingFinished];
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
    self.roomCodeLabel.text = [NSString stringWithFormat:@"Room: %@", self.roomCode];
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

// This is for resolving button
- (void)showRoomCodeDialog {
    UIAlertController *alertController =
    [UIAlertController alertControllerWithTitle:@"ENTER ROOM CODE"
                                        message:@""
                                 preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *okAction =
    [UIAlertAction actionWithTitle:@"OK"
                             style:UIAlertActionStyleDefault
                           handler:^(UIAlertAction *action) {
                               NSString *roomCode = alertController.textFields[0].text;
                               if ([roomCode length] == 0) {
                                   [self enterState:ProgramStateDefault];
                               } else {
                                   [self resolveAnchorWithRoomCode:roomCode];
                               }
                           }];
    UIAlertAction *cancelAction =
    [UIAlertAction actionWithTitle:@"CANCEL"
                             style:UIAlertActionStyleDefault
                           handler:^(UIAlertAction *action) {
                               [self enterState:ProgramStateDefault];
                           }];
    [alertController addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.keyboardType = UIKeyboardTypeNumberPad;
    }];
    [alertController addAction:okAction];
    [alertController addAction:cancelAction];
    [self presentViewController:alertController animated:NO completion:^{}];
}

- (void)enterState:(ProgramState)state {
    switch (state) {
        case ProgramStateDefault:
            if (self.arAnchor) {
                [self.sceneView.session removeAnchor:self.arAnchor];
                self.arAnchor = nil;
            }
            if (self.garAnchor) {
                [self.gSession removeAnchor:self.garAnchor];
                self.garAnchor = nil;
            }
            if (self.state == ProgramStateCreatingRoom) {
                self.message = @"Failed to create room. Tap HOST or RESOLVE to begin.";
            } else {
                self.message = @"Tap HOST or RESOLVE to begin.";
            }
            if (self.state == ProgramStateEnterRoomCode) {
                [self dismissViewControllerAnimated:NO completion:^{}];
            } else if (self.state == ProgramStateResolving) {
                [[[self.firebaseReference child:@"hotspot_list"] child:self.roomCode] removeAllObservers];
            }
            [self toggleButton:self.hostButton enabled:YES title:@"HOST"];
            [self toggleButton:self.resolveButton enabled:YES title:@"RESOLVE"];
            self.roomCode = @"";
            break;
        case ProgramStateCreatingRoom:
            self.message = @"Creating room...";
            [self toggleButton:self.hostButton enabled:NO title:@"HOST"];
            [self toggleButton:self.resolveButton enabled:NO title:@"RESOLVE"];
            break;
        case ProgramStateRoomCreated:
            self.message = @"Tap on a plane to create anchor and host.";
            [self toggleButton:self.hostButton enabled:YES title:@"CANCEL"];
            [self toggleButton:self.resolveButton enabled:NO title:@"RESOLVE"];
            break;
        case ProgramStateHosting:
            self.message = @"Hosting anchor...";
            break;
        case ProgramStateHostingFinished:
            self.message =
            [NSString stringWithFormat:@"Finished hosting: %@",
             [self cloudStateString:self.garAnchor.cloudState]];
            break;
        case ProgramStateEnterRoomCode:
            [self showRoomCodeDialog];
            break;
        case ProgramStateResolving:
            [self dismissViewControllerAnimated:NO completion:^{}];
            self.message = @"Resolving anchor...";
            [self toggleButton:self.hostButton enabled:NO title:@"HOST"];
            [self toggleButton:self.resolveButton enabled:YES title:@"CANCEL"];
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

// Note in this case, room is automatically created every time an anchor is hosted,
- (void)createRoom {
    __weak MainViewController *weakSelf = self;
    [[self.firebaseReference child:@"last_room_code"]
     runTransactionBlock:^FIRTransactionResult *(FIRMutableData *currentData) {
         MainViewController *strongSelf = weakSelf;
         
         NSNumber *roomNumber = currentData.value;
         
         if (!roomNumber || [roomNumber isEqual:[NSNull null]]) {
             roomNumber = @0;
         }
         
         NSInteger roomNumberInt = [roomNumber integerValue];
         roomNumberInt++;
         NSNumber *newRoomNumber = [NSNumber numberWithInteger:roomNumberInt];
         
         long long timestampInteger = (long long)([[NSDate date] timeIntervalSince1970] * 1000);
         NSNumber *timestamp = [NSNumber numberWithLongLong:timestampInteger];
         
         NSDictionary *room = @{
                                @"display_name" : [newRoomNumber stringValue],
                                @"updated_at_timestamp" : timestamp,
                                };
         
         [[[strongSelf.firebaseReference child:@"hotspot_list"]
           child:[newRoomNumber stringValue]] setValue:room];
         
         currentData.value = newRoomNumber;
         
         return [FIRTransactionResult successWithValue:currentData];
     } andCompletionBlock:^(NSError *error, BOOL committed, FIRDataSnapshot *snapshot) {
         dispatch_async(dispatch_get_main_queue(), ^{
             if (error) {
                 [weakSelf roomCreationFailed];
             } else {
                 [weakSelf roomCreated:[(NSNumber *)snapshot.value stringValue]];
             }
         });
     }];
}

- (void)roomCreated:(NSString *)roomCode {
    self.roomCode = roomCode;
    [self enterState:ProgramStateRoomCreated];
}

- (void)roomCreationFailed {
    [self enterState:ProgramStateDefault];
}

#pragma mark - ARSCNViewDelegate

- (nullable SCNNode *)renderer:(id<SCNSceneRenderer>)renderer
                 nodeForAnchor:(ARAnchor *)anchor {
    if ([anchor isKindOfClass:[ARPlaneAnchor class]] == NO) {
        SCNScene *scene = [SCNScene sceneNamed:@"example.scnassets/andy.scn"];
        return [[scene rootNode] childNodeWithName:@"andy" recursively:NO];
    } else {
        return [[SCNNode alloc] init];
    }
}

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
