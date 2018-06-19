//
//  LoginViewController.h
//  ARtGallery
//
//  Created by Jacqueline on 6/15/18.
//

#import <UIKit/UIKit.h>
#import <FirebaseDatabase/FirebaseDatabase.h>
#import "MainViewController.h"
#import <RNCryptor-objc/RNEncryptor.h>

@interface LoginViewController : UIViewController <UITextFieldDelegate>

@property(nonatomic, strong) IBOutlet UITextField *txtRoomName;
@property(nonatomic, strong) IBOutlet UITextField *txtRoomPassword;
@property(nonatomic, strong) IBOutlet UIButton *btnEdit;
@property(nonatomic, strong) IBOutlet UILabel *lblStatus;
@property(nonatomic, strong) FIRDatabaseReference *firebaseReference;
@property(nonatomic, strong) NSString *staticSalt;
@property(nonatomic, strong) Room *room;

- (IBAction)btnEdit_pressed:(id)sender;

@end
