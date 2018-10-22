//
//  ARMenuViewController.m
//  ARtGallery
//
//  Created by Jacqueline on 7/31/18.
//

#import "ARMenuViewController.h"

@interface ARMenuViewController ()

@end

@implementation ARMenuViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Navigation

/*
// In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
     if ([[segue identifier] isEqualToString:@"segBack"]) {
         ARCollectionViewController *viewController = [segue destinationViewController];
         [viewController initialize:self.room viewType:ViewTypeJoin :self.socket];
     }
 }*/

- (IBAction)btnDelete_pressed:(id)sender {
    [_socket emit: @"removeARObject" with: @[self.controlling.anchorID]];

}

- (IBAction)btnBack_pressed:(id)sender {
    [self dismissViewControllerAnimated:YES completion:^{}];
}

- (IBAction)btnReplace_pressed:(id)sender {
    //[_socket emit: @"addARObject" with: @[anchor.cloudIdentifier, base64String, @(_imgFrame.size.width), @(_imgFrame.size.height), @0]];

}

- (void) initialize:(ARCollectionViewController *)parent object:(ARObject *)controlling {
    _controlling = controlling;
    if (!_parent) {
        _parent = parent;
    }
    if (!_socket) {
        _socket = _parent.socket;
        
        [_socket on:@"ARObjectRemovedSuccessful" callback:^(NSArray* data, SocketAckEmitter* ack) {
            //NSLog(@"Room don't exist");
            //[self.lblStatus setText:@"Room doesn't exist"];
            [self.parent removeARObject:controlling];
            [self dismissViewControllerAnimated:YES completion:^{}];
        }];
        
        
    }
}
@end
