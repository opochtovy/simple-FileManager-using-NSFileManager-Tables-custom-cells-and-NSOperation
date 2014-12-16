//
//  OPDirectoryViewController.m
//  FileManager
//
//  Created by Oleg Pochtovy on 27.11.14.
//  Copyright (c) 2014 Oleg Pochtovy. All rights reserved.
//

// 1 - Practicing with NSFileManager - the ability to create directories
// 2 - File Manager has the ability to delete files and directories
// 3 - Sorting of the files and folders: from the top should be folders, sorted by descending name, the files below, sorted by size
// 4 - Don't show hidden files
// 5 - In detailedTextField of each file's cell output the file size
// 6 - Recursively output the folder size using NSOperation in the background thread

#import "OPDirectoryViewController.h"
#import "OPAddDirectoryCell.h"
#import "OPFileCell.h"
#import "OPFolderCell.h"

@interface OPDirectoryViewController ()

@property (strong, nonatomic) NSString *path;
@property (strong, nonatomic) NSArray *contents;
@property (weak, nonatomic) UITextField *addDirectoryField;

@property (strong, nonatomic)  NSMutableArray *files;
@property (strong, nonatomic) NSMutableArray *folders;

@property (strong, nonatomic) NSMutableDictionary *allInnerFolderSizes; // this dictionary will contain the sizes of all folders (so the dimensions will be calculated once when the application starts and then during the transitions between folders the folder size will be taken from the dictionary)
@property (strong, nonatomic) NSMutableDictionary *allFoldersSizes;

@end

@implementation OPDirectoryViewController

#pragma mark - Loading

- (void)setPath:(NSString *)path {
    
    _path = path;
    
    NSError *error;
    
    self.contents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:self.path error:&error];
    
    if (error) {
        
        NSLog(@"%@", [error localizedDescription]);
    }
    
    [self.tableView reloadData];
    
    self.navigationItem.title = [self.path lastPathComponent];
    
    // here we divide the array into 2 - where the files and folders
    self.files = [NSMutableArray array];
    self.folders = [NSMutableArray array];
    
    // to don't show hidden files we should simply not include such files in an array of files during the formation of an array
    NSURL *pathURL = [NSURL fileURLWithPath:self.path];
    NSArray *nonHiddenArray = [[NSFileManager defaultManager] contentsOfDirectoryAtURL:pathURL
                                           includingPropertiesForKeys:[NSArray arrayWithObject:NSURLNameKey]
                                                              options:NSDirectoryEnumerationSkipsHiddenFiles
                                                                error:nil];
    
    for (int i = 0; i < [self.contents count]; i++) {
        
        NSString *fileName = [self.contents objectAtIndex:i];
        
        // now check each folder / file is included in nonHiddenArray (i.e. is not hidden)
        BOOL isHidden = YES;
        for (NSURL *url in nonHiddenArray) {
            if ([[url lastPathComponent] isEqualToString:fileName]) {
                isHidden = NO;
            }
        }
        if (!isHidden) {
            
            if ([self isDirectoryAtRow:i]) {
                [self.folders addObject:[self.contents objectAtIndex:i]];
            }
            else {
                [self.files addObject:[self.contents objectAtIndex:i]];
            }
        }
    }
    
    // sorting of the files and folders: from the top should be folders, sorted by descending name, the files below, sorted by size
    NSArray *sortedFoldersArray = [self.folders sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        
        if ([obj1 compare:obj2] == NSOrderedAscending) {
            return (NSComparisonResult)NSOrderedDescending;
        } else if ([obj1 compare:obj2] == NSOrderedDescending) {
            return (NSComparisonResult)NSOrderedAscending;
        } else {
            return (NSComparisonResult)NSOrderedSame;
        }
    }];
    self.folders = [sortedFoldersArray copy];
    
    NSArray *sortedFilesArray = [self.files sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        
        NSString *path1 = [self.path stringByAppendingPathComponent:obj1];
        NSDictionary *attributes1 = [[NSFileManager defaultManager] attributesOfItemAtPath:path1 error:nil];
        NSString *fileSizeString1 = [attributes1 valueForKey:@"NSFileSize"];
        
        NSString *path2 = [self.path stringByAppendingPathComponent:obj2];
        NSDictionary *attributes2 = [[NSFileManager defaultManager] attributesOfItemAtPath:path2 error:nil];
        NSString *fileSizeString2 = [attributes2 valueForKey:@"NSFileSize"];
        
        if ([fileSizeString1 compare:fileSizeString2] == NSOrderedAscending) {
            return (NSComparisonResult)NSOrderedAscending;
        } else if ([fileSizeString1 compare:fileSizeString2] == NSOrderedDescending) {
            return (NSComparisonResult)NSOrderedDescending;
        } else {
            return (NSComparisonResult)NSOrderedSame;
        }
    }];
    self.files = [sortedFilesArray copy];
    
}

