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

#import <UIKit/UIKit.h>
#import <SceneKit/SceneKit.h>
#import <SceneKit/ModelIO.h>
#import <ARKit/ARKit.h>
#import <ARCore/ARCore.h>
#import <ModelIO/ModelIO.h>
#import <FirebaseDatabase/FirebaseDatabase.h>

#import <dispatch/dispatch.h>

#import "NavigationViewController.h"

#import "Room.h"
#import "Storage.h"
#import "ViewTypeEnum.h"
//#import "GreetViewController.h"

@import SocketIO;

@class NavigationViewController;

typedef NS_ENUM(NSInteger, ProgramState) {
    ProgramStateDefault,
    ProgramStateViewingRoom,
    ProgramStateEdittingRoom,
    ProgramStateAddingToRoom,
    ProgramStateAddConfirm,
    ProgramStateSaving,
    ProgramStateSavingFinished,
    ProgramStateResolving,
    ProgramStateResolvingFinished
};

@interface MainViewController : UIViewController <ARSCNViewDelegate, ARSessionDelegate, GARSessionDelegate>

@property (strong, nonatomic) NavigationViewController* parent;

@property (strong, nonatomic) SocketIOClient* socket;
@property (strong, nonatomic) Storage *storage;
@property (strong, nonatomic) Room *room;
@property (assign, nonatomic) ViewType viewType;

@property (assign, nonatomic) ProgramState state;

@property (strong, nonatomic) GARSession *gSession;
@property (strong, nonatomic) ARAnchor *arAnchor;
@property (strong, nonatomic) GARAnchor *garAnchor;
@property (strong, nonatomic) SCNNode *currentNode;
@property (strong, nonatomic) ARWorldTrackingConfiguration *configuration;

@property (strong, nonatomic) IBOutlet ARSCNView *sceneView;

@property (weak, nonatomic) IBOutlet UILabel *lblRoomName;
@property (weak, nonatomic) IBOutlet UILabel *messageLabel;
@property (weak, nonatomic) IBOutlet UISlider *sldSize;
@property (weak, nonatomic) IBOutlet UIButton *btnCancelAdd;
@property (weak, nonatomic) IBOutlet UIButton *btnConfirmAdd;

@property (strong, nonatomic) NSMutableArray *drawAnchors;
@property (strong, nonatomic) NSMutableDictionary *drawnAnchors;
@property (strong, nonatomic) NSMutableArray *cloudAnchors;

@property (strong, nonatomic) NSMutableDictionary *loadList;
@property (strong, nonatomic) NSMutableDictionary *loadingList;

@property (strong, nonatomic) UIImage *imgToAdd;
@property (assign, nonatomic) float scalingFactor;

- (IBAction)btnCancelAdd_pressed:(id)sender;
- (IBAction)btnConfirmAdd_pressed:(id)sender;
- (IBAction)sldSize_valueChanged:(id)sender;

- (void)initialize;
- (void)initializeAddMode:(UIImage *)toAdd;
- (ViewType)getViewType;
- (void)removeARObject:(NSString*)identifier;

@end
