//
//  ViewController.m
//  EncryptedFilesTest
//
//  Created by Christopher Ballinger on 1/5/15.
//  Copyright (c) 2015 Chris Ballinger. All rights reserved.
//

#import "ViewController.h"
#import <MediaPlayer/MPMoviePlayerViewController.h>
#import "PureLayout.h"
#import "RNEncryptor.h"
#import "RNDecryptor.h"
#import "SCRHTTPServer.h"

@interface ViewController ()
@property (nonatomic, strong) UIButton *playLocalFileButton;
@property (nonatomic, strong) UIButton *encryptLocalFileButton;
@property (nonatomic, strong) UIButton *decryptFileButton;
@property (nonatomic, strong) UIButton *playEncryptedFileButton;
@property (nonatomic, strong) NSURL *localFileURL;
@property (nonatomic, strong) NSString *password;
@property (nonatomic, strong) SCRHTTPServer *httpServer;
@property (nonatomic, strong) NSString *encryptedFileName;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.localFileURL = [[NSBundle mainBundle] URLForResource:@"480p_15sec" withExtension:@"mov"];
    self.password = @"password";
    
    [self setupButtons];
    [self encryptLocalFileButtonPressed:nil];
}

- (void) setupHTTPServer {
    self.httpServer = [[SCRHTTPServer alloc] init];
    [self.httpServer setDocumentRoot:[self applicationDocumentsDirectory]];
    NSError *error = nil;
    
    if ([self.httpServer start:&error])
    {
        NSString *urlString = [NSString stringWithFormat:@"http://localhost:%d/%@", self.httpServer.listeningPort, self.encryptedFileName];
        NSLog(@"HTTP Server Ready: %@", urlString);
        self.playEncryptedFileButton.enabled = YES;
        self.decryptFileButton.enabled = YES;
    }
    else
    {
        NSLog(@"Error starting HTTP Server: %@", error);
    }
}

