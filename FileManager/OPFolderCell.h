//
//  OPFolderCell.h
//  FileManager
//
//  Created by Oleg Pochtovy on 06.12.14.
//  Copyright (c) 2014 Oleg Pochtovy. All rights reserved.
//

#import <UIKit/UIKit.h>

// create a block type
@class OPFolderCell;
typedef void(^ResultFolderSize)(OPFolderCell *);

@interface OPFolderCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (strong, nonatomic) IBOutlet UILabel *sizeLabel;

@property (assign, nonatomic) NSInteger currentFolderDeep; // indicates how many folders should we go inside folder to meet a file on first non-counted by us position of the most insider folder
@property (strong, nonatomic) NSMutableArray *indexesArray; // stores indexes of all folders regarding our currentFolderDeep to know what files and folders sizes we have already counted and what sizes haven't yet
@property (strong, nonatomic) NSMutableArray *pathsArray; // stores paths of all inner folders regarding our currentFolderDeep to get the content of each inner folder using method contentsOfDirectoryAtPath:
@property (assign, nonatomic) unsigned long long folderSize; // here we will store our final size of current folder

@property (strong, nonatomic) NSString *path;

@property (strong, nonatomic) NSMutableDictionary *allInnerFolderSizes; // this dictionary will contain the sizes of all folders (so the dimensions will be calculated once when the application starts and then during the transitions between folders the folder size will be taken from the dictionary)

+ (NSOperationQueue *)sharedOperationQueue;

- (void)countFolderSizeWithBlock:(ResultFolderSize)result;
- (void)countFolderSize;

@end
