//
//  ARCollectionViewController.h
//  ARtGallery
//
//  Created by Jacqueline on 7/16/18.
//

#import <UIKit/UIKit.h>
#import "MainViewController.h"
#import "ARCollectionViewCell.h"
#import "ARObject.h"

@class ARMenuViewController;

@import SocketIO;

@interface ARCollectionViewController : UICollectionViewController <UIImagePickerControllerDelegate, UINavigationControllerDelegate>

@property(strong, nonatomic) SocketIOClient* socket;

@property(nonatomic, strong) NSMutableArray *objectList;
@property(nonatomic, strong) NSDictionary *resourceDictionary;

@property(nonatomic, assign) int lastSelectedIndex;

- (void) initialize:(NSMutableArray *) objectList : (NSMutableDictionary *) resourceDictionary : (SocketIOClient *) socket;
- (void) removeARObject : (ARObject *) removed;

@end
