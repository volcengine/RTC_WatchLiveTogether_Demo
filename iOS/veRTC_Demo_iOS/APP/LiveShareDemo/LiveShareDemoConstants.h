//
//  LiveDemoConstants.h
//  Pods
//
//

#ifndef LiveDemoConstants_h
#define LiveDemoConstants_h

#import "LiveShareDataManager.h"
#import "LiveShareMediaModel.h"

#define HomeBundleName @"LiveShareDemo"

#define TTAPPID @"314168"
#define TTLicenseName @"ttsdk_premium_debug"

#define veString(key, ...)                                                     \
  ({                                                                           \
    NSString *bundlePath =                                                     \
        [[[NSBundle mainBundle] pathForResource:HomeBundleName                 \
                                         ofType:@"bundle"]                     \
            stringByAppendingPathComponent:@"Localizable.bundle"];             \
    NSBundle *resourceBundle = [NSBundle bundleWithPath:bundlePath];           \
    NSString *string = [resourceBundle localizedStringForKey:key               \
                                                       value:nil               \
                                                       table:nil];             \
    string == nil ? key : string;                                              \
  })

#endif /* LiveDemoConstants_h */
