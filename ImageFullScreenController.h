//
//  ImageFullScreenController.h
//  ImgurViewer
//
//  Created by Varun Goyal on 12-01-21.
//  Copyright (c) 2012 University of Waterloo. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ImageFullScreenController : UIViewController<UIScrollViewDelegate>

@property (nonatomic,strong) UIImageView *imageView;
@property (nonatomic,strong) IBOutlet UIScrollView *scrollView;
@property (nonatomic,strong) NSString *imageHash;

@end
