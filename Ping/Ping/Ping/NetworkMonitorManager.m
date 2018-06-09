//
//  NetworkMonitorManager.m


//#import <UIKit/UIKit.h>
#import "sys/time.h"
#import "NetworkMonitorManager.h"
#import "STDPingServices.h"
#import "NetGetAddress.h"
#include <dns_sd.h>

//字符串是否为空
#define IsStrEmpty(_ref)    (((_ref) == nil) || ([(_ref) isEqual:[NSNull null]]) ||([(_ref)isEqualToString:@""]))

static NetworkMonitorManager *g_shareinstance;

@interface NetworkMonitorManager()

@property (nonatomic, strong) NetTraceRoute *traceRoute;
@property (nonatomic, strong) STDPingServices    *pingServices;
@property (nonatomic, strong) NSString *hostName;

@end

@implementation NetworkMonitorManager

+ (NetworkMonitorManager *)shareInstance
{
    if(!g_shareinstance)
    {
        g_shareinstance = [[NetworkMonitorManager alloc] init];
    }
    return g_shareinstance;
}

- (void)startMonitorAction:(NSString *)domainName
{
    self.hostName = domainName;
    [self getDomainFullName];
}

- (void)getDomainFullName
{
    DNSServiceRef sdRef;
    DNSServiceErrorType err;
    void *context = (__bridge void *)(self);
    DNSServiceQueryRecord(&sdRef, 0, 0,
                          [_hostName cStringUsingEncoding:[NSString defaultCStringEncoding]],
                          kDNSServiceType_A,
                          kDNSServiceClass_IN,
                          callBack,
                          context);

    // This stuff is necessary so we don't hang forever if there are no results
    int dns_sd_fd = DNSServiceRefSockFD(sdRef);
    int nfds = dns_sd_fd + 1;
    fd_set readfds;
    struct timeval tv;
    int result;
    int timeOut = 1; // Timeout in seconds

    FD_ZERO(&readfds);
    FD_SET(dns_sd_fd, &readfds);
    tv.tv_sec = timeOut;
    tv.tv_usec = 0;

    result = select(nfds, &readfds, (fd_set*)NULL, (fd_set*)NULL, &tv);
    if (result > 0)
    {
        if(FD_ISSET(dns_sd_fd, &readfds))
        {
            err = DNSServiceProcessResult(sdRef);
            if (err != kDNSServiceErr_NoError)
            {
                [self pingActionWithHostName:_hostName];
            }
        }
    }
    else {
        [self pingActionWithHostName:_hostName];
    }
    DNSServiceRefDeallocate(sdRef);
}

static void callBack(DNSServiceRef sdRef,
                     DNSServiceFlags flags,
                     uint32_t interfaceIndex,
                     DNSServiceErrorType errorCode,
                     const char *fullname,
                     uint16_t rrtype,
                     uint16_t rrclass,
                     uint16_t rdlen,
                     const void *rdata,
                     uint32_t ttl,
                     void *context)
{
    // do your magic here...
    NSString *fullHostName = [NSString stringWithFormat:@"%s", fullname];
    NetworkMonitorManager *obj = (__bridge NetworkMonitorManager *) context;
    [obj pingActionWithHostName:fullHostName];
}

- (void)pingActionWithHostName:(NSString *)hostname
{
    __weak NetworkMonitorManager *weakSelf = self;
    self.pingServices = [STDPingServices startPingAddress:hostname callbackHandler:^(STDPingItem *pingItem, NSArray *pingItems)
    {
        if (pingItem.status != STDPingStatusFinished)
        {
            NSLog(@"result %@",pingItem.description);
        }
        else
        {
            NSLog(@"ping statistics %@",[STDPingItem statisticsWithPingItems:pingItems]);
            weakSelf.pingServices = nil;
            STDPingItem *tmpPingItem = [pingItems firstObject];
            [weakSelf traceRouteActionFiredWithIP:tmpPingItem.IPAddress];
        }
    }];
}

- (void)traceRouteActionFiredWithIP:(NSString *)ipAddress
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        if (IsStrEmpty(ipAddress))
        {
            [self appendRouteLog:[NSString stringWithFormat:@"Could Not TraceRoute %@",_hostName]];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self getLocalDNSServers];
            });
            return ;
        }
        [self appendRouteLog:[NSString stringWithFormat:@"TraceRoute %@(%@)",_hostName,ipAddress]];
        [_traceRoute doTraceRoute:ipAddress];
        [_traceRoute stopTrace];
    });

}

- (void)getLocalDNSServers
{
    NSArray *dnsArr = [NetGetAddress outPutDNSServers];
    for (NSString *dnsIP in dnsArr)
    {
         NSLog(@"NDS %@",dnsIP);
    }
}

#pragma mark-YFBNetTraceRouteDelegate
-(void)appendRouteLog:(NSString *)routeLog
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if(routeLog)
        {
            NSLog(@"routeLog %@",routeLog);
        }
    });
}

-(void)traceRouteDidEnd
{
    [self appendRouteLog:@"TraceRoute Over"];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self getLocalDNSServers];
    });
}

@end
