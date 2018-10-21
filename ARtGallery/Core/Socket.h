//
//  Socket.h
//  ARtGallery
//
//  Created by Jacqueline on 7/23/18.
//

#import <Foundation/Foundation.h>
#import "NavigationViewController.h"
#import "JoinViewController.h"
#import "LoginViewController.h"

@import SocketIO;

@interface Socket : NSObject

@property(assign, nonatomic) NavigationViewController * navigationView;
@property(assign, nonatomic) JoinViewController * joinView;
@property(assign, nonatomic) LoginViewController * loginView;

@property(assign, nonatomic) SocketIOClient* socket;

+ (Socket *) instance;
- (void) start;
- (instancetype) init;

- (void) sendJoinRoom : (NSString *) name;
- (void) sendEditRoom : (NSString *) name : (NSString *) password;
- (void) sendDeleteRoom : (NSString *) name;
- (void) sendRenameRoom : (NSString *) oldName : (NSString *) newName;
@end
