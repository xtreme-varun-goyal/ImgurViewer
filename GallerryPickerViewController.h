//
//  GallerryPickerViewController.h
//  Webbb
//
//  Created by Varun Goyal on 12-01-13.
//  Copyright (c) 2012 University of Waterloo. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ViewController.h"

@interface GallerryPickerViewController : UIViewController

@property (nonatomic,strong) NSArray *results;
@property (nonatomic, strong) NSMutableData *responseData;
@property (nonatomic,strong) IBOutlet UIScrollView *scrollView;
@property (nonatomic,strong) ViewController *imageController;
@property (nonatomic,strong) IBOutlet UIActivityIndicatorView *activityView;
- (IBAction)buttonClicked:(id)sender;
@end
