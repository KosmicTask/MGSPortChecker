What is it
==============

MGSPortChecker is an OS X Cocoa router port checker. Typically an app will use MGSPortChecker  to determine whether a particular port is open on the local Internet router. MGSPortChecker calls out to an external web server that probes the source IP for a specific open port.

Where can I see it in use
=========================

You can see MGSPortChecker used in the following products:

* [KosmicTask](http://www.mugginsoft.com) : a multi (20+) language scripting environment for OS X that features script editing, network sharing, remote execution and file processing.

If you use MGSPortChecker in your app and want it added to the list raise it as an issue.

Installation
=====

Install `portcheck.php` on your web server (say at portchecker.example.com/portcheck.php). This script will be used to call back to the source of the request to check the port status. 

Usage
==========

Usage is simple. Allocate a `MGSPortChecker`, configure it and call `start`. Alternatively use the `+ startForURL:port:timeout:delay:withDelegate` factory method.

	-(void)startPortChecking
	{
		// portcheck.php is installed on this URL
		NSString *portCheckerURL = @"http://portcheck.example.com";

		// allocate the port checker
		NSURL *url = [NSURL URLWithString:portCheckerURL];
    	_portChecker = [[MGSPortChecker alloc] initForURL:url];

		// configure the checker
    	_portChecker.portNumber = 80;
    	_portChecker.portQueryTimeout = 10.0;
    	_portChecker.delegate = self;

		// check the port
		[_portChecker start];
	}

When the check completes the `delegate` receives `portCheckerDidFinishProbing:`.

	- (void)portCheckerDidFinishProbing:(MGSPortChecker *)portChecker
	{
    	switch ([portChecker status]) {
        	case kMGS_PORT_STATUS_NA:
        	break;

        	case kMGS_PORT_STATUS_OPEN:
            	self.externalPort = portChecker.portNumber;
            	self.IPAddressString = portChecker.gatewayAddress;
        	break;

        	case kMGS_PORT_STATUS_CLOSED:
         	break;

        	case kMGS_PORT_STATUS_ERROR:
        	default:
       		break;
    	}
	}

Licence
=======
MIT

Where did it come from?
=======================

MGSPortChecker is derived from the port checker used in the [Transmission](http://www.transmissionbt.com) bit torrent client.