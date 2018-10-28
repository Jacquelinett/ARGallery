//
//  JoinViewController.h
//  ARtGallery
//
//  Created by Jacqueline on 6/15/18.
//

#import <UIKit/UIKit.h>
#import <FirebaseDatabase/FirebaseDatabase.h>
#import "Room.h"
#import "Storage.h"
#import "NavigationViewController.h"

@import SocketIO;

@interface JoinViewController : UIViewController <UITextFieldDelegate>

@property (strong, nonatomic) SocketIOClient *socket;

@property (weak, nonatomic) IBOutlet UITextField *txtRoomName;
@property (weak, nonatomic) IBOutlet UIButton *btnSee;
@property (weak, nonatomic) IBOutlet UIButton *btnBack;
@property (weak, nonatomic) IBOutlet UILabel *lblStatus;

@property (strong, nonatomic) FIRDatabaseReference *firebaseReference;
@property (strong, nonatomic) Room *room;

- (void)joinRoom:(NSString *)roomName;

- (IBAction)btnSee_pressed:(id)sender;
- (IBAction)btnBack_pressed:(id)sender;
- (void) initialize:(SocketIOClient*)socket;

@end
