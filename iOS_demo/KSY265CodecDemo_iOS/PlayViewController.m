//
//  PlayViewController.m
//  HEVDecoder
//
//  Created by Shengbin Meng on 13-2-25.
//  Copyright (c) 2013 Peking University. All rights reserved.
//

#import "PlayViewController.h"
#import "GLView.h"

@implementation PlayViewController

{
    bool isPlaying;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void) monitorPlaybackTime
{
    if (!isPlaying) {
        return;
    }

    [self.infoLabel setText:self.player.infoString];
    [self performSelector:@selector(monitorPlaybackTime) withObject:nil afterDelay:1.0];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    NSString *decoder = [[NSUserDefaults standardUserDefaults] valueForKey:@"codec"];
    // Do any additional setup after loading the view from its nib.
    if (self.player == nil) {
        if ([decoder isEqualToString:@"lenthevcdec"]) {
            self.player = [[MoviePlayer alloc] init];
            self.player.infoString = @"lenthevc decoding";
        }
        else {
            self.player = [[KSYMoviePlayer alloc] init];
            self.player.infoString = @"ksc265 decoding";
        }
    }
    
    NSString * path = [[NSUserDefaults standardUserDefaults] valueForKey:@"videoPath"];
    int ret = [self.player openMovie:path];
    if(ret != 0) {
        UIAlertView * alert = [[UIAlertView alloc] initWithTitle:@"Message" message:@"Get movie data failed! Please check your source or try again." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
        return ;
    } else {
        self.player.renderer = ((GLView*)self.view).renderer;
        [self.player setOutputViews:nil:self.infoLabel];

        int ret = [self.player play];
        if(ret != 0) {
            UIAlertView * alert = [[UIAlertView alloc] initWithTitle:@"Message" message:@"Can't play this movie! Please check its format." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [alert show];
            return ;
        }
        isPlaying = YES;
        [self monitorPlaybackTime];
    }
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [[self.navigationController navigationBar] setHidden:YES];
}

- (void) viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [[self.navigationController navigationBar] setHidden:NO];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskLandscapeRight;
}

-(BOOL)shouldAutorotate
{
    return YES;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation
{
    return UIInterfaceOrientationLandscapeRight;
}


- (IBAction)doneButtonPressed:(id)sender
{
    isPlaying = NO;
    [self.player stop];
    [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
    [self.navigationController popViewControllerAnimated:YES];
}

@end
