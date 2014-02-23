//
//  MainViewController.m
//  WPiOSPasscodeLock
//
//  Created by Basar Akyelli on 2/14/14.
//  Copyright (c) 2014 Basar Akyelli. All rights reserved.
//

#import "PasscodeViewController.h"
#import "PasscodeManager.h" 
#import "PasscodeCircularButton.h"
#import "PasscodeCircularView.h" 

static NSString * const EnterPasscodeText = @"Enter Passcode";
static NSString * const ReEnterPasscodeText = @"Re-enter your new Passcode";
static NSString * const EnterCurrentPasscodeText = @"Enter your old Passcode";
static NSString * const IncorrectPasscodeText = @"Incorrect Passcode";
static NSString * const PasscodesDidNotMatchText = @"Passcodes did not Match";
static NSString * const DeleteButtonText = @"Delete";
static NSString * const CancelButtonText = @"Cancel";

static CGFloat const PasscodeButtonSize = 75;
static CGFloat const PasscodeButtonPaddingHorizontal = 20;
static CGFloat const PasscodeButtonPaddingVertical = 10;

static CGFloat const PasscodeEntryViewSize = 15;
static NSInteger const PasscodeDigitCount = 4;

typedef enum PasscodeWorkflowStep : NSUInteger {
    WorkflowStepOne,
    WorkflowStepSetupPasscodeEnteredOnce,
    WorkflowStepSetupPasscodeEnteredTwice,
    WorkflowStepSetupPasscodesDidNotMatch,
    WorkflowStepChangePasscodeVerified,
    WorkflowStepChangePasscodeNotVerified,
} PasscodeWorkflowStep;

@interface PasscodeViewController ()

@property (strong, nonatomic) UILabel *lblInstruction;
@property (strong, nonatomic) UIButton *btnCancelOrDelete;
@property (strong, nonatomic) UILabel *lblError;
@property (strong, nonatomic) NSString *passcodeFirstEntry;
@property (strong, nonatomic) NSString *passcodeEntered;
@property (strong, nonatomic) NSMutableArray *passcodeEntryViews;
@property (strong, nonatomic) UIView *passcodeEntryViewsContainerView;
@property (strong, nonatomic) UIImageView *backgroundImageView;
@property (strong, nonatomic) NSMutableArray *passcodeButtons;
@property (assign) NSInteger numberOfDigitsEntered;

@property (assign) PasscodeType passcodeType;
@property (assign) PasscodeWorkflowStep currentWorkflowStep;

@end


@implementation PasscodeViewController

#pragma mark - 
#pragma mark - Lifecycle Methods

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self generateView];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
}

-(id) initWithPasscodeType:(PasscodeType)type withDelegate:(id<PasscodeViewControllerDelegate>)delegate
{
    self = [super init];
    
    if(self)
    {
        _currentWorkflowStep = WorkflowStepOne;
        _passcodeType = type;
        _delegate = delegate;
    }
    return self;
}

#pragma mark -
#pragma mark - Event Handlers

-(void)cancelOrDeleteBtnPressed:(id)sender
{
    if(self.btnCancelOrDelete.tag == 1){
        [self.delegate passcodeSetupCancelled];
    }
    else if(self.btnCancelOrDelete.tag == 2)
    {
        NSInteger currentPasscodeLength = self.passcodeEntered.length;
        PasscodeCircularView *pcv = self.passcodeEntryViews[currentPasscodeLength-1];
        [pcv clear];
        self.numberOfDigitsEntered--;
        self.passcodeEntered = [self.passcodeEntered substringToIndex:currentPasscodeLength-1];
        if(self.numberOfDigitsEntered == 0){
            self.btnCancelOrDelete.hidden = YES;
            [self enableCancelIfAllowed];
            self.lblError.hidden = YES;
        }
    }
}

-(void) passcodeBtnPressed:(PasscodeCircularButton *)button
{
    
    if(self.numberOfDigitsEntered < PasscodeDigitCount)
    {
        NSInteger tag = button.tag;
        NSString *tagStr = [[NSNumber numberWithInteger:tag] stringValue];
        self.passcodeEntered = [NSString stringWithFormat:@"%@%@", self.passcodeEntered, tagStr];
        PasscodeCircularView *pcv = self.passcodeEntryViews[self.numberOfDigitsEntered];
        [pcv fill];
        self.numberOfDigitsEntered++;
        
        if(self.numberOfDigitsEntered == 1){
            self.lblError.hidden = YES; 
            [self enableDelete];
        }
        if(self.numberOfDigitsEntered == PasscodeDigitCount)
        {
            [self evaluatePasscodeEntry];
        }
    }
}

