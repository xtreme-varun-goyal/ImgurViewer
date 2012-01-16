//
//  AppDelegate.h
//  Webbb
//
//  Created by Varun Goyal on 12-01-12.
//  Copyright (c) 2012 University of Waterloo. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GallerryPickerViewController.h"

@class ViewController;

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (strong, nonatomic) GallerryPickerViewController *viewController;

@end
