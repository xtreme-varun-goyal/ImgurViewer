//
//  GifAnimatedView.h
//  ImgurViewer
//
//  Created by Varun Goyal on 12-02-12.
//  Copyright (c) 2012 University of Waterloo. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface GifAnimatedView : UIViewController<UIWebViewDelegate,UIAlertViewDelegate,UITableViewDelegate>

@property (nonatomic,strong) UIWebView *webView;
@property (nonatomic,strong) NSString *imageId;
@property (nonatomic,strong) NSString *imageHeight;
@property (nonatomic,strong) NSString *imageWidth;
@property (nonatomic,strong) NSString *url;

@property (nonatomic,strong) UIScrollView *viewScroll;
@property (nonatomic,strong) NSArray *results;
@property (nonatomic, strong) NSMutableData *responseData;
@property (nonatomic,strong) NSString *hash;
@property (nonatomic,strong) UITableView *tableView;
@end
