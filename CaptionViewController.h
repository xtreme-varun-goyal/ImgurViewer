//
//  CaptionViewController.h
//  Webbb
//
//  Created by Varun Goyal on 12-01-12.
//  Copyright (c) 2012 University of Waterloo. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CaptionViewController : UIViewController<UITableViewDataSource, UITableViewDelegate>

@property (nonatomic,strong) NSArray *results;
@property (nonatomic, strong) NSMutableData *responseData;
@property (nonatomic,strong) NSString *hash;
@property (nonatomic,strong) IBOutlet UITableView *tableView;
@property (nonatomic,strong) IBOutlet UIBarButtonItem *buttonItem;

@end
