//
//  GallerryPickerViewController.h
//  ImgurViewer
//
//  Created by Varun Goyal on 12-01-13.
//  Updated for iOS 15+ - 2025
//  Copyright (c) 2012 University of Waterloo. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ViewController.h"
#import "UploadImageController.h"

NS_ASSUME_NONNULL_BEGIN

@interface GallerryPickerViewController : UIViewController <UISearchBarDelegate>

@property (nonatomic, strong) NSArray *results;
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) ViewController *imageController;
@property (nonatomic, strong) IBOutlet UIActivityIndicatorView *activityView;
@property (nonatomic, strong) IBOutlet UIBarButtonItem *reldButton;
@property (nonatomic, strong) IBOutlet UIBarButtonItem *hotButton;
@property (nonatomic, strong) IBOutlet UIBarButtonItem *topBtn;
@property (nonatomic, strong) IBOutlet UIBarButtonItem *latestBtn;
@property (nonatomic, strong) IBOutlet UIBarButtonItem *nxtBtn;
@property (nonatomic, strong) IBOutlet UIBarButtonItem *searchBtn;
@property (nonatomic, strong) NSString *currentViewTitle;
@property (nonatomic, strong) IBOutlet UIBarButtonItem *uploadBtn;
@property (nonatomic, strong, nullable) UploadImageController *uploadImageView;
@property (nonatomic, strong) IBOutlet UIScrollView *superScrollView;
@property (nonatomic, strong) UISearchBar *searchBar;

- (IBAction)buttonClicked:(id)sender;

@end

NS_ASSUME_NONNULL_END
