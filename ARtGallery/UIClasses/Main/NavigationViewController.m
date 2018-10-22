//
//  NavigationViewController.m
//  ARtGallery
//
//  Created by Jacqueline on 6/19/18.
//

#import "NavigationViewController.h"

@implementation NavigationViewController

- (void)initialize:(Room *)room viewType:(ViewType)type socket:(SocketIOClient*)socket storage:(Storage *)storage {
    
    self.room = room;
    self.viewType = type;
    
    self.menuView = (MenuViewController *)[self.viewControllers objectAtIndex:2];
    
    switch(type) {
        case ViewTypeEdit:
            self.tabBar.items[1].enabled = YES;
            self.menuView.btnDelete.enabled = YES;
            self.menuView.btnRename.enabled = YES;
            break;
        case ViewTypeJoin:
            self.tabBar.items[1].enabled = NO;
            self.menuView.btnDelete.enabled = NO;
            self.menuView.btnRename.enabled = NO;
            break;
    }
    
    if (!self.socket) {
        self.socket = socket;
    }
    
    if (!self.storage) {
        self.storage = storage;
    }
}

- (void)viewDidLoad {
    [self.viewControllers makeObjectsPerformSelector:@selector(view)];
    
    self.delegate = self;
    
    self.mainView = [self.viewControllers objectAtIndex:0];
    [self.mainView initialize];
}

- (void)tabBarController:(UITabBarController *)tabBarController
 didSelectViewController:(UIViewController *)viewController {
    if ([viewController isKindOfClass:[MainViewController class]]) {
        //MainViewController * main = (MainViewController *)viewController;
    }
    else if ([viewController isKindOfClass: [ARCollectionViewController class]] ) {
        ARCollectionViewController * collection = (ARCollectionViewController *)viewController;
        [collection initialize];
    }

}

@end
