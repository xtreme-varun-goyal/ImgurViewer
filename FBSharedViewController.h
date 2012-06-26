//
//  FBSharedViewController.h
//  ImgurViewer
//
//  Created by Varun Goyal on 12-03-22.
//  Copyright (c) 2012 University of Waterloo. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FBSharedViewController : UIViewController<UITableViewDataSource, UITableViewDelegate,UIScrollViewDelegate>

@property (nonatomic,strong) UIImageView *imageView;
@property (nonatomic,strong) UIScrollView *scrollViewImage;
@property (nonatomic,strong) UIScrollView *viewScroll;
@property (nonatomic,strong) NSArray *results;
@property (nonatomic, strong) NSMutableData *responseData;
@property (nonatomic,strong) NSString *hash;
@property (nonatomic,strong) UITableView *tableView;

@end
