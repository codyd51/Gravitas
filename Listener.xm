#import "libactivator.h"
#import "GTController.h"
#import "DebugLog.h"

NSMutableArray* iconScrollViews;
NSMutableDictionary* viewPositions;
BOOL isActive;

#pragma mark - Listener

@interface GravitasListener : NSObject<LAListener> {
	GTController* _controller;
}
@end

@interface SBRootIconListView : NSObject
-(NSArray*)icons;
@end
@interface SBIconController : NSObject
+(id)sharedInstance;
-(SBRootIconListView*)currentRootIconList;
@end
@interface SBIconViewMap : NSObject
+(id)sharedInstance;
-(id)mappedIconViewForIcon:(id)icon;
@end

@implementation GravitasListener

GravitasListener* globalSelf;

-(void)activator:(LAActivator *)activator receiveEvent:(LAEvent *)event {
	DebugLog(@"Listener accepted");

	if (!viewPositions) viewPositions = [[NSMutableDictionary alloc] init];

	if (!_controller) _controller = [[GTController alloc] initWithAffectedViews:nil];

	if (!isActive) {
		DebugLog(@"Started simulation");
		NSArray* icons = [[[%c(SBIconController) sharedInstance] currentRootIconList] icons];
		NSMutableArray* iconViews = [[NSMutableArray alloc] init];

		SBIconViewMap *iconMap = [%c(SBIconViewMap) homescreenMap];
		for (id icon in icons) {
			UIView* view = [iconMap mappedIconViewForIcon:icon];
			[iconViews addObject:view];
			[_controller enqueueAffectedView:view];

			//NOTE
			//-layoutIconsIfNeeded doesn't seem to be working, for some reason
			//so, we save each icon's position before modifying it
			[viewPositions setObject:[NSValue valueWithCGRect:view.frame] forKey:[NSValue valueWithNonretainedObject:view]];
		}
		[_controller beginSimulation];
		isActive = YES;
	}
	else {
		DebugLog(@"Ended simulation");
		[_controller endSimulation];
		[_controller resetIconLayout];
		isActive = NO;
	}
}

+(void)load {
	if ([[LAActivator sharedInstance] isRunningInsideSpringBoard]) {
		globalSelf = [self new];
		[[LAActivator sharedInstance] registerListener:globalSelf forName:@"com.phillipt.gravitas"];
	}
}
@end

#pragma mark - Hooks

%ctor {
	iconScrollViews = [[NSMutableArray alloc] init];
}

%hook SBIconScrollView

-(id)init {
	if ((self = %orig)) {
		if (![iconScrollViews containsObject:self]) {
			[iconScrollViews addObject:self];
		}
	}
	return self;
}

%end

%hook SBIconView
/*
- (void)layoutSubviews {
	if (![iconViews containsObject:self]) {
		[iconViews addObject:self];
	}
	%orig;
}
*/
-(id)initWithDefaultSize {
	if ((self = %orig)) {
		UIPanGestureRecognizer* pgr = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
   		[self addGestureRecognizer:pgr];
	}
	return self;
}
-(void)handlePan:(UIPanGestureRecognizer*)pgr {
   if (pgr.state == UIGestureRecognizerStateChanged) {
      CGPoint center = pgr.view.center;
      CGPoint translation = [pgr translationInView:pgr.view];
      center = CGPointMake(center.x + translation.x, 
                           center.y + translation.y);
      pgr.view.center = center;
      [pgr setTranslation:CGPointZero inView:pgr.view];
   }
}
%end
