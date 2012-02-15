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
@property (nonatomic,strong) NSThread *thread;
@property (nonatomic,strong) IBOutlet UIBarButtonItem *reldButton;
@property (nonatomic,strong) IBOutlet UIBarButtonItem *hotButton;
@property (nonatomic,strong) IBOutlet UIBarButtonItem *topBtn;
@property (nonatomic,strong) IBOutlet UIBarButtonItem *latestBtn;
@property (nonatomic,strong) NSString *currentViewTitle;
- (IBAction)buttonClicked:(id)sender;
@end