- (void)loadView {
    
    [super loadView];
    
    self.tableView.allowsSelectionDuringEditing = NO; // allows you to select a cell
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if ([self.navigationController.viewControllers count] > 1) {
        
        UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithTitle:@"Back To Root"
                                                                 style:UIBarButtonItemStylePlain
                                                                target:self
                                                                action:@selector(actionBackToRoot:)];
        
        self.navigationItem.rightBarButtonItem = item;
    }
    
    // final initialization of path
    if (!self.path) {
#pragma        self.path = @"/Volumes/"; // !!!!! add here your file manager root folder
    }
    
    self.tableView.editing = NO; // once the application is booted, we can not edit the cell but when you click on the Edit button in the UINavigationBar we turn on editing
    
    // next, add the button to the right to edit table (in NavigationBar)
    UIBarButtonItem *editButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit target:self action:@selector(actionEdit:)];
    self.navigationItem.rightBarButtonItem = editButton;
    
    if (!self.allFoldersSizes) {
        self.allFoldersSizes = [NSMutableDictionary dictionary];
    }
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Actions

- (void)actionEdit:(UIBarButtonItem *)sender {
    
    // when you click on the Edit button we go into edit mode of the table while the button is named Done
    BOOL isEditing = self.tableView.editing;
    
    // animation mode of button pressing
    [self.tableView setEditing:!isEditing animated:YES];
    
    // we have to create a new button cause we can't change its title
    UIBarButtonSystemItem item = UIBarButtonSystemItemEdit;
    
    if (self.tableView.editing) {
        item = UIBarButtonSystemItemDone;
    }
    
    UIBarButtonItem *editButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:item target:self action:@selector(actionEdit:)];
    
    [self.navigationItem setRightBarButtonItem:editButton animated:YES];
    
}

#pragma mark - Private Methods

- (BOOL)isDirectoryAtRow:(NSInteger)row {
    
    NSString *fileName = [self.contents objectAtIndex:row];
    
    NSString *filePath = [self.path stringByAppendingPathComponent:fileName];
    
    BOOL isDirectory = NO;
    
    [[NSFileManager defaultManager] fileExistsAtPath:filePath isDirectory:&isDirectory];
    
    return isDirectory;
}

- (void)actionBackToRoot:(UIBarButtonItem *)sender {
    
    [self.navigationController popToRootViewControllerAnimated:YES];
    
}

// file size looks not quite as easy to read - next we give it a more elegant looking
- (NSString *)fileSizeFromValue:(unsigned long long)size {
    
    static NSString *units[] = {@"B", @"KB", @"MB", @"GB", @"TB"};
    static int unitsCount = 5;
    
    int index = 0;
    
    double fileSize = (double)size;
    
    while (fileSize > 1024 && index < unitsCount) {
        fileSize /= 1024;
        index++;
    }
    
    return [NSString stringWithFormat:@"%.2f %@", fileSize, units[index]];
    
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    
    return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    if (section == 0) {
        
        return 1;
        
    } else if (section == 1) {
        
        return [self.folders count];
        
    } else {
        
        return [self.files count];
        
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *addDirectoryIdentifier = @"AddDirectoryCell";
    static NSString *folderIdentifier = @"FolderCell";
    static NSString *fileIdentifier = @"FileCell";
    
    if (indexPath.section == 0) {
        
        OPAddDirectoryCell *cell = [tableView dequeueReusableCellWithIdentifier:addDirectoryIdentifier];
        
        // add a functionality to enter a name for a new folder by pressing the button "Tap to Add New Directory"
        self.addDirectoryField = cell.addDirectoryField;
        self.addDirectoryField.keyboardAppearance = UIKeyboardAppearanceDark;
        self.addDirectoryField.delegate = self;
        
        return cell;
        
    } else if (indexPath.section == 1) {
        
        NSString *folderName = [self.folders objectAtIndex:indexPath.row];
        NSString *path = [self.path stringByAppendingPathComponent:folderName];
        
        OPFolderCell *cell = [tableView dequeueReusableCellWithIdentifier:folderIdentifier];
        cell.path = path;
        
        cell.nameLabel.text = folderName;
        cell.sizeLabel.text = @"";
        
        // use NSOperation
        
        // block initialization
        ResultFolderSize resultFolderSize = ^(OPFolderCell *cell) {
            dispatch_async(dispatch_get_main_queue(), ^{
                cell.sizeLabel.text = [self fileSizeFromValue:cell.folderSize];
                self.allInnerFolderSizes = [NSMutableDictionary dictionaryWithDictionary:cell.allInnerFolderSizes];
                [self.allFoldersSizes addEntriesFromDictionary:self.allInnerFolderSizes];
            });
        };
        
        NSNumber *folderSizeNumber = [self.allFoldersSizes valueForKey:path];
        if (folderSizeNumber) {
            
            cell.sizeLabel.text = [self fileSizeFromValue:[folderSizeNumber unsignedLongLongValue]];
            
        } else {
            
            // next we call a method which uses our block type as a parameter
            [cell countFolderSizeWithBlock:(ResultFolderSize)resultFolderSize];
            
        }
        
        return cell;
        
    } else {
        
        NSString *fileName = [self.files objectAtIndex:indexPath.row];
        
        NSString *path = [self.path stringByAppendingPathComponent:fileName];
        
        OPFileCell *cell = [tableView dequeueReusableCellWithIdentifier:fileIdentifier];
        
        NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:path error:nil];
        
        cell.nameLabel.text = fileName;
        
        cell.sizeLabel.text = [self fileSizeFromValue:[attributes fileSize]];
        return cell;
        
    }
}

