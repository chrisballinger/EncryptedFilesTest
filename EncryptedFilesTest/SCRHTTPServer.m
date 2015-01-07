#import "SCRHTTPServer.h"
#import "SCRHTTPConnection.h"

#import "HTTPLogging.h"

#if ! __has_feature(objc_arc)
#warning This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

// Log levels: off, error, warn, info, verbose
// Other flags: trace
static const int httpLogLevel = HTTP_LOG_LEVEL_INFO; // | HTTP_LOG_FLAG_TRACE;


@implementation SCRHTTPServer

- (id)init
{
	if ((self = [super init]))
	{
		// Only accept connections from the device itself
		[self setInterface:@"localhost"];
		
		// Use our custom connection class
		[self setConnectionClass:[SCRHTTPConnection class]];
	}
	return self;
}

- (NSString *)relativePathFromPath:(NSString *)path
{
	// Validate document root setting.
	//
	// If there is no configured documentRoot,
	// then it makes no sense to try to return anything.
	
	if (documentRoot == nil)
	{
		HTTPLogWarn(@"%@[%p]: No configured document root", THIS_FILE, self);
		return nil;
	}
	
	NSString *basePath = [documentRoot stringByStandardizingPath];
	NSString *fullPath = [path stringByStandardizingPath];
	
	// Prevent serving files outside the document root.
	//
	// Sneaky requests may include ".." in the path.
	//
	// E.g.: relativePath="../Documents/TopSecret.doc"
	//       documentRoot="/Users/robbie/Sites"
	//           fullPath="/Users/robbie/Documents/TopSecret.doc"
	//
	// E.g.: relativePath="../Sites_Secret/TopSecret.doc"
	//       documentRoot="/Users/robbie/Sites"
	//           fullPath="/Users/robbie/Sites_Secret/TopSecret"
	
	if (![basePath hasSuffix:@"/"])
	{
		basePath = [documentRoot stringByAppendingString:@"/"];
	}
	
	if (![fullPath hasPrefix:basePath])
	{
		HTTPLogWarn(@"%@[%p]: Request for file outside document root", THIS_FILE, self);
		return nil;
	}
	
	return [fullPath substringFromIndex:[basePath length]];
}

- (id)URLWithPath:(NSString *)filePath
{
	NSString *relativePath = [self relativePathFromPath:filePath];
	if (relativePath == nil) {
		return nil;
	}
	
	NSMutableString *urlStr = [NSMutableString stringWithCapacity:64];
	[urlStr appendFormat:@"http://localhost:%hu", [self listeningPort]];
	
	for (NSString *pathComponent in [relativePath pathComponents])
	{
		CFStringRef pathComponentRef = (__bridge CFStringRef)pathComponent;
		CFStringRef escapedPathComponentRef =
		    CFURLCreateStringByAddingPercentEscapes(NULL, pathComponentRef, NULL, NULL, kCFStringEncodingUTF8);
		
		NSString *escapedPathComponent = CFBridgingRelease(escapedPathComponentRef);
		
		[urlStr appendFormat:@"/%@", escapedPathComponent];
	}
	
	return [NSURL URLWithString:urlStr];
}

@end
