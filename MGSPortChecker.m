/*
 * MGSPortChecker.m
 *
 * Created by Mugginsoft 24/12/2012
 *
 */

/******************************************************************************
 * $Id: PortChecker.m 13492 2012-09-10 02:37:29Z livings124 $
 *
 * Copyright (c) 2006-2012 Transmission authors and contributors
 *
 * Permission is hereby granted, free of charge, to any person obtaining a
 * copy of this software and associated documentation files (the "Software"),
 * to deal in the Software without restriction, including without limitation
 * the rights to use, copy, modify, merge, publish, distribute, sublicense,
 * and/or sell copies of the Software, and to permit persons to whom the
 * Software is furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
 * DEALINGS IN THE SOFTWARE.
 *****************************************************************************/

#import "MGSPortChecker.h"

NSString * const MGSPortTag = @"%_PORT_%";
NSString * const MGSTimeOutTag = @"%_TIMEOUT_%";
#define MGSPath [NSString stringWithFormat:@"portcheck.php?p=%@&t=%@", MGSPortTag, MGSTimeOutTag]


// class extension
@interface MGSPortChecker ()
- (void)startProbe:(NSTimer *)timer;
- (void)callBackWithStatus:(port_status_t)status;

@property (readwrite) port_status_t status;
@property (copy, readwrite) NSString *gatewayAddress;

@end

@implementation MGSPortChecker

@synthesize portNumber = _portNumber;
@synthesize delegate = _delegate;
@synthesize delay = _delay;
@synthesize portQueryTimeout = _portQueryTimeout;
@synthesize URL = _URL;
@synthesize gatewayAddress = _gatewayAddress;
@synthesize status = _status;
@synthesize path = _path;
@synthesize portTag = _portTag;
@synthesize timeoutTag = _timeoutTag;

#pragma mark -
#pragma mark Factory
/*
 
 + startForURL:port:timeout:delay:withDelegate
 
 */
+ (id)startForURL:(NSURL *)url port:(NSInteger)portNumber timeout:(NSUInteger)timeout delay:(NSUInteger)delay withDelegate:(id)delegate
{
    MGSPortChecker *checker = [[[self class] alloc] initForURL:url];
    
    if (checker) {
        checker.portNumber = portNumber;
        checker.portQueryTimeout = timeout;
        checker.delay = delay;
        checker.delegate = delegate;
        
        [checker start];
    }
    
    return checker;
}

#pragma mark -
#pragma mark Initialize

/*
 
 - initForURL:
 
 */
- (id)initForURL:(NSURL *)url
{
    self = [super init];
    if (self) {
        _URL = [url retain];
        _portNumber = 80;
        _portQueryTimeout = 10;
        _delay = 0;
        _status = kMGS_PORT_STATUS_NA;
        _gatewayAddress = @"";
        _path = [MGSPath retain];
        _portTag = MGSPortTag;
        _timeoutTag = MGSTimeOutTag;
        
        if (![self isValid]) {
            self = nil;
            return self;
        }
    }
    
    return self;
}

/*
 
 - dealloc
 
 */
- (void)dealloc
{
    [_timer invalidate];
    
    [_timer release];
    [_connection release];
    [_portProbeData release];
    [_URL release];
    [_gatewayAddress release];
    [_portTag release];
    [_timeoutTag release];
    [_path release];
    
    [super dealloc];
}

#pragma mark -
#pragma mark URL handling

/*
 
 - composedURL
 
 */
- (NSURL *)composedURL
{
    NSString *portString = [NSString stringWithFormat:@"%lu", (long)self.portNumber];
    NSString *timeoutString = [NSString stringWithFormat:@"%lu", (long)self.portQueryTimeout];
    NSMutableString *path = [NSMutableString stringWithFormat:@"%@", self.path];
 
    [path replaceOccurrencesOfString:self.portTag withString:portString options:0 range:NSMakeRange(0, [path length])];
    [path replaceOccurrencesOfString:self.timeoutTag withString:timeoutString options:0 range:NSMakeRange(0, [path length])];
    
    // we have to go back to a string rep to add the query
    NSString *sURL = [self.URL absoluteString];
    sURL = [sURL stringByAppendingPathComponent:path];
    
    NSURL *theURL = [NSURL URLWithString:sURL];
    
    return theURL;
}
#pragma mark -
#pragma mark Control

/*
 
 - start
 
 */
