//
//  FirstViewController.m
//  KSY265CodecDemo_iOS
//
//  Created by 江东 on 17/3/17.
//  Copyright © 2017年 江东. All rights reserved.
//

#import "FirstViewController.h"
#import "SettingsEncoderViewController.h"
#import "EncoderHelperViewController.h"
#import "MoviesViewController.h"
#import "MovieEncoder.h"
#import "KSYMovieEncoder.h"
#import "qy265enc.h"
#import "x264.h"

@interface FirstViewController (){
    UITextField *encoderFile;
    UITextView *infoView;
    SettingsEncoderViewController *setEncoderVC;
    MoviesViewController *listVC;
}

@property (nonatomic, retain) MovieEncoder *enc;

@end

@implementation FirstViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setupUI];
    
    self.enc = nil;
    
    setEncoderVC = [[SettingsEncoderViewController alloc] initDefaultCfg];

    listVC = [[MoviesViewController alloc] initWithSuffix:@".yuv"];
    listVC.tableBlock = ^(NSString* filePath){
        NSLog(@"%@", filePath);
        encoderFile.text = filePath;
    };
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self copyFile2Documents:@"960x540_15"];
    [self copyFile2Documents:@"1280x720_15"];
    [self copyFile2Documents:@"640x480_15"];
}

- (void)setupUI{
    self.view.backgroundColor = [UIColor whiteColor];
    
    //add set button
    UIButton *btnSet = [self addButtonWithTitle:@"设置" action:@selector(onSetEncoder:)];
    //add help button
    UIButton *btnHelp = [self addButtonWithTitle:@"帮助" action:@selector(onHelp:)];
    //add encoder text
    UILabel  *lblEncoder =  [self addLable:@"KSC265编码器"];
    [self addViews:@[btnSet, lblEncoder, btnHelp] withFrame:CGRectMake(0, 40, self.view.frame.size.width, 40)];
    //add browse file button
    UIButton *selectBtn = [self addButtonWithTitle:@"浏览(.yuv)文件" action:@selector(didClickSelectBtn:)];
    [self addViews:@[selectBtn] withFrame:CGRectMake(0, 120, self.view.frame.size.width/3, 40)];
    //input encoder file
    encoderFile = [self addTextField:NULL ];
    UIButton *doneBtn =  [self addButtonWithTitle:@"确定" action:@selector(onDone:)];
    [self addViews2:@[encoderFile,doneBtn] withFrame:CGRectMake(0, 180, self.view.frame.size.width, 40)];

    // info
    infoView = [[UITextView alloc] init];
    infoView.editable = NO;
    infoView.textAlignment = NSTextAlignmentLeft;
    infoView.backgroundColor = [UIColor colorWithWhite:0.8 alpha:0.3];
    infoView.font = [UIFont systemFontOfSize:13];
    infoView.layer.cornerRadius = 2;
    infoView.clipsToBounds = YES;
    infoView.layoutManager.allowsNonContiguousLayout = NO;
    [self addViews:@[infoView] withFrame:CGRectMake(0,  260, self.view.frame.size.width, self.view.frame.size.height- 260 - 20)];
}

