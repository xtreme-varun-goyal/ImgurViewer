//
//  GallerryPickerViewController.h
//  Webbb
//
//  Created by Varun Goyal on 12-01-13.
//  Copyright (c) 2012 University of Waterloo. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ViewController.h"
#import <iAd/iAd.h>
#import "UploadImageController.h"
#import "AdWhirlView.h"

@interface GallerryPickerViewController : UIViewController<ADBannerViewDelegate,AdWhirlDelegate, UISearchBarDelegate, GADBannerViewDelegate, UISearchBarDelegate>

@property (nonatomic,strong) NSArray *results;
@property (nonatomic, strong) NSMutableData *responseData;
@property (nonatomic,strong) UIScrollView *scrollView;
@property (nonatomic,strong) ViewController *imageController;
@property (nonatomic,strong) IBOutlet UIActivityIndicatorView *activityView;
@property (nonatomic,strong) NSThread *thread;
@property (nonatomic,strong) IBOutlet UIBarButtonItem *reldButton;
@property (nonatomic,strong) IBOutlet UIBarButtonItem *hotButton;
@property (nonatomic,strong) IBOutlet UIBarButtonItem *topBtn;
@property (nonatomic,strong) IBOutlet UIBarButtonItem *latestBtn;
@property (nonatomic,strong) IBOutlet UIBarButtonItem *nxtBtn;
@property (nonatomic,strong) IBOutlet UIBarButtonItem *searchBtn;
@property (nonatomic,strong) NSString *currentViewTitle;
- (IBAction)buttonClicked:(id)sender;
@property (nonatomic,strong) AdWhirlView *adWhirl;
@property (nonatomic,strong) ADBannerView *adView;
@property (nonatomic,assign) BOOL bannerIsVisible;
@property (nonatomic,strong) IBOutlet UIBarButtonItem *uploadBtn;
@property (nonatomic,strong) UploadImageController *uploadImageView;
@property (nonatomic,strong) IBOutlet UIScrollView *superScrollView;
@property (nonatomic,strong) UISearchBar *searchBar;
@property (nonatomic, retain) NSString *dataParsed;
@property (nonatomic,strong) GADBannerView *admobView;
@end