#pragma mark -
#pragma mark - Layout Methods

- (NSUInteger)supportedInterfaceOrientations
{
    UIUserInterfaceIdiom interfaceIdiom = [[UIDevice currentDevice] userInterfaceIdiom];
    if (interfaceIdiom == UIUserInterfaceIdiomPad) return UIInterfaceOrientationMaskAll;
    if (interfaceIdiom == UIUserInterfaceIdiomPhone) return UIInterfaceOrientationMaskPortrait | UIInterfaceOrientationMaskPortraitUpsideDown;
    
    return UIInterfaceOrientationMaskAll;
}
-(void)viewWillLayoutSubviews
{
    [self buildLayout];
}

- (void)generateView
{
    [self createButtons];
    [self createPasscodeEntryView];
    [self buildLayout];
    [self updateLayoutBasedOnWorkflowStep];
    
    [self.view setBackgroundColor:[PasscodeManager sharedManager].backgroundColor];
    [self applyBackgroundImage];
    
}
-(void)createButtons
{
    self.passcodeButtons = [NSMutableArray new];
    CGRect initialFrame = CGRectMake(0, 0, PasscodeButtonSize, PasscodeButtonSize);
    
    PasscodeButtonStyleProvider *styleProvider = [PasscodeManager sharedManager].buttonStyleProvider;
    BOOL styleForAllButtonsExists = [styleProvider styleExistsForButton:PasscodeButtonAll];
    
    for(int i = 0; i < 10; i++)
    {
        PasscodeStyle *buttonStyle;
        
        if(!styleForAllButtonsExists){
            buttonStyle = [styleProvider styleForButton:i];
        } else{
            buttonStyle = [styleProvider styleForButton:PasscodeButtonAll];
        }
        
        NSString *passcodeNumberStr = [NSString stringWithFormat:@"%d",i];
        PasscodeCircularButton *passcodeButton = [[PasscodeCircularButton alloc]initWithNumber:NSLocalizedString(passcodeNumberStr,nil)
                                                                                         frame:initialFrame
                                                                                         style:buttonStyle];
        
        [passcodeButton addTarget:self action:@selector(passcodeBtnPressed:) forControlEvents:UIControlEventTouchUpInside];
        [self.passcodeButtons addObject:passcodeButton];

    }
    
    
    self.btnCancelOrDelete = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    self.btnCancelOrDelete.frame = initialFrame;
    [self.btnCancelOrDelete setTitleColor:[PasscodeManager sharedManager].cancelOrDeleteButtonColor forState:UIControlStateNormal];
    self.btnCancelOrDelete.hidden = YES;
    [self.btnCancelOrDelete setTitle:@"" forState:UIControlStateNormal];
    [self.btnCancelOrDelete addTarget:self action:@selector(cancelOrDeleteBtnPressed:) forControlEvents:UIControlEventTouchUpInside];
    self.btnCancelOrDelete.titleLabel.font = [PasscodeManager sharedManager].cancelOrDeleteButtonFont;
    
    self.lblInstruction = [[UILabel alloc]initWithFrame:CGRectZero];
    self.lblInstruction.textColor = [PasscodeManager sharedManager].instructionsLabelColor;
    self.lblInstruction.font = [PasscodeManager sharedManager].instructionsLabelFont;
    
    self.lblError = [[UILabel alloc]initWithFrame:CGRectZero];
    self.lblError.textColor = [PasscodeManager sharedManager].errorLabelColor;
    self.lblError.backgroundColor = [PasscodeManager sharedManager].errorLabelBackgroundColor;
    self.lblError.font = [PasscodeManager sharedManager].errorLabelFont;
}

