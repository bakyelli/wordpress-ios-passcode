//
//  MainViewController.h
//  WPiOSPasscodeLock
//
//  Created by Basar Akyelli on 2/14/14.
//  Copyright (c) 2014 Basar Akyelli. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol PasscodeViewControllerDelegate <NSObject>

@optional

-(void) didSetupPasscode;
-(void) passcodeSetupCancelled;
-(void) didVerifyPasscode;
-(void) passcodeVerificationFailed;

@end

typedef enum PasscodeType : NSUInteger {
    PasscodeTypeVerify,
    PasscodeTypeVerifyForSettingChange,
    PasscodeTypeSetup,
    PasscodeTypeChangePasscode
} PasscodeType;


@interface PasscodeViewController : UIViewController

@property (nonatomic, unsafe_unretained) id <PasscodeViewControllerDelegate> delegate;

-(id) initWithPasscodeType:(PasscodeType)type withDelegate:(id<PasscodeViewControllerDelegate>)delegate;

@end
