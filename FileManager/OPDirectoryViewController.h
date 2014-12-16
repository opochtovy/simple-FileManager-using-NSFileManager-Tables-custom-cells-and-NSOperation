//
//  OPDirectoryViewController.h
//  FileManager
//
//  Created by Oleg Pochtovy on 27.11.14.
//  Copyright (c) 2014 Oleg Pochtovy. All rights reserved.
//

#import <UIKit/UIKit.h>

// create a block type
@class OPFolderCell;
typedef void(^ResultFolderSize)(OPFolderCell *);

@interface OPDirectoryViewController : UITableViewController <UITextFieldDelegate>

@end
