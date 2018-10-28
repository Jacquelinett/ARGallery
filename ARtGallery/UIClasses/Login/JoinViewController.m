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

- (IBAction)btnBack_pressed:(id)sender {
    [self dismissViewControllerAnimated:true completion:nil];
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

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
*/

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    if ([[segue identifier] isEqualToString:@"segSee"]) {
        NavigationViewController *viewController = [segue destinationViewController];
        [viewController initialize:self.room viewType:ViewTypeJoin :self.socket];
    }
}

@end
