//
//  CircleLineButton.h
//  ABPadLockScreenDemo
//
//  Created by Basar Akyelli on 2/15/14.
//  Copyright (c) 2014 Aron Bury. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PasscodeButtonStyleProvider.h"

@interface PasscodeCircularButton : UIButton


- (id) initWithNumber:(NSString *)number
                frame:(CGRect)frame
                style:(PasscodeStyle *)style;
@end
