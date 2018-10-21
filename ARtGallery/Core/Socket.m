//
//  Socket.m
//  ARtGallery
//
//  Created by Jacqueline on 7/23/18.
//

#import "Socket.h"

@implementation Socket

+ (Socket *)instance {
    static Socket *sharedInstance = nil;
    
    if (sharedInstance == nil) {
        sharedInstance = [[Socket alloc] init];
    }
    
    return sharedInstance;
}

- (void) start {
    NSURL* url = [[NSURL alloc] initWithString:@"http://localhost:8900"];
    SocketManager* manager = [[SocketManager alloc] initWithSocketURL:url config:@{@"log": @YES, @"compress": @YES}];
    _socket = manager.defaultSocket;
    
    [_socket on:@"connect" callback:^(NSArray* data, SocketAckEmitter* ack) {
        NSLog(@"socket connected");
    }];
    
    [_socket onAny: ^(SocketAnyEvent* e) {
        NSLog(@"%@", e.event);
        NSLog(@"%@", e.items);
    }];
    
    [_socket connect];
}

- (instancetype) init{
    self = [super init];
    if (self) {
        
    }
    return self;
}

- (void) sendJoinRoom : (NSString *) name {
    
}

- (void) sendEditRoom : (NSString *) name : (NSString *) password {
    
}
- (void) sendDeleteRoom : (NSString *) name {
    
}
- (void) sendRenameRoom : (NSString *) oldName : (NSString *) newName {
    
}


@end
