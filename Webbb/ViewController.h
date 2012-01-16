//
//  ViewController.h
//  Webbb
//
//  Created by Varun Goyal on 12-01-12.
//  Copyright (c) 2012 University of Waterloo. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController<UIScrollViewDelegate>
@property (nonatomic,strong) NSArray *results;
@property (nonatomic, strong) NSMutableData *responseData;
@property (nonatomic,strong) IBOutlet UIScrollView *scrollView;
@property (nonatomic,strong) IBOutlet UIActivityIndicatorView *activityView;
@property (nonatomic,strong) IBOutlet UIBarButtonItem *comments;
@property (nonatomic,strong) IBOutlet UIToolbar *toolBar;
@property (nonatomic,strong) IBOutlet UILabel *textView;
@property (nonatomic,strong) NSString *currentPage;
@property (nonatomic,strong) IBOutlet UIBarButtonItem *backButton;
@property  int pageCount;
-(IBAction)download;
- (void) loadMoreImages;
@end