-(BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    
    return NO;
}

// finish handling code when you press the delete confirmation of the student group Remove
-(void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        
        NSError *error;
        
        NSString *fileName;
        if (indexPath.section == 1) {
            fileName = [self.folders objectAtIndex:indexPath.row];
        } else {
            fileName = [self.files objectAtIndex:indexPath.row];
        }
        NSString *pathToDelete = [self.path stringByAppendingPathComponent:fileName];
        
        BOOL isFileDeleted = [[NSFileManager defaultManager] removeItemAtPath:pathToDelete error:&error];
        
        NSLog(@"isFileDeleted %i", isFileDeleted);
        
        if (isFileDeleted) {
            
            self.contents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:self.path error:&error];
            
            // it is necessary to rewrite arrays self.folders and self.files
            self.files = [NSMutableArray array];
            self.folders = [NSMutableArray array];
            for (int i = 0; i < [self.contents count]; i++) {
                
                if ([self isDirectoryAtRow:i]) {
                    [self.folders addObject:[self.contents objectAtIndex:i]];
                } else {
                    [self.files addObject:[self.contents objectAtIndex:i]];
                }
                
            }
            
        }
        
         [tableView beginUpdates];
         
         [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationLeft];
         
         [tableView endUpdates];
        
    }
}

#pragma mark - UITableViewDelegate

// since we changed the height for file cell in the storyboard we have to account that in the code
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (indexPath.section == 2) { // these are files
        
        return 60.f;
        
    } else {
        
        return 44.f;
        
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    if (indexPath.section == 0) {
        
        NSError *error;
        
        NSString *newPath = [self.path stringByAppendingPathComponent:@"new"];
        
        BOOL isNewDirectoryCreated = [[NSFileManager defaultManager] createDirectoryAtPath:newPath withIntermediateDirectories:nil attributes:nil error:&error];
        
        NSLog(@"%i", isNewDirectoryCreated);
        
        if (isNewDirectoryCreated) {
            
            self.contents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:self.path error:&error];
            [tableView reloadData];
        }
    } else if (indexPath.section == 1) {
        
        NSString *folderName = [self.folders objectAtIndex:indexPath.row];
        
        NSString *path = [self.path stringByAppendingPathComponent:folderName];
        
        OPDirectoryViewController *vc = [self.storyboard instantiateViewControllerWithIdentifier:@"OPDirectoryViewController"];
        vc.path = path;
        
        // it is necessary to init all folders sizes dictionary to the new VC
        vc.allFoldersSizes = [NSMutableDictionary dictionaryWithDictionary:self.allFoldersSizes];
        
        [self.navigationController pushViewController:vc animated:YES];
    }
    
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    return indexPath.section == 0 ? UITableViewCellEditingStyleNone : UITableViewCellEditingStyleDelete;
    
}

- (NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    return @"Remove";
}

- (BOOL)tableView:(UITableView *)tableView shouldIndentWhileEditingRowAtIndexPath:(NSIndexPath *)indexPath {
    
    return NO;
}

#pragma mark - UITextFieldDelegate

// ban to create a new folder when in edit mode
- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
    
    return !self.tableView.editing;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    
    [textField resignFirstResponder]; // here we remove the focus from this active element
    
    NSError *error;
    
    NSString *folderName = self.addDirectoryField.text;
    NSString *newPath = [self.path stringByAppendingPathComponent:folderName];
    
    BOOL isNewDirectoryCreated = [[NSFileManager defaultManager] createDirectoryAtPath:newPath withIntermediateDirectories:nil attributes:nil error:&error];
    
    NSLog(@"isNewDirectoryCreated %i", isNewDirectoryCreated);
    
    if (isNewDirectoryCreated) {
        
        self.contents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:self.path error:&error];
        
        // it is necessary to rewrite array self.folders
        self.folders = [NSMutableArray array];
        for (int i = 0; i < [self.contents count]; i++) {
            
            if ([self isDirectoryAtRow:i]) {
                [self.folders addObject:[self.contents objectAtIndex:i]];
            }
            
        }
        
        [self.tableView reloadData];
    }
    
    self.addDirectoryField.text = @"Tap to Add New Directory";
    
    return YES;
}

@end
