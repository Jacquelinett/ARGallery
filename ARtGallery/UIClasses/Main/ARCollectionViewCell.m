//
//  ARCollectionViewCell.m
//  ARtGallery
//
//  Created by Jacqueline on 7/19/18.
//

#import "ARCollectionViewCell.h"

@implementation ARCollectionViewCell

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        
        _imageView = [[UIImageView alloc] initWithFrame:self.contentView.bounds];
        [self.contentView addSubview:_imageView];
    }
    return self;
}

@end
