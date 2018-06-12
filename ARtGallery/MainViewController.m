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
#import "Room.h"

#import <dispatch/dispatch.h>

#import <ARKit/ARKit.h>
#import <FirebaseDatabase/FirebaseDatabase.h>
#import <ARCore/ARCore.h>
#import <ModelIO/ModelIO.h>
#import <SceneKit/ModelIO.h>
#import <RNCryptor-objc/RNEncryptor.h>

typedef NS_ENUM(NSInteger, ProgramState) {
    ProgramStateDefault,
    ProgramStateCreatingRoom,
    ProgramStateViewingRoom,
    ProgramStateEdittingRoom,
    ProgramStateHosting,
    ProgramStateHostingFinished,
    ProgramStateResolving,
    ProgramStateResolvingFinished
};

typedef NS_ENUM(NSInteger, DialogType) {
    DialogTypeCreate,
    DialogTypeJoin,
    DialogTypeEdit,
    DialogTypeRename
};

@interface MainViewController () <ARSCNViewDelegate, ARSessionDelegate, GARSessionDelegate>

@property(nonatomic, strong) GARSession *gSession;

@property(nonatomic, strong) FIRDatabaseReference *firebaseReference;

@property(nonatomic, strong) NSMutableArray *currentDrawAnchors;
@property(nonatomic, strong) NSMutableArray *currentCloudAnchors;
@property(nonatomic, strong) ARAnchor *arAnchor;
@property(nonatomic, strong) GARAnchor *garAnchor;
//@property(nonatomic, strong) NSMutableArray *currentAnchorType;

@property(nonatomic, strong) Room *currentRoom;

@property(nonatomic, assign) ProgramState state;

@property(nonatomic, strong) NSString *roomCode;
@property(nonatomic, strong) NSString *message;

