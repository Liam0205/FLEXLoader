#include <UIKit/UIKit.h>
#include <objc/runtime.h>
#include <dlfcn.h>

@interface FLEXManager

+ (instancetype)sharedManager;
- (void)showExplorer;

@end


@interface FLEXLoader: NSObject
@end

@implementation FLEXLoader

+ (instancetype)sharedInstance {
	static dispatch_once_t onceToken;
	static FLEXLoader *loader;
	dispatch_once(&onceToken, ^{
		loader = [[FLEXLoader alloc] init];
	});	

	return loader;
}

- (void)show {
	[[objc_getClass("FLEXManager") sharedManager] showExplorer];
}

@end

%ctor {
	@autoreleasepool {
		NSString *dylibPath = @"/Library/Application Support/FLEXLoader/libFLEX.dylib";
		if (![[NSFileManager defaultManager] fileExistsAtPath:dylibPath]) {
			HBLogDebug(@"FLEXLoader dylib file not found: %@", dylibPath);
			return;
		}

		NSDictionary *pref = [NSDictionary dictionaryWithContentsOfFile:@"/User/Library/Preferences/com.todayios-cydia.flexloader.plist"];
		NSString *bundleIdentifier = [[NSBundle mainBundle] bundleIdentifier];
		NSArray *selectedApplications = [pref objectForKey:@"selectedApplications"];

		BOOL enabled = [selectedApplications containsObject:bundleIdentifier];
		HBLogDebug(@"FLEXLoader selectedApplications:%@ contains %@", selectedApplications, bundleIdentifier);

		if (enabled) {
			void *handle = dlopen([dylibPath UTF8String], RTLD_NOW);
			if (handle == NULL) {
				char *error = dlerror();
				HBLogDebug(@"Load FLEXLoader dylib fail: %s", error);
				return;
			} 

			[[NSNotificationCenter defaultCenter] addObserver:[FLEXLoader sharedInstance]
											selector:@selector(show)
												name:UIApplicationDidBecomeActiveNotification
												object:nil];
		}
	}
}
