#import "SCRHTTPConnection.h"
#import "SCRHTTPAsyncFileResponse.h"

#import "HTTPMessage.h"
#import "HTTPLogging.h"
#import "HTTPFileResponse.h"
#import "HTTPAsyncFileResponse.h"

// Log levels: off, error, warn, info, verbose
// Other flags: trace
static const int httpLogLevel = HTTP_LOG_LEVEL_WARN; // | HTTP_LOG_FLAG_TRACE;


@implementation SCRHTTPConnection

/**
 * This method is called to get a response for a request.
 * You may return any object that adopts the HTTPResponse protocol.
 *
 * The HTTPServer comes with several implementations including:
 * - HTTPFileResponse - for simple file responses
 * - HTTPDataResponse - for responsding with custom data
 * - HTTPErrorResponse - for custom error responses
 * - HTTPRedirectResponse - for redirects
 * - HTTPAsyncFileResponse - for asynchronous file io
 * - HTTPDynamicFileResponse - for template files, where components are replaced on the fly
 *
 * You can use any of the included implementations, extend them, or create your own.
**/
- (NSObject<HTTPResponse> *)httpResponseForMethod:(NSString *)method URI:(NSString *)path
{
	HTTPLogTrace();
	
	// Override me to provide custom responses.
	
	NSString *filePath = [self filePathForURI:path allowDirectory:NO];
	
	BOOL isDir = NO;
	
	if (filePath && [[NSFileManager defaultManager] fileExistsAtPath:filePath isDirectory:&isDir] && !isDir)
	{
		return [[SCRHTTPAsyncFileResponse alloc] initWithFilePath:filePath forConnection:self];
	}
	
	return nil;
}

/**
 * This method is called immediately prior to sending the response headers.
 * This method adds standard header fields, and then converts the response to an NSData object.
**/
- (NSData *)preprocessResponse:(HTTPMessage *)response
{
	HTTPLogTrace();
	
	// Override me to customize the response headers
	// You'll likely want to add your own custom headers, and then return [super preprocessResponse:response]
	
	NSString *filePath = nil;
	
	if ([httpResponse isKindOfClass:[HTTPFileResponse class]])
	{
		filePath = [(HTTPFileResponse *)httpResponse filePath];
	}
	else if ([httpResponse isKindOfClass:[HTTPAsyncFileResponse class]])
	{
		filePath = [(HTTPAsyncFileResponse *)httpResponse filePath];
	}
	
	if (filePath)
	{
		// Add proper content type headers to support media
		
		NSString *fileExtension = [filePath pathExtension];
		
		if ([fileExtension isEqualToString:@"mp3"])
		{
			[response setHeaderField:@"Content-Type" value:@"audio/mpeg"];
		}
		else if ([fileExtension isEqualToString:@"aac"])
		{
			[response setHeaderField:@"Content-Type" value:@"audio/aac"];
		}
		else if ([fileExtension isEqualToString:@"m4a"])
		{
			[response setHeaderField:@"Content-Type" value:@"audio/aac"];
		}
		else if ([fileExtension isEqualToString:@"m4p"])
		{
			[response setHeaderField:@"Content-Type" value:@"audio/aac"];
		}
		else if ([fileExtension isEqualToString:@"mov"])
		{
			[response setHeaderField:@"Content-Type" value:@"video/quicktime"];
		}
		else if ([fileExtension isEqualToString:@"mp4"])
		{
			[response setHeaderField:@"Content-Type" value:@"video/mp4"];
		}
		else if ([fileExtension isEqualToString:@"m4v"])
		{
			[response setHeaderField:@"Content-Type" value:@"video/x-m4v"];
		}
		else if ([fileExtension isEqualToString:@"3gp"])
		{
			[response setHeaderField:@"Content-Type" value:@"video/3gpp"];
		}
		else if ([fileExtension isEqualToString:@"pdf"])
		{
			[response setHeaderField:@"Content-Type" value:@"application/pdf"];
		}
	}
	
	return [super preprocessResponse:response];
}

@end
