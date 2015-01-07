#import <Foundation/Foundation.h>
#import "HTTPServer.h"


@interface SCRHTTPServer : HTTPServer

/**
 * Returns a URL that can be used to access the filePath through this HTTPServer instance.
 * 
 * Returns nil if the filePath isn't within the configured documentRoom of the server.
**/
- (id)URLWithPath:(NSString *)filePath;

@end
