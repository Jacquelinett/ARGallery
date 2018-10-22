//
//  ARCollectionViewController.h
//  ARtGallery
//
//  Created by Jacqueline on 7/16/18.
//

#import <UIKit/UIKit.h>
#import "MainViewController.h"
#import "ARCollectionViewCell.h"
#import "NavigationViewController.h"
#import "ARObject.h"
#import "Storage.h"

@class ARMenuViewController;
@class NavigationViewController;

@import SocketIO;

@interface ARCollectionViewController : UICollectionViewController <UIImagePickerControllerDelegate, UINavigationControllerDelegate>

@property (strong, nonatomic) SocketIOClient *socket;
@property (strong, nonatomic) Storage *storage;
@property (strong, nonatomic) NavigationViewController* parent;

@property (assign, nonatomic) int lastSelectedIndex;

- (void) initialize;
- (void) removeARObject:(ARObject *)removed;

@end
