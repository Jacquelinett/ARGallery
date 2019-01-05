//
//  ARCollectionViewController.m
//  ARtGallery
//
//  Created by Jacqueline on 7/16/18.
//

#import <MobileCoreServices/MobileCoreServices.h>

#import "ARCollectionViewController.h"
#import "ARMenuViewController.h"

@interface ARCollectionViewController ()

@end

@implementation ARCollectionViewController

static NSString * const reuseIdentifier = @"Cell";

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.parent = (NavigationViewController *)self.tabBarController;
    
    // Uncomment the following line to preserve selection between presentations
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Register cell classes
    [self.collectionView registerClass:[ARCollectionViewCell class] forCellWithReuseIdentifier:reuseIdentifier];
    
    // Do any additional setup after loading the view.
    
}

- (void)viewDidAppear:(BOOL)animated {
    [self.collectionView reloadData];
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
    
    if ([[segue identifier] isEqualToString:@"segOption"]) {
        ARMenuViewController *viewController = [segue destinationViewController];
        [viewController initialize:self object:[self.parent.room.objectList objectAtIndex: _lastSelectedIndex ]];
    }
}


- (ARObject *) getARObjectFromIndexPath : (NSIndexPath *)indexPath {
    return self.parent.room.objectList[indexPath.row];
}

#pragma mark <UICollectionViewDataSource>

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1; // We only have 1 section ever, liek Pokemon Go pokemon lists!
}


- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.parent.room.objectList.count + 1;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    ARCollectionViewCell *cell = (ARCollectionViewCell *) [collectionView dequeueReusableCellWithReuseIdentifier:reuseIdentifier forIndexPath:indexPath];
    
    // Configure the cell
    if (indexPath.row == 0) {
        //cell.backgroundColor = UIColor.blackColor;
        cell.imageView.image = [UIImage imageNamed: @"icons8-add-new-50"];
    }
    else {
        //cell.backgroundColor = UIColor.yellowColor;
        //cell.imageView.image = [UIImage imageNamed: @"Elon_Musk_2015"];
        ARObject * o = [self.parent.room.objectList objectAtIndex:(indexPath.row - 1)];
        if (o.type == ResourceTypeImage) {
            cell.imageView.image = self.parent.storage.imageDictionary[o.resourceID];
        }
        else if (o.type == ResourceTypeVideo){
            NSURL *videoURL = self.parent.storage.videoDictionary[o.resourceID];
            AVURLAsset *asset1 = [[AVURLAsset alloc] initWithURL:videoURL options:nil];
            AVAssetImageGenerator *generate1 = [[AVAssetImageGenerator alloc] initWithAsset:asset1];
            generate1.appliesPreferredTrackTransform = YES;
            CMTime time = CMTimeMake(1, 2);
            CGImageRef oneRef = [generate1 copyCGImageAtTime:time actualTime:NULL error:nil];
            cell.imageView.image = [[UIImage alloc] initWithCGImage:oneRef]; }
    }
    
    return cell;
}

-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == 0) {
        UIImagePickerController * imagePicker = [[UIImagePickerController alloc] init];
        imagePicker.delegate = self;
        imagePicker.allowsEditing = YES;
        imagePicker.mediaTypes = [UIImagePickerController availableMediaTypesForSourceType:
                                  UIImagePickerControllerSourceTypeCamera];
        
        UIAlertController *alertController =
        [UIAlertController alertControllerWithTitle:@"Media Source"
                                            message:@"Choose a source"
                                     preferredStyle:UIAlertControllerStyleActionSheet];
        UIAlertAction *cameraAction = [UIAlertAction actionWithTitle:@"Camera" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            imagePicker.sourceType = UIImagePickerControllerSourceTypeCamera;
            [self presentViewController:imagePicker animated:YES completion:NULL];
        }];
        
        UIAlertAction *libraryAction = [UIAlertAction actionWithTitle:@"Media Library" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
            [self presentViewController:imagePicker animated:YES completion:NULL];
        }];

        [alertController addAction:cameraAction];
        [alertController addAction:libraryAction];
        
        alertController.popoverPresentationController.sourceView = self.view;
        alertController.popoverPresentationController.sourceRect = CGRectMake(self.view.bounds.size.width / 2.0, self.view.bounds.size.height / 2.0, 1.0, 1.0);
        
        [self presentViewController:alertController animated:NO completion:^{}];
    } else {
        _lastSelectedIndex = (int)indexPath.row - 1;
        
        [self performSegueWithIdentifier:@"segOption" sender:nil];
    }
    NSLog(@"%ld", (long)indexPath.row);
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    [picker dismissViewControllerAnimated:YES completion:NULL];
    
    self.tabBarController.selectedIndex = 0;
    MainViewController * view = [self.tabBarController.viewControllers objectAtIndex:0];
    
    if([info[UIImagePickerControllerMediaType] isEqualToString:(__bridge NSString *)(kUTTypeImage)]) {
        [view addImage:info[UIImagePickerControllerEditedImage]];
    }
    else {
        [view addVideo:info[UIImagePickerControllerMediaURL]];
    }
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    
    [picker dismissViewControllerAnimated:YES completion:NULL];
    
}

#pragma mark <UICollectionViewDelegate>


// Uncomment this method to specify if the specified item should be highlighted during tracking
- (BOOL)collectionView:(UICollectionView *)collectionView shouldHighlightItemAtIndexPath:(NSIndexPath *)indexPath {
	return YES;
}



// Uncomment this method to specify if the specified item should be selected
- (BOOL)collectionView:(UICollectionView *)collectionView shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}


/*
// Uncomment these methods to specify if an action menu should be displayed for the specified item, and react to actions performed on the item
- (BOOL)collectionView:(UICollectionView *)collectionView shouldShowMenuForItemAtIndexPath:(NSIndexPath *)indexPath {
	return NO;
}

- (BOOL)collectionView:(UICollectionView *)collectionView canPerformAction:(SEL)action forItemAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender {
	return NO;
}

- (void)collectionView:(UICollectionView *)collectionView performAction:(SEL)action forItemAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender {
	
}
*/

- (void) initialize{
    [self.collectionView reloadData];
    
    if (!self.socket) {
        self.socket = self.parent.socket;
    }
}

- (void) removeARObject : (ARObject *) removed {
    MainViewController * view = [self.tabBarController.viewControllers objectAtIndex:0];
    [view removeARObject:removed.anchorID];
    [self.parent.room.objectList removeObject:removed];
    
    [self.collectionView reloadData];
}

@end
