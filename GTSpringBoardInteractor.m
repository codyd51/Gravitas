#import "GTSpringBoardInteractor.h"

@implementation GTSpringBoardInteractor
+(instancetype)sharedInstance {
	static dispatch_once_t once;
    static GTSpringBoardInteractor *sharedInstance;
    dispatch_once(&once, ^{
    	sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}
-(id)init {
	if (self = [super init]) {
		_iconScrollViews = [[NSMutableArray alloc] init];
		_viewPositions = [[NSMutableDictionary alloc] init];
		_gestureRecognizers = [[NSMutableDictionary alloc] init];
	}
	return self;
}
@end