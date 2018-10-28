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
}

- (void)viewDidAppear:(BOOL)animated {
    switch (self.selectedType) {
        case ViewTypeEdit:
            self.txtRoomPassword.enabled = YES;
            break;
        case ViewTypeJoin:
            self.txtRoomPassword.enabled = NO;
            break;
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)btnEnter_pressed:(id)sender {
    [[self view] endEditing:YES];
    [self.lblStatus setText:@"Connecting..."];
    
    if ([self.txtRoomName.text isEqualToString:@""])
        [self.lblStatus setText:@"Please enter a name"];
    else {
        switch (self.selectedType) {
            case ViewTypeEdit:
                [self editRoom:self.txtRoomName.text and:self.txtRoomPassword.text];
                break;
            case ViewTypeJoin:
                [self joinRoom:self.txtRoomName.text];
                break;
        }
    }
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

- (void)editRoom:(NSString *)roomName and:(NSString *)password {
    [self.socket emit: @"editRoom" with: @[roomName, password]];
}

- (void)joinRoom:(NSString *)roomName {
    [self.socket emit: @"joinRoom" with: @[roomName]];
}

- (void)loadRoom:(NSDictionary *)data {
    [self.lblStatus setText:@"Loading Room..."];
    id room = [[Room alloc] initWithDictionary:data];
    self.room = room;
    
    if ([self.room.objectList count] <= 0) {
        [self performSegueWithIdentifier:@"segEnter" sender:nil];
    }
    else {
        self.loadingCount = 0;
        
        [self.lblStatus setText:[NSString stringWithFormat:@"Loading data... (0/%@)", @([self.room.objectList count])]];
        for (ARObject * arObj in self.room.objectList) {
            if ([self.storage.imageDictionary objectForKey:arObj.resourceID]) {
                self.loadingCount++;
                [self.lblStatus setText:[NSString stringWithFormat:@"Loading data... (%@/%@)", @(self.loadingCount) ,@([self.room.objectList count])]];
                
                if (self.loadingCount >= [self.room.objectList count]) {
                    // Loading complete
                    [self performSegueWithIdentifier:@"segEnter" sender:nil];
                }
            }
            else
                [self.socket emit: @"requestARResource" with: @[arObj.resourceID, @(arObj.type)]];
        }
    }
}

- (void) initialize:(SocketIOClient *)socket storage:(Storage *)storage view:(ViewType)type {
    if (!self.socket) {
        self.socket = socket;
        
        [self.socket on:@"connect" callback:^(NSArray* data, SocketAckEmitter* ack) {
            NSLog(@"socket connected");
        }];
        
        [self.socket on:@"wrongPassword" callback:^(NSArray* data, SocketAckEmitter* ack) {
            [self.lblStatus setText:@"Wrong password"];
            //NSLog(@"Room join approved");
        }];
        
        [self.socket on:@"roomDoesntExist" callback:^(NSArray* data, SocketAckEmitter* ack) {
            //NSLog(@"Room don't exist");
            [self.lblStatus setText:@"Room doesn't exist"];
        }];
        
        [self.socket on:@"roomData" callback:^(NSArray* data, SocketAckEmitter* ack) {
            [self.lblStatus setText:@"Received room data"];
            
            NSDictionary * dataDictionary = [data objectAtIndex:0];
            [self loadRoom:dataDictionary];
        }];
        
        [self.socket on:@"imageDataForARObject" callback:^(NSArray* data, SocketAckEmitter* ack) {
            NSData *dataEncoded = [[NSData alloc] initWithBase64EncodedString:[data objectAtIndex:1]  options:0];
            UIImage *image = [UIImage imageWithData:dataEncoded];
            
            NSString * identifier = [data objectAtIndex: 0];
            
            [self.storage.imageDictionary setObject:image forKey:identifier];
            
            self.loadingCount++;
            
            [self.lblStatus setText:[NSString stringWithFormat:@"Loading data... (%@/%@)", @(self.loadingCount) ,@([self.room.objectList count])]];
            
            if (self.loadingCount >= [self.room.objectList count]) {
                // Loading complete
                [self performSegueWithIdentifier:@"segEnter" sender:nil];
            }
        }];
    }
    
    if (!self.storage) {
        self.storage = storage;
    }
    
    self.selectedType = type;
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
    if ([[segue identifier] isEqualToString:@"segEnter"]) {
        [self.lblStatus setText:@""];
        NavigationViewController *viewController = [segue destinationViewController];
        [viewController initialize:self.room viewType:self.selectedType socket:self.socket storage:self.storage];
    }
}

@end
