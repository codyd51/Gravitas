#import "GTController.h"
#import "DebugLog.h"
#import <CoreMotion/CoreMotion.h>

@interface SBIconListView : UIView
@end
@interface SBRootFolder : NSObject
@end
@interface SBIcon : NSObject
@end
@interface SBIconView : UIView
@property (nonatomic, retain) SBIcon* icon;
@end

static SBIconListView *IDWListViewForIcon(SBIcon *icon) {
	SBIconController *controller = [%c(SBIconController) sharedInstance];
	SBRootFolder *rootFolder = [controller valueForKeyPath:@"rootFolder"];
	NSIndexPath *indexPath = [rootFolder indexPathForIcon:icon];
	SBIconListView *listView = nil;
	[controller getListView:&listView folder:NULL relativePath:NULL forIndexPath:indexPath createIfNecessary:YES];
	return listView;
}

@implementation GTController

-(id)initWithAffectedViews:(NSArray*)views {
	if (self = [super init]) {
		[_affectedViews removeAllObjects];
		_affectedViews = [[NSMutableArray alloc] initWithArray:views ? views : nil];

		//set up animator
		_animator = [[UIDynamicAnimator alloc] initWithReferenceView:[[UIApplication sharedApplication] keyWindow]];

    	//make it subject to gravity
    	_gravity = [[UIGravityBehavior alloc] initWithItems:views];
		[_animator addBehavior:_gravity];

		//change gravity to device orientation
		_manager = [[CMMotionManager alloc] init];

    	//set up collisions with edge of screen
    	_collider = [[UICollisionBehavior alloc] initWithItems:views];
		_collider.translatesReferenceBoundsIntoBoundary = YES;
		[_animator addBehavior:_collider];
	}
	return self;
}
-(void)enqueueAffectedView:(UIView*)view {
	[_gravity addItem:view];
	[_collider addItem:view];
	[_affectedViews addObject:view];
}
-(void)dequeueAffectedView:(UIView*)view {
	[_gravity removeItem:view];
	[_collider removeItem:view];
	[_affectedViews removeObject:view];
}
-(id)affectedViews {
	return _affectedViews;
}
-(BOOL)viewIsAffected:(UIView*)view {
	return [_affectedViews containsObject:view];
}

-(void)beginSimulation {
	[_animator addBehavior:_gravity];
	[_animator addBehavior:_collider];

	if (_manager.deviceMotionAvailable) {
    	_manager.deviceMotionUpdateInterval = 0.01f;
    	[_manager startDeviceMotionUpdatesToQueue:[NSOperationQueue mainQueue] withHandler:^(CMDeviceMotion *data, NSError *error) {
        	CMAcceleration gravity = data.gravity;
    		dispatch_async(dispatch_get_main_queue(), ^{
        		self.gravity.gravityDirection = CGVectorMake(gravity.x, -gravity.y);
    		});
    	}];

    	//stop the user from scrolling past this page
    	for (UIScrollView* scrollView in iconScrollViews) {
    		//invert whatever theyre at now
    		//should I just set them to NO/YES?
    		scrollView.scrollEnabled = NO;
    	}
	}
}
-(void)endSimulation {
	[_manager stopDeviceMotionUpdates];
	[_animator removeAllBehaviors];

	//allow the user to scroll again
    for (UIScrollView* scrollView in iconScrollViews) {
    	//invert whatever theyre at now
    	//should I just set them to NO/YES?
    	scrollView.scrollEnabled = YES;
    }
}
-(void)resetIconLayout {
	for (NSValue* value in gestRecognizers) {
		SBIconView* view = (SBIconView*)value.nonretainedObjectValue;
		NSArray* recs = [gestRecognizers objectForKey:value];
		for (UIGestureRecognizer* rec in recs) {
			[view addGestureRecognizer:rec];
		}
	}

	SBIconView* view = [_affectedViews objectAtIndex:0];
	SBIconListView *listView = IDWListViewForIcon(view.icon);
	[listView setIconsNeedLayout];
	[listView layoutIconsIfNeeded:0.5 domino:YES];
	[listView layoutIconsNow];

	//view.transform = CGAffineTransformMakeRotation(M_PI_2);

	DebugLog(@"_affectedViews = %@", _affectedViews);
	DebugLog(@"view = %@", view);
	DebugLog(@"listView = %@", listView);

	for (UIView* view in _affectedViews) {
		DebugLog(@"transform = %@", NSStringFromCGAffineTransform(view.transform));
		view.transform = CGAffineTransformIdentity;
		DebugLog(@"transform = %@", NSStringFromCGAffineTransform(view.transform));
	}

	[_affectedViews removeAllObjects];
	[viewPositions removeAllObjects];
}

@end
