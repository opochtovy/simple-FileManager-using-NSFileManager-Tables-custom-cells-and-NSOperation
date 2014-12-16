//
//  OPFileCell.h
//  FileManager
//
//  Created by Oleg Pochtovy on 29.11.14.
//  Copyright (c) 2014 Oleg Pochtovy. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OPFileCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (strong, nonatomic) IBOutlet UILabel *sizeLabel;

@end