@property(nonatomic, strong) NSString *staticSalt;

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
    
    self.staticSalt = @"XXXXX";
    
    self.currentCloudAnchors = [NSMutableArray new];
    self.currentDrawAnchors = [NSMutableArray new];
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
    if (touches.count < 1 || self.state != ProgramStateEdittingRoom) {
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

# pragma mark - Actions

- (IBAction)btnCreate_pressed:(id)sender {
    if (self.state == ProgramStateDefault) {
        //[self enterState:ProgramStateCreatingRoom];
        [self roomNameDialog:DialogTypeCreate];
    } else {
        //[self enterState:ProgramStateDefault];
    }
}

- (IBAction)btnJoin_pressed:(id)sender {
    if (self.state == ProgramStateDefault) {
        //[self enterState:ProgramStateCreatingRoom];
        [self roomNameDialog:DialogTypeJoin];
    } else {
        //[self enterState:ProgramStateDefault];
    }
}

- (IBAction)btnEdit_pressed:(id)sender {
    if (self.state == ProgramStateDefault) {
        [self roomNameDialog:DialogTypeEdit];
    }
}

- (IBAction)btnDelete_pressed:(id)sender {
    if ((self.state == ProgramStateEdittingRoom || self.state == ProgramStateViewingRoom) && self.currentRoom) {
        [self deleteRoom: [self.currentRoom getName]];
    }
}

- (IBAction)btnLeave_pressed:(id)sender {
    if ((self.state == ProgramStateEdittingRoom || self.state == ProgramStateViewingRoom) && self.currentRoom) {
        [self leaveRoom];
    }
}

- (IBAction)lblRoomName_pressed:(id)sender {
    if ((self.state == ProgramStateEdittingRoom || self.state == ProgramStateViewingRoom) && self.currentRoom) {
        [self roomNameDialog:DialogTypeRename];
    }
}

#pragma mark room actions

- (void)createRoom : (NSString *)roomName : (NSString *)password{
    __weak MainViewController *weakSelf = self;
    
    [[self.firebaseReference child:@"room_names"] observeSingleEventOfType:FIRDataEventTypeValue withBlock:^(FIRDataSnapshot * _Nonnull snapshot) {
        MainViewController *strongSelf = weakSelf;
        
        NSMutableArray * nameList = snapshot.value;
        
        if ([nameList isEqual:[NSNull null]]) {
            NSLog(@"NameList is null");
            nameList = [NSMutableArray new];
        }
        
        if ([nameList containsObject: roomName]) {
            self.message = @"Room name already existed";
            [self updateMessageLabel];
        }
        else {
            [nameList addObject:roomName];
            
            long long timestampInteger = (long long)([[NSDate date] timeIntervalSince1970] * 1000);
            NSNumber *timestamp = [NSNumber numberWithLongLong:timestampInteger];
            
            NSData * salt = [[self.staticSalt stringByAppendingString:roomName] dataUsingEncoding:NSUTF8StringEncoding];
            NSData * hash = [RNCryptor keyForPassword:password salt:salt settings:kRNCryptorAES256Settings.keySettings];
            
            NSString * salt64 = [salt base64EncodedStringWithOptions:0];
            NSString * hash64 = [hash base64EncodedStringWithOptions:0];
            
            NSDictionary *room = @{
                                   @"updated_at_timestamp" : timestamp,
                                   @"salt" : salt64,
                                   @"hash" : hash64
                                   };
            
            [[[strongSelf.firebaseReference child:@"room_list"]
              child:roomName] setValue:room withCompletionBlock:^(NSError *error, FIRDatabaseReference *ref) {
                if (error) {
                    [self createRoomFailed:@"Error on saving the room to room list"];
                } else {
                    NSLog(@"Saved room info");
                    [[strongSelf.firebaseReference child:@"room_names"] setValue:nameList withCompletionBlock:^(NSError *error, FIRDatabaseReference *ref) {
                        if (error) {
                            [self createRoomFailed:@"Error on storing list of used name"];
                        } else {
                            id room = [[Room alloc] initWithName:roomName];
                            [self createRoomSuccess: room];
                        }
                    }];
                }
                
            }];
        }
        
    } withCancelBlock:^(NSError * _Nonnull error) {
        NSLog(@"%@", error.localizedDescription);
    }];
}

- (void) createRoomFailed:(NSString *) errMsg {
    NSLog(@"Failed to create room: %@", errMsg);
}

- (void) createRoomSuccess: (Room *)createdRoom {
    NSLog(@"Data saved successfully.");
    NSLog(@"Past all the trouble");
    
    self.currentRoom = createdRoom;
    
    [self enterState:ProgramStateEdittingRoom];
}

- (void)joinRoom:(NSString *)roomName {
    //__weak MainViewController *weakSelf = self; // self referencing
    
    [[self.firebaseReference child:@"room_names"] observeSingleEventOfType:FIRDataEventTypeValue withBlock:^(FIRDataSnapshot * _Nonnull snapshot) {
        //MainViewController *strongSelf = weakSelf;
        
        NSMutableArray *nameList = snapshot.value;
        
        if ([nameList isEqual:[NSNull null]] || ![nameList containsObject: roomName]) {
            self.message = @"Room doesn't exist";
            [self updateMessageLabel];
        }
        else {
            [[[self.firebaseReference child:@"room_list"] child:roomName] observeSingleEventOfType:FIRDataEventTypeValue withBlock:^(FIRDataSnapshot * _Nonnull snapshot) {
                //MainViewController *strongSelf = weakSelf;
                
                // Create a null anchor and attempt to load it with read information from database
                
                if ([snapshot.value isKindOfClass:[NSDictionary class]]) {
                    NSDictionary *data = snapshot.value;
                    
                    id room = [[Room alloc] initWithName:roomName];
                    if (room) {
                        NSLog(@"%@", [room getName]);
                        NSDictionary *objectList = data[@"objectList"];
                        if ([objectList isEqual:[NSNull null]]) {
                            objectList = [NSDictionary new];
                        }
                        else {
                            for (NSDictionary *object in objectList) {
                                NSString *anchor = object[@"id"];
                                NSNumber *type = object[@"type"];
                                
                                id arObj = [[ARObject alloc] initWithID:anchor type:(int)type resName:@""];
                                if (arObj) {
                                    [room addObject:arObj];
                                }
                                NSLog(@"%@, %@", anchor, type);
                            }
                        }
                        
                        self.currentRoom = room;
                    }
                }
            }];
            
            [self enterState:ProgramStateViewingRoom];
        }
    }];
}

- (void) loadRoom:(Room *)room {
    for (ARObject * arObj in room.objectList) {
        [self loadAnchor:arObj.getID];
    }
}

- (void) loadAnchor: (NSString *) anchorID {
    
}

- (void)editRoom:(NSString *)roomName : (NSString *) password {
    //__weak MainViewController *weakSelf = self; // self referencing
    
    [[self.firebaseReference child:@"room_names"] observeSingleEventOfType:FIRDataEventTypeValue withBlock:^(FIRDataSnapshot * _Nonnull snapshot) {
        //MainViewController *strongSelf = weakSelf;
        
        NSMutableArray *nameList = snapshot.value;
        
        if ([nameList isEqual:[NSNull null]] || ![nameList containsObject: roomName]) {
            self.message = @"Room doesn't exist";
            [self updateMessageLabel];
        }
        else {
            [[[self.firebaseReference child:@"room_list"] child:roomName] observeSingleEventOfType:FIRDataEventTypeValue withBlock:^(FIRDataSnapshot * _Nonnull snapshot) {
                //MainViewController *strongSelf = weakSelf;
                
                // Create a null anchor and attempt to load it with read information from database
                
                if ([snapshot.value isKindOfClass:[NSDictionary class]]) {
                    NSDictionary *data = snapshot.value;
                    
                    NSString * salt64 = data[@"salt"];
                    id salt = [[NSData alloc] initWithBase64EncodedString:salt64 options:0];
                    
                    NSData * hash = [RNCryptor keyForPassword:password salt:salt settings:kRNCryptorAES256Settings.keySettings];
                    NSString * hash64 = [hash base64EncodedStringWithOptions:0];
                    
                    
                    if ([hash64 isEqualToString:data[@"hash"]]) {
                        id room = [[Room alloc] initWithName:roomName];
                        if (room) {
                            NSLog(@"%@", [room getName]);
                            NSDictionary *objectList = data[@"objectList"];
                            if ([objectList isEqual:[NSNull null]]) {
                                objectList = [NSDictionary new];
                            }
                            else {
                                for (NSDictionary *object in objectList) {
                                    NSString *anchor = object[@"id"];
                                    NSNumber *type = object[@"type"];
                                    
                                    id arObj = [[ARObject alloc] initWithID:anchor type:(int)type resName:@""];
                                    if (arObj) {
                                        [room addObject:arObj];
                                    }
                                    NSLog(@"%@, %@", anchor, type);
                                }
                            }
                            
                            self.currentRoom = room;
                            [self enterState:ProgramStateEdittingRoom];
                        }
                    }
                    else {
                        NSLog(@"Wrong password");
                    }
                }
            }];
        }
    }];
}

- (void)deleteRoom:(NSString *)roomName {
    __weak MainViewController *weakSelf = self;
    
    [[self.firebaseReference child:@"room_names"] observeSingleEventOfType:FIRDataEventTypeValue withBlock:^(FIRDataSnapshot * _Nonnull snapshot) {
        MainViewController *strongSelf = weakSelf;
        
        if ([snapshot.value isKindOfClass:[NSMutableArray class]]) {
            NSMutableArray *nameList = snapshot.value;
            
            if ([nameList isEqual:[NSNull null]]) {
                NSLog(@"NameList is null");
                nameList = [NSMutableArray new];
            }
            
            if ([nameList containsObject: roomName]) {
                [[[strongSelf.firebaseReference child:@"room_list"]
                  child:roomName] removeValue];
                
                [[[strongSelf.firebaseReference child:@"room_names"]
                  child: [NSString stringWithFormat:@"%lu", [nameList indexOfObject: roomName]]] removeValue];
                
                [self enterState:ProgramStateDefault];
            }
            
            else {
                self.message = @"Room doesn't exist";
                [self updateMessageLabel];
            }
        }
    }];
}

- (void)leaveRoom {
    if ((self.state == ProgramStateEdittingRoom || self.state == ProgramStateViewingRoom) && self.currentRoom) {
        [self enterState:ProgramStateDefault];
    }
}

- (void)renameRoom : (NSString *)newName : (NSString *)oldName{
    __weak MainViewController *weakSelf = self;
    
    [[self.firebaseReference child:@"room_names"] observeSingleEventOfType:FIRDataEventTypeValue withBlock:^(FIRDataSnapshot * _Nonnull snapshot) {
        MainViewController *strongSelf = weakSelf;
        
        if ([snapshot.value isKindOfClass:[NSMutableArray class]]) {
            NSMutableArray *nameList = snapshot.value;
            
            if ([nameList isEqual:[NSNull null]]) {
                NSLog(@"NameList is null");
                nameList = [NSMutableArray new];
            }
            
            if ([nameList containsObject: newName]) {
                self.message = @"Room name already exist";
                [self updateMessageLabel];
            }
            else {
                if ([nameList containsObject: oldName]) {
                    [nameList removeObject:oldName];
                    [nameList addObject:newName];
                    
                    long long timestampInteger = (long long)([[NSDate date] timeIntervalSince1970] * 1000);
                    NSNumber *timestamp = [NSNumber numberWithLongLong:timestampInteger];
                    
                    [[[self.firebaseReference child:@"room_list"] child:oldName] observeSingleEventOfType:FIRDataEventTypeValue withBlock:^(FIRDataSnapshot * _Nonnull snapshot) {
            
                        if ([snapshot.value isKindOfClass:[NSDictionary class]]) {
                            NSDictionary *data = snapshot.value;
                            
                            NSString * salt64 = data[@"salt"];
                            NSString * hash64 = data[@"hash"];
                            
                            NSDictionary *room = @{
                                                   @"updated_at_timestamp" : timestamp,
                                                   @"salt" : salt64,
                                                   @"hash" : hash64
                                                   };
                            
                            [[[strongSelf.firebaseReference child:@"room_list"]
                              child:newName] setValue:room withCompletionBlock:^(NSError *error, FIRDatabaseReference *ref) {
                                if (error) {
                                    [self createRoomFailed:@"Error on saving the room to room list"];
                                } else {
                                    NSLog(@"Saved room info");
                                    [[strongSelf.firebaseReference child:@"room_names"] setValue:nameList withCompletionBlock:^(NSError *error, FIRDatabaseReference *ref) {
                                        if (error) {
                                            //[self createRoomFailed:@"Error on storing list of used name"];
                                        } else {
                                            [self.currentRoom setName:newName];
                                            
                                            [[[strongSelf.firebaseReference child:@"room_list"]
                                              child:oldName] removeValue];
                                            
                                            self.roomCode = newName;
                                            self.message = @"Successfully renamed the room";
                                            [self updateMessageLabel];
                                        }
                                    }];
                                }
                            }];
                        }
                    }];
                }
            }
        }
    } withCancelBlock:^(NSError * _Nonnull error) {
        NSLog(@"%@", error.localizedDescription);
    }];
}

- (void)resolveAnchorWithRoomCode_old:(NSString *)roomCode {
    
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
    
    [self.currentDrawAnchors addObject:self.arAnchor];
    
    // To share an anchor, we call host anchor here on the ARCore session.
    // session:disHostAnchor: session:didFailToHostAnchor: will get called appropriately.
    self.garAnchor = [self.gSession hostCloudAnchor:self.arAnchor error:nil];
    [self enterState:ProgramStateHosting];
}

#pragma mark - GARSessionDelegate

- (void)session:(GARSession *)session didHostAnchor:(GARAnchor *)anchor {
    
    // This function run the anchor is soccessfully hosted
    if (self.state != ProgramStateHosting || ![anchor isEqual:self.garAnchor]) {
        return;
    }
    self.garAnchor = anchor;
    
    [self.currentCloudAnchors addObject:anchor];
    
    [self enterState:ProgramStateEdittingRoom];
    
    // anchor to firebase
    [[[[self.firebaseReference child:@"room_list"] child:[_currentRoom getName]] child:anchor.cloudIdentifier]
     setValue:anchor.cloudIdentifier];
    
    // Write timestamp to firebase
    long long timestampInteger = (long long)([[NSDate date] timeIntervalSince1970] * 1000);
    NSNumber *timestamp = [NSNumber numberWithLongLong:timestampInteger];
    [[[[self.firebaseReference child:@"room_list"] child:[_currentRoom getName]]
      child:@"updated_at_timestamp"] setValue:timestamp];
}

- (void)session:(GARSession *)session didFailToHostAnchor:(GARAnchor *)anchor {
    // Run when anchor can't be hosted
    if (self.state != ProgramStateHosting || ![anchor isEqual:self.garAnchor]) {
        return;
    }
    
    // Sample code just consider it to be a fail experiment, don't do anything and just change the state
    self.garAnchor = anchor;
    [self.sceneView.session removeAnchor:self.arAnchor];
    [self.currentDrawAnchors removeObject:self.arAnchor];
    [self enterState:ProgramStateEdittingRoom];
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
    self.lblRoomName.text = [NSString stringWithFormat:@"Room: %@", self.roomCode];
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

- (void)enterState:(ProgramState)state {
    switch (state) {
        case ProgramStateDefault:
            self.currentRoom = nil;
            
            for (ARAnchor * anchor in self.currentDrawAnchors) {
                [self.sceneView.session removeAnchor:anchor];
            }
            
            for (GARAnchor * anchor in self.currentCloudAnchors) {
                [self.gSession removeAnchor:anchor];
            }
            
            self.currentDrawAnchors = [NSMutableArray new];
            self.currentCloudAnchors = [NSMutableArray new];
            
            [self toggleButton:self.btnCreate enabled:YES title:@"Create"];
            [self toggleButton:self.btnJoin enabled:YES title:@"Join"];
            [self toggleButton:self.btnEdit enabled:YES title:@"Edit"];
            [self toggleButton:self.btnDelete enabled:NO title:@"Delete"];
            [self toggleButton:self.btnLeave enabled:NO title:@"Leave"];
            
            self.roomCode = @"N/A";
            self.message = @"";
            
            /*if (self.arAnchor) {
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
            */
            break;
        case ProgramStateCreatingRoom:
            self.message = [@"Creating " stringByAppendingString:self.roomCode];
            [self toggleButton:self.btnCreate enabled:NO title:@"Create"];
            [self toggleButton:self.btnJoin enabled:NO title:@"Join"];
            [self toggleButton:self.btnEdit enabled:NO title:@"Edit"];
            [self toggleButton:self.btnDelete enabled:NO title:@"Delete"];
            [self toggleButton:self.btnLeave enabled:NO title:@"Leave"];
            break;
        case ProgramStateViewingRoom:
            self.message = [@"Viewing " stringByAppendingString:self.roomCode];
            [self toggleButton:self.btnCreate enabled:NO title:@"Create"];
            [self toggleButton:self.btnJoin enabled:NO title:@"Join"];
            [self toggleButton:self.btnEdit enabled:NO title:@"Edit"];
            [self toggleButton:self.btnDelete enabled:NO title:@"Delete"];
            [self toggleButton:self.btnLeave enabled:YES title:@"Leave"];
            break;
        case ProgramStateEdittingRoom:
            self.message = [@"Editting " stringByAppendingString:self.roomCode];
            [self toggleButton:self.btnCreate enabled:NO title:@"Create"];
            [self toggleButton:self.btnJoin enabled:NO title:@"Join"];
            [self toggleButton:self.btnEdit enabled:NO title:@"Edit"];
            [self toggleButton:self.btnDelete enabled:YES title:@"Delete"];
            [self toggleButton:self.btnLeave enabled:YES title:@"Leave"];
            break;
        case ProgramStateHosting:
            self.message = @"Hosting anchor...";
            break;
        case ProgramStateHostingFinished:
            self.message =
            [NSString stringWithFormat:@"Finished hosting: %@",
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

- (void)roomNameDialog: (DialogType)type{
    UIAlertController *alertController =
    [UIAlertController alertControllerWithTitle:@"ENTER ROOM NAME"
                                        message:@""
                                 preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *okAction =
    [UIAlertAction actionWithTitle:@"OK"
                             style:UIAlertActionStyleDefault
                           handler:^(UIAlertAction *action) {
                               NSString *roomName = alertController.textFields[0].text;
                               NSString *password = alertController.textFields[1].text;
                               if ([roomName length] == 0) {
                                   //[self enterState:ProgramStateDefault];
                               } else {
                                   //[self resolveAnchorWithRoomCode:roomCode];
                                   self.roomCode = roomName;
                                   switch (type) {
                                       case DialogTypeCreate:
                                           [self createRoom:roomName : password];
                                           break;
                                       case DialogTypeJoin:
                                           [self joinRoom:roomName];
                                           break;
                                       case DialogTypeEdit:
                                           [self editRoom:roomName : password];
                                           break;
                                       case DialogTypeRename:
                                           [self renameRoom:roomName : [self.currentRoom getName]];
                                   }
                                   
                               }
                           }];
    UIAlertAction *cancelAction =
    [UIAlertAction actionWithTitle:@"CANCEL"
                             style:UIAlertActionStyleDefault
                           handler:^(UIAlertAction *action) {
                               [self enterState:ProgramStateDefault];
                           }];
    [alertController addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.keyboardType = UIKeyboardTypeDefault;
    }];
    [alertController addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.keyboardType = UIKeyboardTypeDefault;
        if (type != DialogTypeCreate && type != DialogTypeEdit) {
            [textField setEnabled:false];
        }
    }];
    [alertController addAction:okAction];
    [alertController addAction:cancelAction];
    [self presentViewController:alertController animated:NO completion:^{}];
}

- (void)roomCreated:(NSString *)roomCode {
    self.roomCode = roomCode;
    //[self enterState:ProgramStateRoomCreated];
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