- (void)startEncoder:(NSString *) filePath
{
    NSString *encoder = [[NSUserDefaults standardUserDefaults] valueForKey:@"encoder"];
    if (self.enc == nil) {
        if ([encoder isEqualToString:@"x264"]) {
            self.enc = [[MovieEncoder alloc] init];
            NSString* string = [NSString stringWithFormat:@"%s" ,X264_POINTVER];
            [[NSUserDefaults standardUserDefaults] setValue:string  forKey:@"version"];
        }
        else {
            self.enc = [[KSYMovieEncoder alloc] init];
            NSString* string = [NSString stringWithFormat:@"%s" , strLibQy265Version];
            [[NSUserDefaults standardUserDefaults] setValue:string forKey:@"version"];
        }
    }
    
    int ret = [self.enc openMovie:filePath];
    if(ret != 0) {
        UIAlertView * alert = [[UIAlertView alloc] initWithTitle:@"Message" message:@"Get movie data failed! Please check your source or try again." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
        return ;
    } else {
        int ret = [self.enc encoder];
        if(ret != 0) {
            UIAlertView * alert = [[UIAlertView alloc] initWithTitle:@"Message" message:@"Can't encode this yuv! Please check its format." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [alert show];
            return ;
        }
        
        NSString *encoder = [[NSUserDefaults standardUserDefaults] valueForKey:@"encoder"];
        NSString *fps = [[NSUserDefaults standardUserDefaults] valueForKey:@"fps"];
        NSString *bitRate = [[NSUserDefaults standardUserDefaults] valueForKey:@"bitRate"];
        NSString *threads = [[NSUserDefaults standardUserDefaults] valueForKey:@"threads"];
        NSString *profile = [[NSUserDefaults standardUserDefaults] valueForKey:@"profile"];
        NSString *delayed = [[NSUserDefaults standardUserDefaults] valueForKey:@"delayed"];
        NSString *version = [[NSUserDefaults standardUserDefaults] valueForKey:@"version"];
        NSString *psnr = [[NSUserDefaults standardUserDefaults] valueForKey:@"psnr"];
        
        NSFileManager *manager = [NSFileManager defaultManager];
        NSDictionary *outDic = [manager attributesOfItemAtPath:self.enc.out_file_string error:nil];
        NSDictionary *inDic = [manager attributesOfItemAtPath:filePath error:nil];
        unsigned long long outLength = outDic.fileSize;
        unsigned long long inLength = inDic.fileSize;
        
        if ([encoder isEqualToString:@"x264"]) {
            NSString *delayShow;
            if ([delayed isEqualToString:@"zerolatency"]) {
                delayShow = @"--bframes 0 --tune zerolatency";
            }
            else if([delayed isEqualToString:@"livestreaming"]){
                delayShow = @"--bframes 3";
            }
            else{
                delayShow = @"--bframes 7";
            }
            
            infoView.text = [NSString stringWithFormat:@"%@\n编码器版本:%@\n编码参数:%@ --preset %@ %@ --input-res %ldx%ld --fps %@ --threads %@ --bitrate %@ -o %@ %@\n\n编码时间:%.2lf s\n编码帧数:%ld\n编码速度:%.2lf f/s\n压缩比:%llu\nPSNR:%.2lf\n\n视频信息\n码率:%.2lf kbps\n分辨率:%@\n帧率:%@\n文件总时长:%.2lf s\n\n\n",
                             infoView.text,
                             version,
                             encoder,
                             profile,
                             delayShow,
                             self.enc.width,
                             self.enc.height,
                             fps,
                             threads,
                             bitRate,
                             [self.enc.out_file_string lastPathComponent],
                             encoderFile.text,
                             self.enc.real_time,
                             self.enc.frameNum,
                             self.enc.realFPS,
                             inLength/outLength,
                             self.enc.avg_psnr,
                             outLength*8.0/(1000.0*(self.enc.frameNum/[fps floatValue])),
                             NSStringFromCGSize(CGSizeMake(self.enc.width, self.enc.height)),
                             fps,
                             self.enc.frameNum/[fps floatValue]];
        }
        else{
            infoView.text = [NSString stringWithFormat:@"%@\n编码器版本:%@\n编码参数:%@ -i %@ -preset %@ -latency %@ -wdt %ld -hgt %ld -fr %@ -threads %@ -br %@ -b %@\n\n编码时间:%.2lf s\n编码帧数:%ld\n编码速度:%.2lf f/s\n压缩比:%llu\nPSNR:%@\n\n视频信息\n码率:%.2lf kbps\n分辨率:%@\n帧率:%@\n文件总时长:%.2lf s\n\n\n",
                             infoView.text,
                             version,
                             encoder,
                             encoderFile.text,
                             profile,
                             delayed,
                             self.enc.width,
                             self.enc.height,
                             fps,
                             threads,
                             bitRate,
                             [self.enc.out_file_string lastPathComponent],
                             self.enc.real_time,
                             self.enc.frameNum,
                             self.enc.realFPS,
                             inLength/outLength,
                             psnr,
                             outLength*8.0/(1000.0*(self.enc.frameNum/[fps floatValue])),
                             NSStringFromCGSize(CGSizeMake(self.enc.width, self.enc.height)),
                             fps,
                             self.enc.frameNum/[fps floatValue]];
            
        }
        [infoView scrollRangeToVisible:NSMakeRange(infoView.text.length, 1)];
    }
    self.enc = nil;
}

#pragma mark - actions
- (void)onSetEncoder:(UIButton *)btn {
    [self presentViewController:setEncoderVC animated:true completion:nil];
}
- (void)onHelp:(UIButton *)btn {
    EncoderHelperViewController *encoderHelperVC = [[EncoderHelperViewController alloc] init];
    [self presentViewController:encoderHelperVC animated:true completion:nil];
}
- (void)didClickSelectBtn:(UIButton *)btn{
    UINavigationController *naVC = [[UINavigationController alloc]initWithRootViewController: listVC];
    [self presentViewController:naVC animated:YES completion:nil];
}
- (void)onDone:(UIButton *)btn {
    [encoderFile resignFirstResponder];
    NSString *dir = [NSHomeDirectory() stringByAppendingString:@"/Documents/"];
    NSString *encFile = [dir stringByAppendingPathComponent:encoderFile.text];
    [self startEncoder:encFile];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(NSString*) copyFile2Documents:(NSString*)fileName
{
    NSFileManager*fileManager =[NSFileManager defaultManager];
    NSError*error;
    NSArray*paths =NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask, YES);
    NSString*documentsDirectory =[paths objectAtIndex:0];
    
    NSString*destPath =[documentsDirectory stringByAppendingPathComponent:fileName];
    destPath = [destPath stringByAppendingString:@".yuv"];
    
    //  如果目标目录也就是(Documents)目录没有数据库文件的时候，才会复制一份，否则不复制
    if(![fileManager fileExistsAtPath:destPath]){
        NSString* sourcePath =[[NSBundle mainBundle] pathForResource:fileName ofType:@"yuv"];
        [fileManager copyItemAtPath:sourcePath toPath:destPath error:&error];
    }
    return destPath;
}

@end
