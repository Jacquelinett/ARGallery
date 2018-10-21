//
//  ARMenuViewController.h
//  ARtGallery
//
//  Created by Jacqueline on 7/31/18.
//

#import <UIKit/UIKit.h>
#import "ARCollectionViewController.h"

@interface ARMenuViewController : UIViewController

@property (weak, nonatomic) ARCollectionViewController * parent;
@property(strong, nonatomic) SocketIOClient* socket;

@property (weak, nonatomic) ARObject *controlling;

@property (weak, nonatomic) IBOutlet UIButton *btnDelete;
@property (weak, nonatomic) IBOutlet UIButton *btnReplace;
@property (weak, nonatomic) IBOutlet UIButton *btnBack;

- (IBAction)btnDelete_pressed:(id)sender;
- (IBAction)btnBack_pressed:(id)sender;
- (IBAction)btnReplace_pressed:(id)sender;

- (void) initialize: (ARCollectionViewController *) parent : (SocketIOClient*)socket : (ARObject *) controlling;

@end
