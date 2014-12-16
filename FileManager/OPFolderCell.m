//
//  OPFolderCell.m
//  FileManager
//
//  Created by Oleg Pochtovy on 06.12.14.
//  Copyright (c) 2014 Oleg Pochtovy. All rights reserved.
//

#import "OPFolderCell.h"

@interface OPFolderCell() {
    __weak id _weakSelf;
}

@end

@implementation OPFolderCell

- (void)awakeFromNib {
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
    
    // Configure the view for the selected state
}

// here we create an instance of NSOperation (create private class method, that returns static (only one to all instances of OPFolderCell class) NSOperationQueue, which is initialized after first invocation of this method -> all OPFolderCell class cells must run their proccesses in that NSOperationQueue and all blocks are running together
+ (NSOperationQueue *)sharedOperationQueue {
    
    static NSOperationQueue *operationQueue;
    
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        operationQueue = [[NSOperationQueue alloc] init];
    });
    
    return operationQueue;
}

- (void)countFolderSizeWithBlock:(ResultFolderSize)result {
    
    self.currentFolderDeep = 1;
    self.indexesArray = [[NSMutableArray alloc] initWithObjects:[NSNumber numberWithInteger:0], nil];
    self.pathsArray = [[NSMutableArray alloc] initWithObjects:self.path, nil];
    self.folderSize = 0;
    _weakSelf = self;
    
    self.allInnerFolderSizes = [NSMutableDictionary dictionary];
    
    [[OPFolderCell sharedOperationQueue] addOperationWithBlock:^{
        
        while (self.currentFolderDeep) {
            [self countFolderSize];
        }
        
        result(_weakSelf);
    }];
    
}

// recursive method
- (void)countFolderSize {
    
    NSString *path = [self.pathsArray lastObject];
    
    NSInteger currentIndex = [[self.indexesArray lastObject] integerValue];
    
    NSError *error;
    
    NSArray *contents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:path error:&error];
    
    if (error) {
        
        NSLog(@"%@", [error localizedDescription]);
    }
    
    if (currentIndex < [contents count]) {
        
        NSString *fileName = [contents objectAtIndex:currentIndex];
        
        [self.indexesArray replaceObjectAtIndex:([self.indexesArray count] - 1) withObject:[NSNumber numberWithInteger:++currentIndex]];
        
        path = [path stringByAppendingPathComponent:fileName];
        
        BOOL isDirectory = NO;
        
        // next we check that object whether it's folder or file
        [[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDirectory];
        
        if (isDirectory) {
            
            ++self.currentFolderDeep;
            [self.indexesArray addObject:[NSNumber numberWithInteger:0]];
            [self.pathsArray addObject:path];
            
        } else {
            
            NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:path error:nil];
            
            self.folderSize += [attributes fileSize];
            NSLog(@"self.folderSize ::: %llu", self.folderSize);
        }
        
        
    } else { // for case when currentIndex == [contents count] -> welling up in our folder tree (hierarchy) for 1 level above
        
        unsigned long long folderSize = 0;
        for (NSString *fileName in contents) {
            
            // check our current element whether it's folder or file, if it's folder then we take already saved value from our dictionary self.allInnerFolderSizes using the path (path+fileName)
            path = [path stringByAppendingPathComponent:fileName];
            
            BOOL isDirectory = NO;
            
            // next we check that object whether it's folder or file
            [[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDirectory];
            
            unsigned long long currentFolderSize = 0;
            if (isDirectory) {
                
                NSNumber *currentFolderSizeNumber = [self.allInnerFolderSizes valueForKey:path];
                currentFolderSize = [currentFolderSizeNumber unsignedLongLongValue];
                folderSize += currentFolderSize;
                
            } else {
                
                NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:path error:nil];
                currentFolderSize = [attributes fileSize];
                folderSize += [attributes fileSize];
            }
            
        }
        
        NSNumber *folderSizeNumber = [NSNumber numberWithUnsignedLongLong:folderSize];
        [self.allInnerFolderSizes setObject:folderSizeNumber forKey:path];
        
        [self.indexesArray removeLastObject];
        [self.pathsArray removeLastObject];
        --self.currentFolderDeep;
        
    }
    
}

@end