- (void)buildLayout
{

    CGFloat buttonRowWidth = (PasscodeButtonSize * 3) + (PasscodeButtonPaddingHorizontal * 2);
  
    CGFloat firstButtonX = ([self returnWidth]/2) - (buttonRowWidth/2) + 0.5;
    CGFloat middleButtonX = firstButtonX + PasscodeButtonSize + PasscodeButtonPaddingHorizontal;
    CGFloat lastButtonX = middleButtonX + PasscodeButtonSize + PasscodeButtonPaddingHorizontal;
    
    CGFloat firstRowY = ([self returnHeight]/2) - PasscodeButtonSize - PasscodeButtonPaddingVertical * 3;
    CGFloat middleRowY = firstRowY + PasscodeButtonSize + PasscodeButtonPaddingVertical;
    CGFloat lastRowY = middleRowY + PasscodeButtonSize + PasscodeButtonPaddingVertical;
    CGFloat zeroRowY = lastRowY + PasscodeButtonSize + PasscodeButtonPaddingVertical;

    NSValue *frameBtnOne = [NSValue valueWithCGRect:CGRectMake(firstButtonX, firstRowY, PasscodeButtonSize, PasscodeButtonSize)];
    NSValue *frameBtnTwo = [NSValue valueWithCGRect:CGRectMake(middleButtonX, firstRowY, PasscodeButtonSize, PasscodeButtonSize)];
    NSValue *frameBtnThree = [NSValue valueWithCGRect:CGRectMake(lastButtonX, firstRowY, PasscodeButtonSize, PasscodeButtonSize)];
    NSValue *frameBtnFour = [NSValue valueWithCGRect:CGRectMake(firstButtonX, middleRowY, PasscodeButtonSize, PasscodeButtonSize)];
    NSValue *frameBtnFive = [NSValue valueWithCGRect:CGRectMake(middleButtonX, middleRowY, PasscodeButtonSize, PasscodeButtonSize)];
    NSValue *frameBtnSix = [NSValue valueWithCGRect:CGRectMake(lastButtonX, middleRowY, PasscodeButtonSize, PasscodeButtonSize)];
    NSValue *frameBtnSeven = [NSValue valueWithCGRect:CGRectMake(firstButtonX, lastRowY, PasscodeButtonSize, PasscodeButtonSize)];
    NSValue *frameBtnEight = [NSValue valueWithCGRect:CGRectMake(middleButtonX, lastRowY, PasscodeButtonSize, PasscodeButtonSize)];
    NSValue *frameBtnNine = [NSValue valueWithCGRect:CGRectMake(lastButtonX, lastRowY, PasscodeButtonSize, PasscodeButtonSize)];
    NSValue *frameBtnZero = [NSValue valueWithCGRect:CGRectMake(middleButtonX, zeroRowY, PasscodeButtonSize, PasscodeButtonSize)];
   
    CGRect frameBtnCancel = CGRectMake(lastButtonX, zeroRowY, PasscodeButtonSize, PasscodeButtonSize);
    CGRect frameLblInstruction = CGRectMake(0, 0, 250, 20);
    CGRect frameLblError = CGRectMake(0, 0, 200, 20);
    CGRect frameBackgroundImageView = CGRectMake(self.view.frame.origin.x, self.view.frame.origin.y, [self returnWidth], [self returnHeight]);
    
    NSArray *buttonFrames = @[frameBtnZero, frameBtnOne, frameBtnTwo, frameBtnThree, frameBtnFour, frameBtnFive, frameBtnSix, frameBtnSeven, frameBtnEight, frameBtnNine];
    
    
    for(int i = 0; i < 10; i++)
    {
        PasscodeCircularButton *passcodeButton = self.passcodeButtons[i];
        passcodeButton.frame = [buttonFrames[i] CGRectValue];
        [self.view addSubview:passcodeButton];
    }

    self.backgroundImageView.frame = frameBackgroundImageView;
    
    self.btnCancelOrDelete.frame = frameBtnCancel;

    self.lblInstruction.textAlignment = NSTextAlignmentCenter;
    self.lblInstruction.frame = frameLblInstruction;
    self.lblInstruction.center = CGPointMake([self returnWidth]/2, firstRowY - (PasscodeButtonPaddingVertical * 10));

    self.lblError.textAlignment = NSTextAlignmentCenter;
    self.lblError.frame = frameLblError;
    self.lblError.center = CGPointMake([self returnWidth]/2, firstRowY - (PasscodeButtonPaddingVertical * 3));
    self.lblError.layer.cornerRadius = 10;
    self.lblError.hidden = YES;

    [self.view addSubview:self.btnCancelOrDelete];
    [self.view addSubview:self.lblInstruction];
    [self.view addSubview:self.lblError];
    
    
    CGFloat passcodeEntryViewsY = firstRowY - PasscodeButtonPaddingVertical * 7;
    CGFloat passcodeEntryViewWidth = (PasscodeDigitCount * PasscodeEntryViewSize) + ((PasscodeDigitCount - 1) * PasscodeButtonPaddingHorizontal);
    CGFloat xPoint = ([self returnWidth] - passcodeEntryViewWidth) / 2;
    CGFloat xPointInsideContainer = 0;
    CGRect framePasscodeEntryViewsContainerView = CGRectMake(xPoint, passcodeEntryViewsY, passcodeEntryViewWidth, PasscodeEntryViewSize);
    
    self.passcodeEntryViewsContainerView = [[UIView alloc]initWithFrame:framePasscodeEntryViewsContainerView];
    for (PasscodeCircularView *circularView in self.passcodeEntryViews){
        CGRect frame = CGRectMake(xPointInsideContainer, 0, PasscodeEntryViewSize, PasscodeEntryViewSize);
        circularView.frame = frame;
        xPointInsideContainer = xPointInsideContainer + PasscodeEntryViewSize + PasscodeButtonPaddingHorizontal;
        [self.passcodeEntryViewsContainerView addSubview:circularView];
    }
    [self.view addSubview:self.passcodeEntryViewsContainerView];

    
 }

