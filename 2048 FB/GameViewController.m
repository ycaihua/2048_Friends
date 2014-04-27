//
//  GameViewController.m
//  2048 FB
//
//  Created by Shuyang Sun on 4/19/14.
//  Copyright (c) 2014 Shuyang Sun. All rights reserved.
//

#import "GameViewController.h"
#import <iAd/iAd.h>
#import "AppDelegate.h"
#import "GameManager+ModelLayer03.h"
#import "History+ModelLayer03.h"
#import "Board+ModelLayer03.h"
#import "Tile+ModelLayer03.h"
#import "Theme.h"
#import "macro.h"

#import "BoardScene.h"
#import "TileSKShapeNode.h"
#import "UIImage+ImageEffects.h"

// Defines for localization
#define STRING_GAME_OVER_LABEL NSLocalizedStringFromTable(@"STRING_GAME_OVER_LABEL", @"GameViewControllerTable", @"Text on Game Over label.")
#define STRING_TRY_AGAIN NSLocalizedStringFromTable(@"STRING_TRY_AGAIN", @"GameViewControllerTable", @"Text on play again button.")

// Constants
const NSTimeInterval kAnimationDuration_Default = SCALED_ANIMATION_DURATION(0.1f);
const NSTimeInterval kAnimationDuration_ScreenBlur = SCALED_ANIMATION_DURATION(1.5f);
const NSTimeInterval kAnimationDuration_ScaleTile = SCALED_ANIMATION_DURATION(1.0f);
const NSTimeInterval kAnimationDuration_MoveTile = SCALED_ANIMATION_DURATION(0.2f);
const NSTimeInterval kAnimationDelay_GameOver = SCALED_ANIMATION_DURATION(0.0f);
const NSTimeInterval kAnimationDuration_TextFade = SCALED_ANIMATION_DURATION(0.5f);
const NSTimeInterval kTextShowDuration = SCALED_ANIMATION_DURATION(5.0f);
const CGFloat kAnimationSpring_Damping = SCALED_ANIMATION_DURATION(0.5f);
const CGFloat kAnimationSpring_Velocity = SCALED_ANIMATION_DURATION(0.4f);

const CGFloat kTileMoveAnimationDurationFraction = 1.5f;

const CGFloat kBoardPanMinDistance = 5.0f;
const CGFloat kLineWidthDefault_iPhone = 8.0f;

const NSUInteger kDefaultContextSavingSwipeNumber = 10;

@interface GameViewController ()

#pragma mark - IBOutlets
@property (weak, nonatomic) IBOutlet UIView *profilePictureView;
@property (weak, nonatomic) IBOutlet UIImageView *profilePictureImageView;
@property (weak, nonatomic) IBOutlet UIView *profilePictureInteractionLayer;
@property (strong, nonatomic) IBOutlet UITapGestureRecognizer *profilePictureTapGestureRecognizer;
@property (strong, nonatomic) IBOutlet UILongPressGestureRecognizer *profilePictureLongPressGestureRecognizer;
@property (weak, nonatomic) IBOutlet UIButton *menuButton;
@property (weak, nonatomic) IBOutlet SKView *boardSKView;
@property (weak, nonatomic) IBOutlet UIView *boardInteractionLayerVIew;
@property (weak, nonatomic) IBOutlet UILabel *messageLabel;
@property (strong, nonatomic) IBOutlet UIPanGestureRecognizer *panGestureRecognizer;

@property (weak, nonatomic) IBOutlet UIView *pauseView;
@property (weak, nonatomic) IBOutlet UIImageView *pauseImageView;
@property (weak, nonatomic) IBOutlet UILabel *pauseLabel;
@property (weak, nonatomic) IBOutlet UIButton *resumeGameButton;
@property (weak, nonatomic) IBOutlet UIButton *shareButton;

#pragma mark - Analyzing Algorithm Property
@property (nonatomic) BoardSwipeGestureDirection direction;
@property (nonatomic) CGFloat width;
@property (nonatomic) CGFloat height;
@property (nonatomic) BOOL analyzed;
@property (nonatomic, assign) BOOL canSwipeToDesiredDirection;

#pragma mark - SKAction for Animation
@property (nonatomic, strong) SKAction *tileMagnifyAction;

#pragma mark - Other Private Properties
@property (strong, nonatomic) Theme *theme;
@property (strong, nonatomic) GameManager *gManager;
@property (nonatomic, strong) AppDelegate *appDelegate;
@property (nonatomic, strong) UIImage *lastFullScreenSnapshot;
@property (nonatomic, assign) CGFloat scaledFraction;

