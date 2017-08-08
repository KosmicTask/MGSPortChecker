/*
 * MGSPortChecker.h
 *
 * Created by Mugginsoft 24/12/2012
 *
 */

/******************************************************************************
 * $Id: PortChecker.h 13251 2012-03-13 02:52:11Z livings124 $
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

#import <Cocoa/Cocoa.h>
#import <Cocoa/Cocoa.h>

@class MGSPortChecker;

@protocol MGSPortCheckerDelegate <NSObject>
@optional
- (void)portCheckerDidFinishProbing:(MGSPortChecker *)checker;
@end

enum
{
    kMGS_PORT_STATUS_NA,
    kMGS_PORT_STATUS_CHECKING,
    kMGS_PORT_STATUS_OPEN,
    kMGS_PORT_STATUS_CLOSED,
    kMGS_PORT_STATUS_ERROR
};
typedef NSInteger port_status_t;

@interface MGSPortChecker : NSObject
{    
    port_status_t _status;
    
    NSURLConnection * _connection;
    NSMutableData * _portProbeData;
    
    NSTimer * _timer;
    
    NSUInteger _portNumber;
    id <MGSPortCheckerDelegate> __weak _delegate;
    NSUInteger _delay;
    NSUInteger _portQueryTimeout;
    NSURL *_URL;
    NSString *_path;
    NSString *_gatewayAddress;
    NSString *_portTag;
    NSString *_timeoutTag;
}

+ (id)startForURL:(NSURL *)url port:(NSInteger)portNumber timeout:(NSUInteger)timeout delay:(NSUInteger)delay withDelegate:(id)delegate;
- (id)initForURL:(NSURL *)url; // desigated initializer
- (BOOL)start;
- (BOOL)startWithDelay:(NSUInteger)delay;
- (void)stop;
- (NSURL *)composedURL;

@property NSUInteger portNumber;
@property (weak) id <MGSPortCheckerDelegate> delegate;
@property NSUInteger delay;
@property NSUInteger portQueryTimeout;
@property (copy) NSURL *URL;
@property (readonly) port_status_t status;
@property (copy, readonly) NSString *gatewayAddress;
@property (copy) NSString *path;
@property (copy) NSString *portTag;
@property (copy) NSString *timeoutTag;

@end
