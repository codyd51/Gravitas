#import <CoreMotion/CoreMotion.h>

OBJC_EXTERN NSMutableArray* iconScrollViews;
OBJC_EXTERN NSMutableDictionary* viewPositions;
OBJC_EXTERN NSMutableDictionary* gestRecognizers;

@interface GTController : NSObject {
	NSMutableArray* _affectedViews;
	CMMotionManager* _manager;
	UICollisionBehavior* _collider;
	UIAttachmentBehavior* _attacher;
}
@property (nonatomic, retain) UIDynamicAnimator* animator;
@property (nonatomic, retain) UIDynamicItemBehavior* iconDynamicProperties;
@property (nonatomic, retain) UIGravityBehavior* gravity;
-(id)initWithAffectedViews:(NSArray*)views;
-(void)enqueueAffectedView:(UIView*)view;
-(void)dequeueAffectedView:(UIView*)view;
-(id)affectedViews;
-(BOOL)viewIsAffected:(UIView*)view;
-(void)beginSimulation;
-(void)endSimulation;
-(void)resetIconLayout;
@end