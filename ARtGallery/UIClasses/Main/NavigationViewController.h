//
//  NavigationViewController.h
//  ARtGallery
//
//  Created by Jacqueline on 6/19/18.
//

#import <UIKit/UIKit.h>
#import <FirebaseDatabase/FirebaseDatabase.h>

#import "MainViewController.h"
#import "MenuViewController.h"
#import "ARCollectionViewController.h"
#import "Room.h"
#import "Storage.h"
#import "ViewTypeEnum.h"

@import SocketIO;

@class MainViewController;
@class MenuViewController;

@interface NavigationViewController : UITabBarController <UITabBarControllerDelegate>

@property (strong, nonatomic) SocketIOClient *socket;
@property (strong, nonatomic) Storage *storage;

@property (strong, nonatomic) Room *room;
@property (assign, nonatomic) ViewType viewType;
@property (assign, nonatomic) MainViewController *mainView;
@property (assign, nonatomic) MenuViewController *menuView;

- (void)initialize:(Room *)room viewType:(ViewType)type socket:(SocketIOClient*)socket storage:(Storage *)storage;

@end
