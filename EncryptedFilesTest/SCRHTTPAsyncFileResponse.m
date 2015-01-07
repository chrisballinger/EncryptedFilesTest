#import "SCRHTTPAsyncFileResponse.h"
#import "HTTPConnection.h"

@interface SCRHTTPAsyncFileResponse()
@property (nonatomic) NSUInteger decryptedBytes;
@property (nonatomic) BOOL finishedDecryption;
@property (nonatomic) BOOL finishedReading;

/**
 *  We need to handle the last chunk of data in a special way due to RNDecryptor's finish method
 *  not timing up properly with the responseHasAvailableData:
 */
@property (nonatomic) NSMutableData *finalData;

@end

@implementation SCRHTTPAsyncFileResponse

- (void)processReadBuffer
{
	// This method is here to allow superclasses to perform post-processing of the data.
	// For an example, see the HTTPDynamicFileResponse class.
	//
	// At this point, the readBuffer has readBufferOffset bytes available.
	// 
	// This method is in charge of updating the readBufferOffset.
	// Failure to do so will cause the readBuffer to grow to fileLength. (Imagine a 1 GB file...)
	
	// Copy the data out of the temporary readBuffer.
	NSData *mData = [[NSData alloc] initWithBytes:readBuffer length:readBufferOffset];
    
    // Reset the read buffer.
    readBufferOffset = 0;
    
    NSLog(@"Sending %d bytes to be decrypted", (int)mData.length);
    NSLog(@"Read offset: %d / %d", (int)readOffset, (int)fileLength);
    
    if (readOffset == fileLength) {
        self.finishedReading = YES;
    }
    
    if (mData.length) {
        // Decrypt the data
        [self.decryptor addData:mData];
    }
    
    if (self.finishedReading == YES) {
        [self.decryptor finish];
    }
}

- (id)initWithFilePath:(NSString *)_filePath forConnection:(HTTPConnection *)_connection {
    if (self = [super initWithFilePath:_filePath forConnection:_connection]) {
        [self setupDecryptor];
    }
    return self;
}

- (void) setupDecryptor {
    self.decryptor = [[RNDecryptor alloc] initWithPassword:@"password" handler:^(RNCryptor *cryptor, NSData *decryptedData) {
        NSLog(@"Decrypted %ld bytes", (unsigned long)decryptedData.length);
        if (cryptor.isFinished) {
            self.finishedDecryption = YES;
            // call my delegate that I'm finished with decrypting
            NSLog(@"finished decryption");
            [self.finalData appendData:decryptedData];
        }
        if (!decryptedData.length) {
            NSLog(@"0 bytes!");
            return;
        }
        if (self.finishedReading && !cryptor.isFinished) {
            self.finalData = [NSMutableData dataWithData:decryptedData];
        }
        self.decryptedBytes += decryptedData.length;
        // Store data (in preparation to deliver to connection)
        data = [decryptedData copy];
        
        // Notify the connection that we have data available for it.
        if (!self.finishedReading) {
            [connection responseHasAvailableData:self];
        } else if (cryptor.isFinished) {
            data = self.finalData;
            [connection responseHasAvailableData:self];
        }
    }];
}

- (BOOL) isChunked {
    return YES;
}

/**
 * Should only return YES after the HTTPConnection has read all available data.
 * That is, all data for the response has been returned to the HTTPConnection via the readDataOfLength method.
 **/
- (BOOL)isDone {
    return self.finishedDecryption;
}

@end
