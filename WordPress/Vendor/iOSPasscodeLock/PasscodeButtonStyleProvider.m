//
//  PasscodeButtonStyleProvider.m
//  WPiOSPasscodeLock
//
//  Created by Basar Akyelli on 2/19/14.
//  Copyright (c) 2014 Basar Akyelli. All rights reserved.
//

#import "PasscodeButtonStyleProvider.h"

@implementation PasscodeStyle

@end


@interface PasscodeButtonStyleProvider ()

@property (strong, nonatomic) NSMutableDictionary *buttonStyles;

@end


@implementation PasscodeButtonStyleProvider

-(id)init{
    self = [super init];
     if(self)
     {
         _buttonStyles = [NSMutableDictionary new];
     }
     return self;
}

- (void) addStyleForButton:(PasscodeButton)button stye:(PasscodeStyle *)passcodeStyle
{
    [_buttonStyles setObject:passcodeStyle forKey:[NSNumber numberWithInt:button]];
}

- (PasscodeStyle *) styleForButton:(PasscodeButton)button
{
    if([_buttonStyles objectForKey:[NSNumber numberWithInt:button]] != nil){
        return [_buttonStyles objectForKey:[NSNumber numberWithInt:button]];
    }else{
        PasscodeStyle *defaultStyle = [[PasscodeStyle alloc]init];
        defaultStyle.titleColor = [UIColor blackColor];
        defaultStyle.lineColor = [UIColor blackColor];
        defaultStyle.fillColor = [UIColor clearColor];
        defaultStyle.selectedFillColor = [UIColor blackColor];
        defaultStyle.selectedLineColor = [UIColor whiteColor];
        defaultStyle.selectedTitleColor = [UIColor whiteColor];
        return defaultStyle;
    }
}

- (BOOL) styleExistsForButton:(PasscodeButton)button{
    if([_buttonStyles objectForKey:[NSNumber numberWithInt:button]]){
        return YES;
    }else{
        return NO;
    }
}

@end
