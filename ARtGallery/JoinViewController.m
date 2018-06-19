//
//  JoinViewController.m
//  ARtGallery
//
//  Created by Jacqueline on 6/15/18.
//

#import "JoinViewController.h"

@interface JoinViewController ()

@end

@implementation JoinViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.firebaseReference = [[FIRDatabase database] reference];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)btnSee_pressed:(id)sender {
    [[self view] endEditing:YES];
    [_lblStatus setText:@"Connecting..."];
    if ([_txtRoomName.text isEqualToString:@""])
        [_lblStatus setText:@"Please enter a name"];
    else
        [self joinRoom:_txtRoomName.text];
}

- (void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    [[self view] endEditing:YES];
}

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    return YES;
}

// It is important for you to hide the keyboard
- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return YES;
}

- (void)joinRoom:(NSString *)roomName {
    [[self.firebaseReference child:@"room_names"] observeSingleEventOfType:FIRDataEventTypeValue withBlock:^(FIRDataSnapshot * _Nonnull snapshot) {
        NSMutableArray *nameList = snapshot.value;
        
        if ([nameList isEqual:[NSNull null]] || ![nameList containsObject: roomName]) {
            [self.lblStatus setText:@"Room doesn't exist"];
        }
        else {
            [[[self.firebaseReference child:@"room_list"] child:roomName] observeSingleEventOfType:FIRDataEventTypeValue withBlock:^(FIRDataSnapshot * _Nonnull snapshot) {
                // Create a null anchor and attempt to load it with read information from database
                if ([snapshot.value isKindOfClass:[NSDictionary class]]) {
                    NSDictionary *data = snapshot.value;
                    
                    id room = [[Room alloc] initWithName:roomName];
                    if (room) {
                        NSDictionary *objectList = data[@"objectList"];
                        if ([objectList isEqual:[NSNull null]]) {
                            objectList = [NSDictionary new];
                        }
                        else {
                            for(id key in objectList) {
                                NSDictionary * value = [objectList objectForKey:key];
                                
                                NSString *anchor = value[@"anchorID"];
                                NSString *resource = value[@"resourceID"];
                                NSNumber *type = value[@"type"];
                                
                                id arObj = [[ARObject alloc] initWithID:anchor resource:resource type:(int)type];
                                if (arObj) {
                                    [room addARObject:arObj];
                                }
                            }
                        }
                        
                        self.room = room;
                        
                        [self.lblStatus setText:@""];
                        [self performSegueWithIdentifier:@"segSee" sender:nil];
                    }
                }
            }];
        }
    }];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
*/

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    if ([[segue identifier] isEqualToString:@"segSee"]) {
        MainViewController *viewController = [segue destinationViewController];
        [viewController setRoom : self.room viewType:ViewTypeJoin];
    }
}

@end
