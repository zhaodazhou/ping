//
//  NetworkMonitorManager.h


#import <Foundation/Foundation.h>
#import "NetTraceRoute.h"

@interface NetworkMonitorManager : NSObject<NetTraceRouteDelegate>

+ (NetworkMonitorManager *)shareInstance;

- (void)startMonitorAction:(NSString *)domainName;

@end
