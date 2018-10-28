//
//  MenuViewController.h
//  ARtGallery
//
//  Created by Jacqueline on 6/19/18.
//

#import <UIKit/UIKit.h>

#import "NavigationViewController.h"

@class NavigationViewController;

@import SocketIO;

@interface MenuViewController : UIViewController

@property (strong, nonatomic) SocketIOClient *socket;
@property (strong, nonatomic) NavigationViewController* parent;

@property (weak, nonatomic) IBOutlet UILabel *lblStatus;
@property (weak, nonatomic) IBOutlet UIButton *btnRename;
@property (weak, nonatomic) IBOutlet UIButton *btnDelete;
@property (weak, nonatomic) IBOutlet UIButton *btnLeave;

- (void) initialize;

- (IBAction)btnRename_pressed:(id)sender;
- (IBAction)btnDelete_pressed:(id)sender;
- (IBAction)btnLeave_pressed:(id)sender;

@end