- (void)updateLayoutBasedOnWorkflowStep
{
    self.btnCancelOrDelete.hidden = YES;
    
    if(self.passcodeType == PasscodeTypeSetup)
    {
        if(self.currentWorkflowStep == WorkflowStepOne)
        {
            self.lblInstruction.text = NSLocalizedString(EnterPasscodeText, nil);
        }
        else if(self.currentWorkflowStep == WorkflowStepSetupPasscodeEnteredOnce)
        {
            self.lblInstruction.text = NSLocalizedString(ReEnterPasscodeText, nil);
        }
        else if(self.currentWorkflowStep == WorkflowStepSetupPasscodesDidNotMatch)
        {
            self.lblInstruction.text = NSLocalizedString(EnterPasscodeText, nil);
            self.currentWorkflowStep = WorkflowStepOne;
        }
    }
    else if(self.passcodeType == PasscodeTypeVerify || self.passcodeType == PasscodeTypeVerifyForSettingChange){
        self.lblInstruction.text = NSLocalizedString(EnterPasscodeText, nil);;
        if(self.passcodeType == PasscodeTypeVerifyForSettingChange){
        }
    }
    else if(self.passcodeType == PasscodeTypeChangePasscode)
    {
        if(self.currentWorkflowStep == WorkflowStepOne){
            self.lblInstruction.text = NSLocalizedString(EnterCurrentPasscodeText, nil);
        }
    }
    [self enableCancelIfAllowed];
    [self resetPasscodeEntryView];
}

#pragma mark - 
#pragma mark - UIView Handlers

-(void)enableDelete
{
    if(!self.btnCancelOrDelete.tag != 2){
        self.btnCancelOrDelete.tag = 2;
        [self.btnCancelOrDelete setTitle:NSLocalizedString(DeleteButtonText,nil) forState:UIControlStateNormal];
    }
    if(self.btnCancelOrDelete.hidden){
        self.btnCancelOrDelete.hidden = NO;
    }
}

-(void)showErrorMessage:(NSString *)errorMessage
{
    self.lblError.hidden = NO;
    self.lblError.text = errorMessage;
}
- (void)enableCancelIfAllowed
{
    if(self.passcodeType == PasscodeTypeChangePasscode || self.passcodeType == PasscodeTypeSetup || self.passcodeType == PasscodeTypeVerifyForSettingChange){
        [self.btnCancelOrDelete setTitle:NSLocalizedString(CancelButtonText, nil) forState:UIControlStateNormal];
        self.btnCancelOrDelete.tag = 1;
        self.btnCancelOrDelete.hidden = NO;
    }
}
- (void) createPasscodeEntryView
{
    self.passcodeEntryViews = [NSMutableArray new];
    self.passcodeEntered = @"";
    self.numberOfDigitsEntered = 0;
    UIColor *lineColor = [PasscodeManager sharedManager].passcodeViewLineColor;
    UIColor *fillColor = [PasscodeManager sharedManager].passcodeViewFillColor;
    CGRect frame = CGRectMake(0, 0, PasscodeEntryViewSize, PasscodeEntryViewSize);
    
    for (int i=0; i < PasscodeDigitCount; i++){
        PasscodeCircularView *pcv = [[PasscodeCircularView alloc]initWithFrame:frame
                                                                     lineColor:lineColor
                                                                     fillColor:fillColor];
        [self.passcodeEntryViews addObject:pcv];
    }
}

- (void) resetPasscodeEntryView
{
    for(PasscodeCircularView *pcv in self.passcodeEntryViews)
    {
        [pcv clear];
    }
    self.passcodeEntered = @"";
    self.numberOfDigitsEntered = 0;
}

