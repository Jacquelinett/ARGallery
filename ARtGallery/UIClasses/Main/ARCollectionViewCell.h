//
//  ARCollectionViewCell.h
//  ARtGallery
//
//  Created by Jacqueline on 7/19/18.
//

#import <UIKit/UIKit.h>

@class ARCollectionViewCell;

@interface ARCollectionViewCell : UICollectionViewCell

@property (strong, nonatomic) IBOutlet UIImageView *imageView;
@property (strong, nonatomic) IBOutlet UIButton *btnView;

@end
