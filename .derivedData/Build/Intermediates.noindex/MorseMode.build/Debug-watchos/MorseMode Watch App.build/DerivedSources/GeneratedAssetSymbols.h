#import <Foundation/Foundation.h>

#if __has_attribute(swift_private)
#define AC_SWIFT_PRIVATE __attribute__((swift_private))
#else
#define AC_SWIFT_PRIVATE
#endif

/// The resource bundle ID.
static NSString * const ACBundleID AC_SWIFT_PRIVATE = @"com.Ishauna.MorseModeTest.watchkitapp";

/// The "Neon" asset catalog color resource.
static NSString * const ACColorNameNeon AC_SWIFT_PRIVATE = @"Neon";

/// The "Header" asset catalog image resource.
static NSString * const ACImageNameHeader AC_SWIFT_PRIVATE = @"Header";

/// The "Radar" asset catalog image resource.
static NSString * const ACImageNameRadar AC_SWIFT_PRIVATE = @"Radar";

#undef AC_SWIFT_PRIVATE