@end

@implementation GameViewController

#pragma mark - Setup Methods
-(void)setup
{
	// Initialization code here...
	
	self.gManager = [GameManager sharedGameManager];
	self.theme = [Theme sharedThemeWithID:self.gManager.currentThemeID];
	self.messageLabel.textAlignment = NSTextAlignmentCenter;
	self.menuButton.titleLabel.textAlignment = NSTextAlignmentCenter;
	self.bestScoreLabel.textAlignment = NSTextAlignmentCenter;
	self.scoreLabel.textAlignment = NSTextAlignmentCenter;
	self.appDelegate = [UIApplication sharedApplication].delegate;
	self.canSwipeToDesiredDirection = YES;
	self.canDisplayBannerAds = YES;
	
	// Setup SKActions
	CGFloat scaleFactor = 1+((self.scene.size.width - 4 * self.theme.tileWidth)/5.0f)/self.theme.tileWidth;
	self.tileMagnifyAction = [SKAction group:@[[SKAction scaleTo:scaleFactor duration:kAnimationDuration_Default * 2],
											   [SKAction moveBy:CGVectorMake(-self.theme.tileWidth*((scaleFactor - 1)/2.0f), -self.theme.tileWidth*((scaleFactor - 1)/2))
																	 duration:kAnimationDuration_Default * 2]]];
}

-(void)awakeFromNib
{
	[self setup];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	[self updateThemeAnimated:NO];
	self.pauseLabel.textAlignment = NSTextAlignmentCenter;
	self.resumeGameButton.titleLabel.textAlignment = NSTextAlignmentCenter;
	self.shareButton.titleLabel.textAlignment = NSTextAlignmentCenter;
	
    // SpriteKit stuff
    SKView * skView = (SKView *)self.boardSKView;
	
    skView.showsFPS = YES;
    skView.showsNodeCount = YES;
    
    // Create and configure the scene.
    self.scene = [BoardScene sceneWithSize:skView.bounds.size andTheme:self.theme];
	if (!self.theme) {
		GameManager *gManager = [GameManager sharedGameManager];
		self.theme = [Theme sharedThemeWithID:gManager.currentThemeID];
	}
	self.scene.theme = self.theme;
    self.scene.scaleMode = SKSceneScaleModeAspectFill;
	self.scene.gameViewController = self;
	
	self.profilePictureImageView.contentMode = UIViewContentModeScaleAspectFill;
	UIImage *profileImage = [Tile tileWithValue:2048].image;
	if (profileImage) {
		self.profilePictureImageView.image = profileImage;
	}

    // Present the scene.
    [skView presentScene:self.scene];
}

-(void)viewDidLayoutSubviews {
	self.width = self.boardSKView.frame.size.width;
	self.height  = self.boardSKView.frame.size.height;

}

-(void)updateThemeAnimated:(BOOL) animated {
	if (animated) {
		[UIView animateWithDuration:kAnimationDuration_ScreenBlur
							  delay:0.0f
							options:UIViewAnimationOptionCurveEaseIn
						 animations:^{
							 [self setThemeDataForViews];
						 } completion:nil];
	} else {
		[self setThemeDataForViews];
	}
}

-(void)setThemeDataForViews {
	// Change the corner radius of views
	self.originalContentView.backgroundColor = self.theme.backgroundColor;
	self.boardSKView.layer.cornerRadius = self.theme.boardCornerRadius;
	self.boardSKView.layer.masksToBounds = YES;
	self.profilePictureView.layer.cornerRadius = self.theme.buttonCornerRadius;
	self.profilePictureView.layer.masksToBounds = YES;
	self.profilePictureImageView.layer.cornerRadius = self.theme.buttonCornerRadius;
	self.profilePictureImageView.layer.masksToBounds = YES;
	self.profilePictureInteractionLayer.layer.cornerRadius = self.theme.buttonCornerRadius;
	self.profilePictureInteractionLayer.layer.masksToBounds = YES;
	self.menuButton.layer.cornerRadius = self.theme.buttonCornerRadius;
	self.bestScoreLabel.layer.cornerRadius = self.theme.buttonCornerRadius;
	self.scoreLabel.layer.cornerRadius = self.theme.buttonCornerRadius;
	self.resumeGameButton.layer.cornerRadius = self.theme.buttonCornerRadius;
	self.resumeGameButton.layer.masksToBounds = YES;
	self.shareButton.layer.cornerRadius = self.theme.buttonCornerRadius;
	self.shareButton.layer.masksToBounds = YES;
	
	// Change the color of views
	self.boardSKView.backgroundColor = self.theme.boardColor;
	self.profilePictureView.backgroundColor = self.theme.tileColors[@(2048)];
	self.resumeGameButton.backgroundColor = self.theme.boardColor;
	self.shareButton.backgroundColor = self.theme.boardColor;
	self.menuButton.backgroundColor = self.theme.tileColors[@(8)];
	self.scoreLabel.backgroundColor = self.theme.tileColors[@(4)];
}

