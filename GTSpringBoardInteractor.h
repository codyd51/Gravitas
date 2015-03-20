@interface GTSpringBoardInteractor : NSObject {}
@property (nonatomic, retain) NSMutableArray* iconScrollViews;
@property (nonatomic, retain) NSMutableDictionary* viewPositions;
@property (nonatomic, retain) NSMutableDictionary* gestureRecognizers; 
@property (nonatomic) BOOL isActive;
+(instancetype)sharedInstance;
-(id)init;
@end