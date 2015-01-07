#import <Foundation/Foundation.h>
#import "HTTPAsyncFileResponse.h"
#import "RNDecryptor.h"

/**
 * This method extends HTTPAsyncFileResponse.
 * It automatically decrypts the file on the fly.
**/
@interface SCRHTTPAsyncFileResponse : HTTPAsyncFileResponse

@property (nonatomic, strong) RNDecryptor *decryptor;

@end
