//
//  SecondViewController.m
//  KSY265CodecDemo_iOS
//
//  Created by 江东 on 17/3/17.
//  Copyright © 2017年 江东. All rights reserved.
//

#import "SecondViewController.h"
#import "SettingsDecoderViewController.h"
#import "DecoderHelperViewController.h"
#import "MoviesViewController.h"
#import "MoviePlayer.h"
#import "KSYMoviePlayer.h"
#import "GLView.h"
#import "qy265dec.h"
#include "lenthevcdec.h"

@interface SecondViewController ()<UINavigationControllerDelegate, UIImagePickerControllerDelegate, UIAlertViewDelegate>
{
    UILabel  *lblDecoder;
    UITextView *infoView;
    UITextField *decoderFile;
    UIButton *doneBtn;
    UIButton *btnSet;
    UIButton *btnHelp;
    UIButton *selectBtn;
    SettingsDecoderViewController *setDecoderVC;
    MoviesViewController *listVC;
    NSString *outputFlag;
}
@property (strong, nonatomic) IBOutlet UIView *playerView;
@property (weak, nonatomic) IBOutlet GLView *playView;
@property (nonatomic, retain) KSYMoviePlayer *player;

@end

@implementation SecondViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupUI];
    self.player = nil;
    setDecoderVC = [[SettingsDecoderViewController alloc] initDefaultCfg];
    listVC = [[MoviesViewController alloc] initWithSuffix:@".265"];
    
    //__weak SecondViewController *weakself = self;
    listVC.tableBlock = ^(NSString* filePath){
        NSLog(@"%@", filePath);
        decoderFile.text = filePath;
    };

}

- (void)setupUI{
    self.view.backgroundColor = [UIColor whiteColor];
    
    //add set button
    btnSet = [self addButtonWithTitle:@"设置" action:@selector(onSetDecoder:)];
    //add help button
    btnHelp = [self addButtonWithTitle:@"帮助" action:@selector(onHelp:)];
    //add decoder text
    lblDecoder =  [self addLable:@"KSC265解码器"];
    [self addViews:@[btnSet, lblDecoder, btnHelp] withFrame:CGRectMake(0, 40, self.view.frame.size.width, 40)];
    //add browse file button
    selectBtn = [self addButtonWithTitle:@"浏览(.265)文件" action:@selector(didClickSelectBtn:)];
    [self addViews:@[selectBtn] withFrame:CGRectMake(0, 120, self.view.frame.size.width/3, 40)];
    //input decoder file
    decoderFile = [self addTextField:NULL ];
    doneBtn =  [self addButtonWithTitle:@"确定" action:@selector(onDone:)];
    [self addViews2:@[decoderFile,doneBtn] withFrame:CGRectMake(0, 180, self.view.frame.size.width, 40)];
    _playView.frame = CGRectMake(0, 240, self.view.frame.size.width, self.view.frame.size.height/4);
    // info
    infoView = [[UITextView alloc] init];
    infoView.editable = NO;
    infoView.textAlignment = NSTextAlignmentLeft;
    infoView.backgroundColor = [UIColor colorWithWhite:0.8 alpha:0.3];
    infoView.font = [UIFont systemFontOfSize:13];
    infoView.layer.cornerRadius = 2;
    infoView.clipsToBounds = YES;
    infoView.layoutManager.allowsNonContiguousLayout = NO;
    [self addViews:@[infoView] withFrame:CGRectMake(0,  self.view.frame.size.height/4 + 280, self.view.frame.size.width, self.view.frame.size.height- (self.view.frame.size.height/4 + 280) - 20)];
}

- (void) monitorPlaybackTime
{
    if (self.player.decodeEnd) {
        [self stopPlay];
        return;
    }
    
    [self performSelector:@selector(monitorPlaybackTime) withObject:nil afterDelay:1.0];
}

