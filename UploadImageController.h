//
//  UploadImageController.h
//  ImgurViewer
//
//  Created by Varun Goyal on 12-02-25.
//  Copyright (c) 2012 University of Waterloo. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <iAd/iAd.h>
#import "GADBannerView.h"
#import "AdWhirlView.h"

@interface UploadImageController : UIViewController<UIPickerViewDelegate, UITextFieldDelegate,UIAlertViewDelegate,UIActionSheetDelegate,GADBannerViewDelegate,AdWhirlDelegate,ADBannerViewDelegate>
@property (nonatomic,strong) UIImagePickerController *imagePicker;
@property (nonatomic,strong) IBOutlet UIButton *uploadBtn;
@property (nonatomic,strong) IBOutlet UIImageView *imageView;
@property (nonatomic,strong) IBOutlet UITextField *textView;
@property (nonatomic,strong) IBOutlet UITextField *titleView;
@property (nonatomic,strong) IBOutlet UIBarButtonItem *doneBtn;
@property (nonatomic,strong) IBOutlet UIBarButtonItem *cameraBtn;
@property (nonatomic,strong) UIButton *camPick;
@property (nonatomic,strong) UIButton *galleryPick;
@property (nonatomic,strong) IBOutlet UIButton *retrieveCopy;
@property (nonatomic,assign) BOOL bannerIsVisible;
@property (nonatomic,strong) IBOutlet UILabel *urlLabel;
@property (nonatomic,strong) IBOutlet UILabel *titleLabel;
@property (nonatomic,strong) UIAlertView *alert;
@property (nonatomic,strong) GADBannerView *admobView;
@property (nonatomic,strong) AdWhirlView *adWhirl;
@property (nonatomic,strong) ADBannerView *adView;
@end