-(BOOL)prefersStatusBarHidden {
	return YES;
}

- (BOOL)shouldAutorotate
{
    return YES;
}

- (NSUInteger)supportedInterfaceOrientations
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        return UIInterfaceOrientationMaskAllButUpsideDown;
    } else {
        return UIInterfaceOrientationMaskAll;
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - IBActions

- (IBAction)menuButtonTapped:(UIButton *)sender {
	
}

- (IBAction)profilePictureTapped:(UITapGestureRecognizer *)sender {
	
	UIGestureRecognizerState state = sender.state;
	if (state == UIGestureRecognizerStateRecognized) {
		
		self.gManager.tileViewType = (int16_t)self.scene.tileType;
		NSArray *allNodes = [self.scene.nodeForIndexes allValues];
		for (TileSKShapeNode *node in allNodes) {
			if (self.scene.tileType == TileTypeImage) {
				[node hideImageAnimated:YES];
			} else if (self.scene.tileType == TileTypeNumber) {
				[node showImageAnimated:YES];
			}
		}
		
		if (self.scene.tileType == TileTypeNumber) {
			self.scene.tileType = TileTypeImage;
		} else if (self.scene.tileType == TileTypeImage) {
			self.scene.tileType = TileTypeNumber;
		}
		self.gManager.tileViewType = (int16_t)self.scene.tileType;
		[self saveContext];
	}
}

- (IBAction)profilePictureBeingHold:(UILongPressGestureRecognizer *)sender {
	if (self.scene.tileType == TileTypeImage) {
		if (sender.state == UIGestureRecognizerStateBegan) { // Animate show number layer
			NSArray *allNodes = [self.scene.nodeForIndexes allValues];
			for (TileSKShapeNode *node in allNodes) {
				[node transparentImageAnimated:YES];
			}
//			self.profilePictureInteractionLayer.backgroundColor = [UIColor colorWithRed:0.0f green:0.0f blue:0.0f alpha:0.5f];
			[UIView animateWithDuration:kAnimationDuration_ImageTransparent
							 animations:^{
								 self.profilePictureImageView.alpha = kAnimationImageTransparencyFraction;
							 }];
		} else if (sender.state == UIGestureRecognizerStateEnded ||
				   sender.state == UIGestureRecognizerStateCancelled ||
				   sender.state == UIGestureRecognizerStateFailed) { // Animate hide number layer
			NSArray *allNodes = [self.scene.nodeForIndexes allValues];
			for (TileSKShapeNode *node in allNodes) {
				[node opaqueImageAnimated:YES];
			}
//			self.profilePictureInteractionLayer.backgroundColor = [UIColor clearColor];
			[UIView animateWithDuration:kAnimationDuration_ImageTransparent
							 animations:^{
								 self.profilePictureImageView.alpha = 1.0f;
							 }];
		}
	}
}

- (IBAction)resumeButtonTapped:(UIButton *)sender {
	if (sender.tag == 0) { // If it's try again button
		for (NSValue *value in [self.scene.positionsForNodes allKeys]) {
			SKShapeNode *node = [value nonretainedObjectValue];
			[node removeFromParent];
		}
		[self enableButtonAndGestureInteractions:NO];
		[UIView animateWithDuration:kAnimationDuration_Default
						 animations:^{
							 self.pauseView.alpha = 0.0f;
						 }
						 completion:^(BOOL finished) {
							 [self.scene initializePropertyLists];
							 self.scene.gamePlaying = YES;
							 self.scene.score = 0;
							 self.scene.board = [Board initializeNewBoard];
							 self.scene.history = self.scene.board.boardHistory;
							 [self.scene startGameFromBoard:self.scene.board animated:YES];
							 [self enableButtonAndGestureInteractions:YES];
						 }];
	}
}

- (IBAction)shareButtonTapped:(UIButton *)sender {
	self.scene.paused = NO;
	self.boardSKView.paused = NO;
}

- (IBAction)handlePan:(UIPanGestureRecognizer *)sender {
	UIGestureRecognizerState state = sender.state;
	
	if (state == UIGestureRecognizerStateBegan || state == UIGestureRecognizerStatePossible) {
		self.analyzed = NO;
		self.direction = BoardSwipeGestureDirectionNone;
	} else if (state == UIGestureRecognizerStateChanged) {
		CGPoint translate = [sender translationInView:self.boardSKView];
		CGFloat x = translate.x;
		CGFloat y = translate.y;
		// Set the direction
		if (fabs(x) >= 5 || fabs(y) >= 5) {
			if (self.direction == BoardSwipeGestureDirectionNone) {
				if (fabs(x) > fabs(y)) { // Left or Right
					if (x > 0) {
						self.direction = BoardSwipeGestureDirectionRight;
					} else {
						self.direction = BoardSwipeGestureDirectionLeft;
					}
				} else { // Up or Down
					if (y > 0) {
						self.direction = BoardSwipeGestureDirectionDown;
					} else {
						self.direction = BoardSwipeGestureDirectionUp;
					}
				}
			}
			
			if (self.direction != BoardSwipeGestureDirectionNone && !self.analyzed) {
				self.analyzed = YES;
#ifdef DEBUG
				NSDate *start = [NSDate date];
#endif
				self.canSwipeToDesiredDirection = [self.scene analyzeTilesForSwipeDirection:self.direction completion:nil];
#ifdef DEBUG
				NSDate *end = [NSDate date];
				NSLog(@"Took %f seconds analyzing swiping %@", [end timeIntervalSinceDate:start], [Board directionStringFromDirection:self.direction]);
#endif
				if (self.canSwipeToDesiredDirection == NO) {
					self.direction = BoardSwipeGestureDirectionNone;
				}
			}
			
			if (self.direction != BoardSwipeGestureDirectionNone && self.analyzed) {
				CGFloat fraction = 0.0f;
				if  ((self.direction == BoardSwipeGestureDirectionLeft && x < 0) ||
					 (self.direction == BoardSwipeGestureDirectionRight && x > 0)) {
					fraction = fabs(x/(self.width/2.0f));
				} else if ((self.direction == BoardSwipeGestureDirectionUp && y < 0) ||
						   (self.self.direction == BoardSwipeGestureDirectionDown && y > 0)) {
					fraction = fabs(y/(self.height/2.0f));
				}
				// If we can swipe to that direction, swipe it
				if (self.canSwipeToDesiredDirection) {
										[self.scene swipeToDirection:self.direction withFraction:fraction];
				// If we cannot swipe to that direction, do the animation.
				} else {
					[self.scene animateTileScaleToDirection:self.direction withFraction:fraction];
				}
			}
		}
	} else if (state == UIGestureRecognizerStateEnded ||
			   state == UIGestureRecognizerStateCancelled ||
			   state == UIGestureRecognizerStateFailed) {
		// If the board can be swiped previously:
		if (self.canSwipeToDesiredDirection) {
			CGPoint translate = [sender translationInView:self.boardSKView];
			if ((self.direction == BoardSwipeGestureDirectionLeft && translate.x < 0) ||
				(self.direction == BoardSwipeGestureDirectionRight && translate.x > 0)) {
				CGFloat f = fabs(translate.x/(self.width/2.0f));
				f = MIN(1.0f, f);
				f = MAX(0.0f, f);
				f = 1.0f - f;
				// If cancelled or failed: reverse it
				if (fabs(translate.x/(self.width/2.0f)) > 0.5 && state == UIGestureRecognizerStateEnded) {
					[self.scene finishSwipeAnimationWithDuration:kAnimationDuration_Default*f * kTileMoveAnimationDurationFraction];
					[self saveContext];
				} else {
					[self.scene reverseSwipeAnimationWithDuration:kAnimationDuration_Default*f * kTileMoveAnimationDurationFraction];
				}
			} else if ((self.direction == BoardSwipeGestureDirectionUp && translate.y < 0) ||
					   (self.direction == BoardSwipeGestureDirectionDown && translate.y > 0)) {
				CGFloat f = fabs(translate.y/(self.height/2.0f));
				f = MIN(1.0f, f);
				f = MAX(0.0f, f);
				f = 1-f;
				if (fabs(translate.y/(self.height/2.0f)) > 0.5 && state == UIGestureRecognizerStateEnded) {
					[self.scene finishSwipeAnimationWithDuration:kAnimationDuration_Default* f * kTileMoveAnimationDurationFraction];
					[self saveContext];
				} else {
					[self.scene reverseSwipeAnimationWithDuration:kAnimationDuration_Default* f * kTileMoveAnimationDurationFraction];
				}
			}
		// If we can't swipe to a direction, but we have a direction:
		} else if (self.direction != BoardSwipeGestureDirectionNone) {
			// Restore the scale animation
			[self.scene reverseTileScaleAnimationWithDuration:kAnimationDuration_Default];
		}
		
		self.analyzed = NO;
		self.direction = BoardSwipeGestureDirectionNone;
		self.canSwipeToDesiredDirection = YES;
	}
}

#pragma mark - Helper Methods

-(void)saveContext {
	dispatch_queue_t contextSavingQueue = dispatch_queue_create("Context Saving Queue", NULL);
	dispatch_async(contextSavingQueue, ^{
		[self.appDelegate saveContext];
	});
}

-(void)enableGestureRecognizers:(BOOL)enabled {
	self.panGestureRecognizer.enabled = enabled;
}

-(void)enableButtonAndGestureInteractions:(BOOL)enabled {
	[self enableGestureRecognizers:enabled];
	self.profilePictureTapGestureRecognizer.enabled = enabled;
	self.profilePictureLongPressGestureRecognizer.enabled = enabled;
}

-(void)showGameEndView {
	// !!!: && self.mode == BoardViewControllerModePlaying
	if (self.scene.gamePlaying == NO) {
		// Disable some user interactions.
		[self enableButtonAndGestureInteractions:NO];
		
		// Task a snapshot for sharing
		UIGraphicsBeginImageContextWithOptions(self.originalContentView.bounds.size, YES, 0.0f);
		[self.boardSKView drawViewHierarchyInRect:self.originalContentView.bounds afterScreenUpdates:YES];
		self.lastFullScreenSnapshot = UIGraphicsGetImageFromCurrentImageContext();
		UIGraphicsEndImageContext();
		
		self.pauseView.alpha = 0.0f;
		[self.boardSKView bringSubviewToFront:self.pauseView];
		[self.boardSKView bringSubviewToFront:self.pauseImageView];
		[self.pauseView bringSubviewToFront:self.pauseLabel];
		[self.pauseView bringSubviewToFront:self.shareButton];
		[self.pauseView bringSubviewToFront:self.resumeGameButton];
		self.pauseLabel.tag = 0;
		self.pauseLabel.text = STRING_GAME_OVER_LABEL;
		self.resumeGameButton.tag = 0; // 0 Represents "play again"
		self.resumeGameButton.titleLabel.text = STRING_TRY_AGAIN;
		__block UIImage *snapshot;
		NSArray *allTileViewsWithoutNewTile = [self.scene.positionsForNodes allKeys];
		NSMutableArray *allTileViews = [NSMutableArray arrayWithArray:allTileViewsWithoutNewTile];
		NSValue *newNSValueTile = [[self.scene.positionForNewRandomTile allKeys] lastObject];
		if (newNSValueTile) {
			[allTileViews addObject:newNSValueTile];
		}
		// Disable gesture recognizers for now
		[self enableGestureRecognizers:NO];
		NSUInteger count = 0;
		NSUInteger size = [allTileViews count];
		void (^completion)() = nil;
		for (NSValue *value in allTileViews) {
			TileSKShapeNode *tile = [value nonretainedObjectValue];
			count++;
			if (count >= size) {
				completion = ^void() {
					if (!snapshot) {
						UIGraphicsBeginImageContextWithOptions(self.boardSKView.bounds.size, YES, 0.0f);
						[self.boardSKView drawViewHierarchyInRect:self.boardSKView.bounds afterScreenUpdates:YES];
						snapshot = UIGraphicsGetImageFromCurrentImageContext();
						UIGraphicsEndImageContext();
						
						UIColor *blurtTintColor = self.theme.tileColors[@(2048)];
						CGFloat red, green, blue, alpha;
						[blurtTintColor getRed:&red green:&green blue:&blue alpha:&alpha];
						blurtTintColor = [UIColor colorWithRed:red green:green blue:blue alpha:0.1f];
						snapshot = [snapshot applyBlurEffectWithRadius:3.0f tintColor:blurtTintColor];
						self.pauseImageView.image = snapshot;
						
						[UIView animateWithDuration:kAnimationDuration_ScreenBlur
											  delay:0.0f
											options:UIViewAnimationOptionCurveEaseInOut
										 animations:^{
											 self.pauseView.alpha = 1.0f;
										 }
										 completion:^(BOOL finished) {
											 [self.boardSKView bringSubviewToFront:self.pauseView];
										 }];
						[self enableButtonAndGestureInteractions:YES];
					}
				};
			}
			[tile runAction:self.tileMagnifyAction completion:completion];
		}
		[self saveContext];
	} else {
		self.pauseView.alpha = 0.0f;
	}
}

@end