- (void) setupButtons {
    self.playLocalFileButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [self.playLocalFileButton setTitle:@"Play Local File" forState:UIControlStateNormal];
    [self.playLocalFileButton addTarget:self action:@selector(playLocalFileButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.playLocalFileButton];
    
    self.encryptLocalFileButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [self.encryptLocalFileButton setTitle:@"Encrypt Local File" forState:UIControlStateNormal];
    [self.encryptLocalFileButton addTarget:self action:@selector(encryptLocalFileButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.encryptLocalFileButton];

    self.playEncryptedFileButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [self.playEncryptedFileButton setTitle:@"Play Encrypted File" forState:UIControlStateNormal];
    [self.playEncryptedFileButton addTarget:self action:@selector(playEncryptedFileButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    self.playEncryptedFileButton.enabled = NO;
    [self.view addSubview:self.playEncryptedFileButton];
    
    self.decryptFileButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [self.decryptFileButton setTitle:@"Decrypt File" forState:UIControlStateNormal];
    [self.decryptFileButton addTarget:self action:@selector(decryptFileButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    self.decryptFileButton.enabled = NO;
    [self.view addSubview:self.decryptFileButton];
}

- (void) updateViewConstraints {
    [super updateViewConstraints];
    [self.playLocalFileButton autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsMake(10, 10, 10, 10) excludingEdge:ALEdgeBottom];
    [self.playLocalFileButton autoSetDimension:ALDimensionHeight toSize:40];
    
    [self.encryptLocalFileButton autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.playLocalFileButton];
    [self.encryptLocalFileButton autoPinEdgeToSuperviewEdge:ALEdgeRight withInset:10];
    [self.encryptLocalFileButton autoPinEdgeToSuperviewEdge:ALEdgeLeft withInset:10];
    [self.encryptLocalFileButton autoSetDimension:ALDimensionHeight toSize:40];
    
    [self.playEncryptedFileButton autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.encryptLocalFileButton];
    [self.playEncryptedFileButton autoPinEdgeToSuperviewEdge:ALEdgeRight withInset:10];
    [self.playEncryptedFileButton autoPinEdgeToSuperviewEdge:ALEdgeLeft withInset:10];
    [self.playEncryptedFileButton autoSetDimension:ALDimensionHeight toSize:40];
    
    [self.decryptFileButton autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.playEncryptedFileButton];
    [self.decryptFileButton autoPinEdgeToSuperviewEdge:ALEdgeRight withInset:10];
    [self.decryptFileButton autoPinEdgeToSuperviewEdge:ALEdgeLeft withInset:10];
    [self.decryptFileButton autoSetDimension:ALDimensionHeight toSize:40];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) playLocalFileButtonPressed:(id)sender {
    [self playFileWithURL:self.localFileURL];
}


- (void) encryptLocalFileButtonPressed:(id)sender {
    self.playEncryptedFileButton.enabled = NO;
    // Make sure that this number is larger than the header + 1 block.
    // 33+16 bytes = 49 bytes. So it shouldn't be a problem.
    int blockSize = 32 * 1024;
    
    self.encryptedFileName = [self.localFileURL.path lastPathComponent];
    NSString *encryptedFilePath = [[self applicationDocumentsDirectory] stringByAppendingPathComponent:self.encryptedFileName];
    if ([[NSFileManager defaultManager] fileExistsAtPath:encryptedFilePath]) {
        [[NSFileManager defaultManager] removeItemAtPath:encryptedFilePath error:nil];
    }
    
    NSInputStream *localFileStream = [NSInputStream inputStreamWithFileAtPath:self.localFileURL.path];
    NSOutputStream *encryptedStream = [NSOutputStream outputStreamToFileAtPath:encryptedFilePath append:NO];
    
    [localFileStream open];
    [encryptedStream open];
    
    // We don't need to keep making new NSData objects. We can just use one repeatedly.
    __block NSMutableData *data = [NSMutableData dataWithLength:blockSize];
    __block RNEncryptor *encryptor = nil;
    
    dispatch_block_t readStreamBlock = ^{
        [data setLength:blockSize];
        NSInteger bytesRead = [localFileStream read:[data mutableBytes] maxLength:blockSize];
        if (bytesRead < 0) {
            // Throw an error
        }
        else if (bytesRead == 0) {
            [encryptor finish];
        }
        else {
            [data setLength:bytesRead];
            [encryptor addData:data];
            NSLog(@"Sent %ld bytes to encryptor", (unsigned long)bytesRead);
        }
    };
    
    encryptor = [[RNEncryptor alloc] initWithSettings:kRNCryptorAES256Settings
                                             password:self.password
                                              handler:^(RNCryptor *cryptor, NSData *data) {
                                                  NSLog(@"Encryptor recevied %ld bytes", (unsigned long)data.length);
                                                  NSInteger bytesWritten = [encryptedStream write:data.bytes maxLength:data.length];
                                                  NSLog(@"Wrote recevied %d bytes", (int)bytesWritten);
                                                  if (cryptor.isFinished) {
                                                      [encryptedStream close];
                                                      // call my delegate that I'm finished with decrypting
                                                      NSLog(@"finished encryption");
                                                      dispatch_async(dispatch_get_main_queue(), ^{
                                                          [self setupHTTPServer];
                                                      });
                                                  }
                                                  else {
                                                      // Might want to put this in a dispatch_async(), but I don't think you need it.
                                                      readStreamBlock();
                                                  }
                                              }];
    
    // Read the first block to kick things off    
    readStreamBlock();
}

- (void) decryptFileButtonPressed:(id)sender {
    // Make sure that this number is larger than the header + 1 block.
    // 33+16 bytes = 49 bytes. So it shouldn't be a problem.
    int blockSize = 32 * 1024;
    
    NSString *encryptedFilePath = [[self applicationDocumentsDirectory] stringByAppendingPathComponent:self.encryptedFileName];
    NSString *outputFileName = [NSString stringWithFormat:@"decrypted-%@", self.encryptedFileName];
    NSString *outputFilePath = [[self applicationDocumentsDirectory] stringByAppendingPathComponent:outputFileName];
    if ([[NSFileManager defaultManager] fileExistsAtPath:outputFilePath]) {
        [[NSFileManager defaultManager] removeItemAtPath:outputFilePath error:nil];
    }
    
    
    NSInputStream *cryptedStream = [NSInputStream inputStreamWithFileAtPath:encryptedFilePath];
    NSOutputStream *decryptedStream = [NSOutputStream outputStreamToFileAtPath:outputFilePath append:NO];
    
    [cryptedStream open];
    [decryptedStream open];
    
    // We don't need to keep making new NSData objects. We can just use one repeatedly.
    __block NSMutableData *data = [NSMutableData dataWithLength:blockSize];
    __block RNDecryptor *decryptor = nil;
    
    dispatch_block_t readStreamBlock = ^{
        [data setLength:blockSize];
        NSInteger bytesRead = [cryptedStream read:[data mutableBytes] maxLength:blockSize];
        if (bytesRead < 0) {
            // Throw an error
        }
        else if (bytesRead == 0) {
            [decryptor finish];
        }
        else {
            [data setLength:bytesRead];
            [decryptor addData:data];
            NSLog(@"Sent %ld bytes to decryptor", (unsigned long)bytesRead);
        }
    };
    
    decryptor = [[RNDecryptor alloc] initWithPassword:self.password
                                              handler:^(RNCryptor *cryptor, NSData *data) {
                                                  NSLog(@"Decryptor recevied %ld bytes", (unsigned long)data.length);
                                                  NSInteger bytesWritten = [decryptedStream write:data.bytes maxLength:data.length];
                                                  NSLog(@"Wrote recevied %d bytes", (int)bytesWritten);
                                                  if (cryptor.isFinished) {
                                                      [decryptedStream close];
                                                      // call my delegate that I'm finished with decrypting
                                                      NSLog(@"finished decryption");
                                                  }
                                                  else {
                                                      // Might want to put this in a dispatch_async(), but I don't think you need it.
                                                      readStreamBlock();
                                                  }
                                              }];
    
    // Read the first block to kick things off
    readStreamBlock();
}


- (void) playEncryptedFileButtonPressed:(id)sender {
    NSString *urlString = [NSString stringWithFormat:@"http://localhost:%d/%@", self.httpServer.listeningPort, self.encryptedFileName];
    NSURL *url = [NSURL URLWithString:urlString];
    [self playFileWithURL:url];
}

- (void) playFileWithURL:(NSURL*)url {
    NSParameterAssert(url != nil);
    MPMoviePlayerViewController *movie = [[MPMoviePlayerViewController alloc] initWithContentURL:url];
    [self presentMoviePlayerViewControllerAnimated:movie];
}

- (NSString *) applicationDocumentsDirectory
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *basePath = [paths firstObject];
    return basePath;
}

@end
