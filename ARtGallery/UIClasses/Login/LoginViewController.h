//
//  LoginViewController.h
//  ARtGallery
//
//  Created by Jacqueline on 6/15/18.
//

#import <UIKit/UIKit.h>
#import <FirebaseDatabase/FirebaseDatabase.h>
#import "NavigationViewController.h"
#import "Room.h"
#import "ARObject.h"
#import "Storage.h"
#import "ViewTypeEnum.h"
#import "ResourceType.h"

@import SocketIO;

@interface LoginViewController : UIViewController <UITextFieldDelegate>

@property (strong, nonatomic) SocketIOClient *socket;
@property (strong, nonatomic) SocketManager *manager;
@property (strong, nonatomic) Storage *storage;
@property (assign, nonatomic) ViewType selectedType;
@property (assign, nonatomic) int loadingCount;

@property (weak, nonatomic) IBOutlet UITextField *txtRoomName;
@property (strong, nonatomic) IBOutlet UITextField *txtRoomPassword;
@property (weak, nonatomic) IBOutlet UIButton *btnEnter;
@property (weak, nonatomic) IBOutlet UIButton *btnBack;
@property (weak, nonatomic) IBOutlet UILabel *lblStatus;

@property (strong, nonatomic) Room *room;

- (void)joinRoom:(NSString *)roomName;
- (void)editRoom:(NSString *)roomName and:(NSString *)password;

- (IBAction)btnEnter_pressed:(id)sender;
- (IBAction)btnBack_pressed:(id)sender;
- (void) initialize:(SocketIOClient *)socket storage:(Storage *)storage view:(ViewType)type;

@end
