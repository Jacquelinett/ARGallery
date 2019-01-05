//
//  GreetViewController.m
//  ARtGallery
//
//  Created by Jacqueline on 6/15/18.
//

#import "GreetViewController.h"

@interface GreetViewController ()

@end

@implementation GreetViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.storage = [[Storage alloc] initDefault];
    
    NSURL* url = [[NSURL alloc] initWithString:@"http://130.203.82.238:8900"];
    self.manager = [[SocketManager alloc] initWithSocketURL:url config:@{@"log": @YES, @"compress": @YES}];
    self.socket = self.manager.defaultSocket;                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        
    [self.socket connect];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    if ([[segue identifier] isEqualToString:@"segLogin"]) {
        LoginViewController *viewController = [segue destinationViewController];
        [viewController initialize:self.socket storage:self.storage view:self.selectedType];
    }
}


- (IBAction)btnJoin_pressed:(id)sender {
    self.selectedType = ViewTypeJoin;
    [self performSegueWithIdentifier:@"segLogin" sender:nil];
}

- (IBAction)btnEdit_pressed:(id)sender {
    self.selectedType = ViewTypeEdit;
    [self performSegueWithIdentifier:@"segLogin" sender:nil];
}
@end
