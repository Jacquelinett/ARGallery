//
//  GreetViewController.h
//  ARtGallery
//
//  Created by Jacqueline on 6/15/18.
//

#import <UIKit/UIKit.h>

#import "LoginViewController.h"
#import "Storage.h"
#import "ViewTypeEnum.h"

@import SocketIO;
@interface GreetViewController : UIViewController

@property (strong, nonatomic) SocketIOClient *socket;
@property (strong, nonatomic) SocketManager *manager;
@property (strong, nonatomic) Storage *storage;
@property (assign, nonatomic) ViewType selectedType;

@property (weak, nonatomic) IBOutlet UIButton *btnJoin;
@property (weak, nonatomic) IBOutlet UIButton *btnEdit;

- (IBAction)btnJoin_pressed:(id)sender;
- (IBAction)btnEdit_pressed:(id)sender;

@end

