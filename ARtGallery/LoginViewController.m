//
//  LoginViewController.m
//  ARtGallery
//
//  Created by Jacqueline on 6/15/18.
//

#import "LoginViewController.h"

@interface LoginViewController ()

@end

@implementation LoginViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.firebaseReference = [[FIRDatabase database] reference];
    self.staticSalt = @"XXXXX";
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)btnEdit_pressed:(id)sender {
    [[self view] endEditing:YES];
    [_lblStatus setText:@"Connecting..."];
    [self createOrEditRoom:_txtRoomName.text : _txtRoomPassword.text];
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

- (void)createOrEditRoom : (NSString *)roomName : (NSString *)password{
    [[self.firebaseReference child:@"room_names"] observeSingleEventOfType:FIRDataEventTypeValue withBlock:^(FIRDataSnapshot * _Nonnull snapshot) {
        NSMutableArray * nameList = snapshot.value;
        
        if ([nameList isEqual:[NSNull null]]) {
            NSLog(@"NameList is null");
            nameList = [NSMutableArray new];
        }
        
        // If room already exist
        if ([nameList containsObject: roomName]) {
            [[[self.firebaseReference child:@"room_list"] child:roomName] observeSingleEventOfType:FIRDataEventTypeValue withBlock:^(FIRDataSnapshot * _Nonnull snapshot) {
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
                                for(id key in objectList) {
                                    NSDictionary * value = [objectList objectForKey:key];
                                    
                                    NSString *anchor = value[@"anchorID"];
                                    NSString *resource = value[@"resourceID"];
                                    NSNumber *type = value[@"type"];
                                    
                                    id arObj = [[ARObject alloc] initWithID:anchor resource:resource type:(int)type];
                                    if (arObj) {
                                        [room addARObject:arObj];
                                    }
                                    NSLog(@"%@, %@", anchor, type);
                                }
                            }
                            self.room = room;
                            [self.lblStatus setText:@""];
                            [self performSegueWithIdentifier:@"segEdit" sender:nil];
                        }
                    }
                    else {
                        [self.lblStatus setText:@"Wrong password"];
                    }
                }
            }];
        }
        // Create new room
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
            
            [[[self.firebaseReference child:@"room_list"]
              child:roomName] setValue:room withCompletionBlock:^(NSError *error, FIRDatabaseReference *ref) {
                if (error) {
                    [self.lblStatus setText:@"Error on saving the room to room list"];
                } else {
                    [[self.firebaseReference child:@"room_names"] setValue:nameList withCompletionBlock:^(NSError *error, FIRDatabaseReference *ref) {
                        if (error) {
                            [self.lblStatus setText:@"Error on storing list of used name"];
                        } else {
                            id room = [[Room alloc] initWithName:roomName];
                            
                            self.room = room;
                           
                            [self.lblStatus setText:@""];
                            [self performSegueWithIdentifier:@"segEdit" sender:nil];
                        }
                    }];
                }
                
            }];
        }
        
    } withCancelBlock:^(NSError * _Nonnull error) {
        NSLog(@"%@", error.localizedDescription);
    }];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    if ([[segue identifier] isEqualToString:@"segEdit"]) {
        MainViewController *viewController = [segue destinationViewController];
        [viewController setRoom : self.room viewType:ViewTypeEdit];
    }
}

@end