- (BOOL)start
{
    if (!self.isValid) {
        return false;
    }
    
    if (self.status == kMGS_PORT_STATUS_CHECKING) {
        return false;
    }
    
    self.status = kMGS_PORT_STATUS_CHECKING;
    
    _timer = [[NSTimer scheduledTimerWithTimeInterval:self.delay target:self selector:@selector(startProbe:) userInfo:nil repeats: NO] retain];
    
    return true;
}

/*
 
 - startWithDelay:
 
 */
- (BOOL)startWithDelay:(NSUInteger)delay 
{
    self.delay = delay;
    return [self start];
}

/*
 
 - stop
 
 */
- (void)stop
{
    if (self.status != kMGS_PORT_STATUS_CHECKING) {
        return;
    }
    
    self.status = kMGS_PORT_STATUS_NA;
    [_timer invalidate];
    [_timer release];
    _timer = nil;
    
    [_connection cancel];
}

/*
 
 -startProbe:
 
 */
- (void)startProbe:(NSTimer *)timer
{
#pragma unused(timer)
    
    [_timer release];
    _timer = nil;
    
    NSURL *theURL = [self composedURL];
    
#ifdef MGS_DEBUG
    NSLog(@"composedURL = %@", theURL);
#endif
    
    NSURLRequest * portProbeRequest = [NSURLRequest requestWithURL:theURL
                                                       cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData timeoutInterval:15.0];
    
    if ((_connection = [[NSURLConnection alloc] initWithRequest:portProbeRequest delegate:self]))
        _portProbeData = [[NSMutableData alloc] init];
    else
    {
        NSLog(@"Unable to get port status: failed to initiate connection");
        [self callBackWithStatus:kMGS_PORT_STATUS_ERROR];
    }
}

#pragma mark -
#pragma mark NSURLConnectionDelegate

/*
 
  - connection:didReceiveResponse:
 
 */
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
#pragma unused(connection)
#pragma unused(response)
    
    [_portProbeData setLength: 0];
}

/*
 
 - connection:didReceiveData:
 
 */
- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *) data
{
#pragma unused(connection)
    
    [_portProbeData appendData:data];
}

/*
 
 - connection:didFailWithError:
 
 */
- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *) error
{
#pragma unused(connection)
    
    NSLog(@"Unable to get port status: connection failed (%@)", [error localizedDescription]);
    [self callBackWithStatus:kMGS_PORT_STATUS_ERROR];
}

/*
 
 - connectionDidFinishLoading:
 
 */
- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
#pragma unused(connection)
    
    NSString * probeString = [[NSString alloc] initWithData:_portProbeData encoding:NSUTF8StringEncoding];
    [_portProbeData release];
    _portProbeData = nil;
    
    if (probeString)
    {
        NSString *probeStatus = nil;
        
        //
        // probe string is : <gateway IP> <0/1>
        //
        NSArray *probeComponents = [probeString componentsSeparatedByString:@" "];
        if ([probeComponents count] == 2) {
            self.gatewayAddress = [probeComponents objectAtIndex:0];
            probeStatus = [probeComponents objectAtIndex:1];
        }
        if ([probeStatus isEqualToString: @"1"])
            [self callBackWithStatus:kMGS_PORT_STATUS_OPEN];
        else if ([probeStatus isEqualToString: @"0"])
            [self callBackWithStatus:kMGS_PORT_STATUS_CLOSED];
        else
        {
            NSLog(@"Unable to get port status: invalid response (%@)", probeString);
            [self callBackWithStatus:kMGS_PORT_STATUS_ERROR];
        }
        [probeString release];
    }
    else
    {
        NSLog(@"Unable to get port status: invalid data received");
        [self callBackWithStatus:kMGS_PORT_STATUS_ERROR];
    }
}

#pragma mark -
#pragma mark Validation

/*
 
 - isValid
 
 */
- (BOOL)isValid
{
    return YES;
}

#pragma mark -
#pragma mark Delegate handling

/*
 
 - callBackWithStatus:
 
 */
- (void)callBackWithStatus:(port_status_t)status
{
    self.status = status;
    
    if (_delegate && [_delegate respondsToSelector: @selector(portCheckerDidFinishProbing:)])
        [(NSObject *)_delegate performSelectorOnMainThread: @selector(portCheckerDidFinishProbing:) withObject:self waitUntilDone:NO];
}

@end