- (void)performShake:(UIView *)view {
	
    CAKeyframeAnimation *animation = [CAKeyframeAnimation animationWithKeyPath:@"position"];
	[animation setDuration:0.75];
	NSMutableArray *instructions = [NSMutableArray new];
	int loopCount = 4;
    CGFloat offSet = 30;
	
    while(offSet > 0.01) {
		[instructions addObject:[NSValue valueWithCGPoint:CGPointMake(view.center.x - offSet, view.center.y)]];
        offSet = offSet * 0.70;
		[instructions addObject:[NSValue valueWithCGPoint:CGPointMake(view.center.x + offSet, view.center.y)]];
        offSet = offSet * 0.70;
		loopCount--;
		if(loopCount <= 0) {
			break;
		}
	}
	animation.values = instructions;
	[view.layer addAnimation:animation forKey:@"position"];
}
-(void)applyBlur
{
    UIToolbar *blurToolbar = [[UIToolbar alloc] initWithFrame:self.view.bounds];
    blurToolbar.barStyle = UIBarStyleBlackTranslucent;
    blurToolbar.translucent = YES;
    blurToolbar.alpha = 0.95;
    [self.view addSubview:blurToolbar];
}
-(void)applyBackgroundImage
{
    if([PasscodeManager sharedManager].backgroundImage){
        self.backgroundImageView = [[UIImageView alloc] initWithFrame:CGRectZero];
        [self.backgroundImageView setImage:[PasscodeManager sharedManager].backgroundImage];
        [self.view addSubview:self.backgroundImageView];
    }
}
#pragma mark -
#pragma mark - Helper methods

- (CGFloat)returnWidth
{
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    if (UIInterfaceOrientationIsLandscape(orientation)){
        return self.view.frame.size.height;
    }
    else{
        return self.view.frame.size.width;
    }
}

- (CGFloat)returnHeight
{
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    if (UIInterfaceOrientationIsLandscape(orientation)){
        return self.view.frame.size.width;
    }
    else{
        return self.view.frame.size.height;
    }
}

-(void)evaluatePasscodeEntry{
    
    self.lblError.hidden = YES;
    
    if(self.passcodeType == PasscodeTypeSetup){
        if(self.currentWorkflowStep == WorkflowStepOne){
            self.currentWorkflowStep = WorkflowStepSetupPasscodeEnteredOnce;
            self.passcodeFirstEntry = self.passcodeEntered;
            [self updateLayoutBasedOnWorkflowStep];
        }
        else if(self.currentWorkflowStep == WorkflowStepSetupPasscodeEnteredOnce)
        {
            if([self.passcodeFirstEntry isEqualToString:self.passcodeEntered])
            {
                [[PasscodeManager sharedManager] setPasscode:self.passcodeEntered];
                [self.delegate didSetupPasscode];
            }
            else
            {
                self.currentWorkflowStep = WorkflowStepSetupPasscodesDidNotMatch;
                [self performErrorWithErrorText:PasscodesDidNotMatchText];
                [self updateLayoutBasedOnWorkflowStep];
            }
        }
    }
    else if(self.passcodeType == PasscodeTypeVerify || self.passcodeType == PasscodeTypeVerifyForSettingChange){
        if([[PasscodeManager sharedManager] isPasscodeCorrect:self.passcodeEntered]){
            [self.delegate didVerifyPasscode];
        }
        else{
            [self performErrorWithErrorText:IncorrectPasscodeText];
            self.currentWorkflowStep = WorkflowStepOne;
            [self updateLayoutBasedOnWorkflowStep];
        }
    }
    else if(self.passcodeType == PasscodeTypeChangePasscode)
    {
        if([[PasscodeManager sharedManager] isPasscodeCorrect:self.passcodeEntered]){
            self.passcodeType = PasscodeTypeSetup;
            self.currentWorkflowStep = WorkflowStepOne;
            [self updateLayoutBasedOnWorkflowStep];
        }
        else{
            [self performErrorWithErrorText:IncorrectPasscodeText];
            self.currentWorkflowStep = WorkflowStepOne;
            [self updateLayoutBasedOnWorkflowStep];
        }
        
    }

}

-(void)performErrorWithErrorText:(NSString *)text{
    [self showErrorMessage:NSLocalizedString(text, nil)];
    [self performShake:self.passcodeEntryViewsContainerView];
}

-(void)setDelegate:(id)newDelegate{
    self.delegate = newDelegate;
}

@end
