//
//  MoviesViewController.m
//  HEVDecoder
//
//  Created by Shengbin Meng on 13-2-25.
//  Copyright (c) 2013 Peking University. All rights reserved.
//

#import "MoviesViewController.h"
//#import "PlayViewController.h"
//#import "SettingsViewController.h"
//#import "TestDecoderViewController.h"

@interface MoviesViewController (){
    NSString * _suffix;
}

@end

@implementation MoviesViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
        self.title = @"Movies";
    }
    _tableBlock = nil;
    return self;
}

-(id)initWithSuffix:(NSString *)suffix
{
    self = [super init];
    _suffix = suffix;
    return self;
}

-(id)init{
    self = [super init];
    _suffix = @"";
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if ([self.tableView respondsToSelector:@selector(registerClass:forCellReuseIdentifier:)]) {
        // this is iOS 6.0 above
        [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"Cell"];
    }
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(backAction)];
}

- (void)backAction{
    [self dismissViewControllerAnimated:FALSE completion:nil];
}

- (void) viewWillAppear:(BOOL)animated
{
    self.movieList = [[NSMutableArray alloc] init];
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSFileManager *manager = [NSFileManager defaultManager];
    NSArray *fileList = [manager contentsOfDirectoryAtPath:documentsDirectory error:nil];
    for (NSString *filename in fileList){
        if([filename hasSuffix:_suffix]){
            NSMutableDictionary *movie = [[NSMutableDictionary alloc] init];
            [movie setObject:filename forKey:@"Filename"];
            [movie setObject:[documentsDirectory stringByAppendingString:[@"/" stringByAppendingString:filename]] forKey:@"Path"];
            [self.movieList addObject:movie];
        }
    }
    
    [self.tableView reloadData];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return self.movieList.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell;
    if ([tableView respondsToSelector:@selector(dequeueReusableCellWithIdentifier:forIndexPath:)]) {
        cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    } else {
        cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        }

    }

    
    // Configure the cell...
    NSUInteger row = [indexPath row];
    NSDictionary *movie = [self.movieList objectAtIndex:row];
    cell.textLabel.text = [movie objectForKey:@"Filename"];
    
    return cell;
}

// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        int index = [indexPath row];
        NSFileManager *manager = [NSFileManager defaultManager];
        [manager removeItemAtPath:[[self.movieList objectAtIndex:index] valueForKey:@"Path"] error:nil];
        [self.movieList removeObjectAtIndex:index];
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)  tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger row = [indexPath row];
    NSDictionary *movie = [self.movieList objectAtIndex:row];
    [[NSUserDefaults standardUserDefaults] setValue:[movie objectForKey:@"Path"] forKey:@"videoPath"];
    NSString * path = [movie objectForKey:@"Filename"];
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    [self dismissViewControllerAnimated:FALSE completion:nil];
    if (_tableBlock){
        _tableBlock(path);
    }
}

@end