- (void)startPlay:(NSString *) filePath
{
    NSString *decoder = [[NSUserDefaults standardUserDefaults] valueForKey:@"codec"];
    if (self.player == nil) {
        if ([decoder isEqualToString:@"lenthevcdec"]) {
            self.player = [[MoviePlayer alloc] init];
            NSString* string = [NSString stringWithFormat:@"%d" , lenthevcdec_version()];
            [[NSUserDefaults standardUserDefaults] setValue:string forKey:@"version"];
        }
        else {
            self.player = [[KSYMoviePlayer alloc] init];
            NSString* string = [NSString stringWithFormat:@"%s" , strLibQy265Version];
            [[NSUserDefaults standardUserDefaults] setValue:string forKey:@"version"];
        }
    }
    
    int ret = [self.player openMovie:filePath];
    if(ret != 0) {
        UIAlertView * alert = [[UIAlertView alloc] initWithTitle:@"Message" message:@"Get movie data failed! Please check your source or try again." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
        doneBtn.enabled = YES;
        btnSet.enabled = YES;
        selectBtn.enabled = YES;
        return ;
    } else {
        NSString *fps = [[NSUserDefaults standardUserDefaults] valueForKey:@"renderFPS"];
        if ([fps isEqualToString:@"-1 (off)"]) {
            self.playView.hidden = YES;
        }
        else{
            self.playView.hidden = NO;
            [_playView.renderer resizeFromLayer:(CAEAGLLayer*)self.playView.layer];
        }
        self.player.renderer = _playView.renderer;

        int ret = [self.player play];
        if(ret != 0) {
            UIAlertView * alert = [[UIAlertView alloc] initWithTitle:@"Message" message:@"Can't play this movie! Please check its format." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [alert show];
            doneBtn.enabled = YES;
            btnSet.enabled = YES;
            selectBtn.enabled = YES;
            return ;
        }
        [self monitorPlaybackTime];
    }
}

- (void)stopPlay{
    NSString *decoder = [[NSUserDefaults standardUserDefaults] valueForKey:@"codec"];
    NSString *threadNum = [[NSUserDefaults standardUserDefaults] valueForKey:@"threadNum"];
    NSString *renderFPS = [[NSUserDefaults standardUserDefaults] valueForKey:@"renderFPS"];
    NSString *version = [[NSUserDefaults standardUserDefaults] valueForKey:@"version"];
    
    NSUInteger threads = [threadNum intValue];
    if (self.player.out_file_string){
        infoView.text = [NSString stringWithFormat:@"%@\n解码器版本:%@\n解码参数:%@ -b %@ -o %@ -threads %ld\n\n分辨率:%@\n渲染帧率:%@\n线程数:%@\n解码时间:%.2lf s\n解码帧数:%ld\n解码速度:%.2lf f/s\n\n",
                         infoView.text,
                         version,
                         decoder,
                         decoderFile.text,
                         [self.player.out_file_string lastPathComponent],
                         threads,
                         NSStringFromCGSize(CGSizeMake(self.player.width, self.player.height)),
                         renderFPS,
                         threadNum,
                         self.player.real_time,
                         self.player.frameNum,
                         self.player.realFPS];
        
    }else{
        infoView.text = [NSString stringWithFormat:@"%@\n解码器版本:%@\n解码参数:%@ -b %@ -threads %ld\n\n分辨率:%@\n渲染帧率:%@\n线程数:%@\n解码时间:%.2lf s\n解码帧数:%ld\n解码速度:%.2lf f/s\n\n",
                         infoView.text,
                         version,
                         decoder,
                         decoderFile.text,
                         threads,
                         NSStringFromCGSize(CGSizeMake(self.player.width, self.player.height)),
                         renderFPS,
                         threadNum,
                         self.player.real_time,
                         self.player.frameNum,
                         self.player.realFPS];
    }

    [infoView scrollRangeToVisible:NSMakeRange(infoView.text.length, 1)];
    [self.player stop];
    self.player = nil;
    doneBtn.enabled = YES;
    btnSet.enabled = YES;
    selectBtn.enabled = YES;
}

#pragma mark - actions
- (void)onSetDecoder:(UIButton *)btn {
    [self presentViewController:setDecoderVC animated:true completion:nil];
}
- (void)onHelp:(UIButton *)btn {
    DecoderHelperViewController *decoderHelperVC = [[DecoderHelperViewController alloc] init];
    [self presentViewController:decoderHelperVC animated:true completion:nil];
}
- (void)didClickSelectBtn:(UIButton *)send{
    UINavigationController *naVC = [[UINavigationController alloc]initWithRootViewController: listVC];
    [self presentViewController:naVC animated:YES completion:nil];
}
- (void)onDone:(UIButton *)btn {
    btn.enabled = NO;
    btnSet.enabled = NO;
    selectBtn.enabled = NO;
    [decoderFile resignFirstResponder];
    NSString *dir = [NSHomeDirectory() stringByAppendingString:@"/Documents/"];
    NSString *decFile = [dir stringByAppendingPathComponent:decoderFile.text];
    [self startPlay:decFile];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
