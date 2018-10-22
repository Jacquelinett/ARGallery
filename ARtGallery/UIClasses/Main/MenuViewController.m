//
//  MenuViewController.m
//  ARtGallery
//
//  Created by Jacqueline on 6/19/18.
//

#import "MenuViewController.h"

@interface MenuViewController ()

@end

@implementation MenuViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidAppear:(BOOL)animated {

}

- (void) initialize {
    if (!_socket) {
        [_socket on:@"roomWithNewNameAlreadyExist" callback:^(NSArray* data, SocketAckEmitter* ack) {
            [self.lblStatus setTextColor:UIColor.redColor];
            [self.lblStatus setText:@"Another room with same name already exist"];
        }];
        
        [_socket on:@"roomRenamed" callback:^(NSArray* data, SocketAckEmitter* ack) {
            [self.lblStatus setTextColor:UIColor.greenColor];
            [self.lblStatus setText:@"Room renamed successfully"];
        }];
        
        [_socket on:@"roomDeleted" callback:^(NSArray* data, SocketAckEmitter* ack) {
            [self.lblStatus setText:@""];
            [self performSegueWithIdentifier:@"segSee" sender:nil];
        }];
    }
}

- (IBAction)btnRename_pressed:(id)sender {
    [self roomNameDialog];
}

- (IBAction)btnDelete_pressed:(id)sender {
    [_socket emit: @"deleteRoom" with: @[@""]];
}

- (IBAction)btnLeave_pressed:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)roomNameDialog {
    UIAlertController *alertController =
    [UIAlertController alertControllerWithTitle:@"Enter new room name:"
                                        message:@""
                                 preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *okAction =
    [UIAlertAction actionWithTitle:@"OK"
                             style:UIAlertActionStyleDefault
                           handler:^(UIAlertAction *action) {
                               NSString *roomName = alertController.textFields[0].text;
                               if ([roomName length] > 0) {
                                   [self.socket emit: @"renameRoom" with: @[roomName]];
                               }
                           }];
    UIAlertAction *cancelAction =
    [UIAlertAction actionWithTitle:@"CANCEL"
                             style:UIAlertActionStyleDefault
                           handler:^(UIAlertAction *action) {}];
    [alertController addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.keyboardType = UIKeyboardTypeDefault;
    }];
    [alertController addAction:okAction];
    [alertController addAction:cancelAction];
    [self presentViewController:alertController animated:NO completion:^{}];
}



/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
