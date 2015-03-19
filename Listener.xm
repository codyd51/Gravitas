#import "libactivator.h"
#import "GTController.h"
#import "DebugLog.h"

NSMutableArray* iconScrollViews;
NSMutableDictionary* viewPositions;
NSMutableDictionary* gestRecognizers;
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
	if (!gestRecognizers) gestRecognizers = [[NSMutableDictionary alloc] init];

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

			NSArray* recs = view.gestureRecognizers;
			if (![gestRecognizers containsObject:recs]) {
				[gestRecognizers setObject:recs forKey:[NSValue valueWithNonretainedObject:view]];
			}
			for (UIGestureRecognizer* rec in recs) {
				[view removeGestureRecognizer:rec];
			}

			UIPanGestureRecognizer* pgr = [[UIPanGestureRecognizer alloc] initWithTarget:_controller action:@selector(handlePan:)];
   			[view addGestureRecognizer:pgr];

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
		[_controller prepareForReuse];
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

/*
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
-(BOOL)scrollEnabled { return YES; }
-(BOOL)showsHorizontalScrollIndicator { return YES; }
-(BOOL)showsVerticalScrollIndicator { return YES; }

%end

@interface SBIconListView : UIView
- (void)setAssociatedObject:(id)object;
- (id)associatedObject;
@end

BOOL hasSetAssociatedObject = NO;

%hook SBIconListView
-(id)initWithModel:(id)arg1 orientation:(long long)arg2 viewMap:(id)arg3 {
	UIScrollView* scrollView;
	if ((self = %orig)) {
		CGRect mainFrame = [[UIApplication sharedApplication] keyWindow].frame;
		UIScrollView* scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(self.frame.origin.x, 0, 100, 5562)];

		[self addSubview:scrollView];
		[self setAssociatedObject:scrollView];
	}
	return self;
}
-(void)addSubview:(UIView*)view {
	//we only want this to run if we haven't already set the associated object
	//else, the scroll view would be adding it to itself
	if (!hasSetAssociatedObject) {
		[(UIView*)[self associatedObject] addSubview:view];
	}
	else %orig;
}

%new
- (void)setAssociatedObject:(id)object {
    objc_setAssociatedObject(self, @selector(associatedObject), object, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    hasSetAssociatedObject = YES;
}
%new
- (id)associatedObject {
    return objc_getAssociatedObject(self, @selector(associatedObject));
}
%end
*/
/*
%hook SBIconListView
-(CGRect)frame {
	CGRect mainFrame = [[UIApplication sharedApplication] keyWindow].frame;
	return CGRectMake(0, 0, mainFrame.size.width, mainFrame.size.height*2);
}

-(void)setFrame:(CGRect)frame {
	CGRect mainFrame = [[UIApplication sharedApplication] keyWindow].frame;
	%orig(CGRectMake(frame.origin.x, 0, mainFrame.size.width, mainFrame.size.height*2));
}
%end
*/
/*
%hook SBIconView
/*
- (void)layoutSubviews {
	if (![iconViews containsObject:self]) {
		[iconViews addObject:self];
	}
	%orig;
}
**
%new
-(void)handlePan:(UIPanGestureRecognizer*)pgr {
   	if (pgr.state == UIGestureRecognizerStateChanged) {
    	CGPoint center = pgr.view.center;
     	CGPoint translation = [pgr translationInView:pgr.view];
     	center = CGPointMake(center.x + translation.x, center.y + translation.y);
    	pgr.view.center = center;
      //[pgr setTranslation:CGPointZero inView:pgr.view];
    }
}
%end
*/
