//
//  PasscodeCircularView.h
//  WPiOSPasscodeLock
//
//  Created by Basar Akyelli on 2/17/14.
//  Copyright (c) 2014 Basar Akyelli. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PasscodeCircularView : UIView

- (id) initWithFrame:(CGRect)frame
           lineColor:(UIColor *) lineColor
           fillColor:(UIColor *) fillColor;

- (void)fill;
- (void)clear;
@end
