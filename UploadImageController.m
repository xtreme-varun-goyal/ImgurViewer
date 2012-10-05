//
//  UploadImageController.m
//  ImgurViewer
//
//  Created by Varun Goyal on 12-02-25.
//  Copyright (c) 2012 University of Waterloo. All rights reserved.
//

#import "UploadImageController.h"
#import "NSDataAdditions.h"
#import "NSString+URLEscape.h"
#import "SBJson.h"
#import "SHK.h"
#import "SHKItem.h"
#import "SHKActionSheet.h"
#import "AppDelegate.h"
#import "AdWhirlView.h"
#import "GADBannerView.h"

@interface UploadImageController ()
-(void) uploadImage;
-(NSData *)uploadPhoto:(UIImage *) image;
-(void) dismissView;
-(void) actionPopup;
-(void) camPicker;
-(void) galleryPicker;
-(void) copyTitleText;
@end
@implementation UploadImageController
@synthesize imagePicker = _imagePicker, uploadBtn = _uploadBtn,imageView = _imageView, textView = _textView,titleView = _titleView,doneBtn = _doneBtn,cameraBtn = _cameraBtn,camPick = _camPick,galleryPick = _galleryPick, bannerIsVisible = _bannerIsVisible,alert = _alert,retrieveCopy = _retrieveCopy, urlLabel = _urlLabel,titleLabel = _titleLabel,admobView = _admobView,adWhirl = _adWhirl,adView = _adView;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    float maxHeight = MAX([[UIScreen mainScreen] bounds].size.height, [[UIScreen mainScreen] bounds].size.width);
    float minHeight = MIN([[UIScreen mainScreen] bounds].size.height, [[UIScreen mainScreen] bounds].size.width);
    UIImageView *backgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"background.png"]];
    [backgroundView setFrame:CGRectMake(0, 0, minHeight, maxHeight)];
    [self.retrieveCopy addTarget:self action:@selector(copyTitleText) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:backgroundView];
    [self.view sendSubviewToBack:backgroundView];
    self.camPick = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    self.galleryPick = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [self.uploadBtn addTarget:self action:@selector(actionPopup) forControlEvents:UIControlEventTouchUpInside];
    [self.textView setHidden:YES];
    [self.retrieveCopy setHidden:YES];
    [self.urlLabel setHidden:YES];
    [self.titleView setHidden:YES];
    [self.titleLabel setHidden:YES];
    [self.cameraBtn setAction:@selector(share)];
    self.titleView.delegate = self;
    [self.imageView setContentMode:UIViewContentModeScaleAspectFit];
    [self.doneBtn setAction:@selector(dismissView)];
    [self.camPick addTarget:self action:@selector(camPicker) forControlEvents:UIControlEventTouchUpInside];
    [self.galleryPick addTarget:self action:@selector(galleryPicker) forControlEvents:UIControlEventTouchUpInside];
    self.admobView = [[GADBannerView alloc] init];
    [self.admobView setFrame:CGRectMake(0, maxHeight - 70, minHeight, 50)];
    self.admobView.adUnitID = @"a14f409cc9d4b4f";
    self.admobView.rootViewController = self;
    [self.view addSubview:self.admobView];
    
    
    GADRequest *r = [[GADRequest alloc] init];
//    r.testing = YES;
    [self.admobView loadRequest:r];
//    [self.adView setHidden:YES];
//    self.adView = [[ADBannerView alloc] initWithFrame:CGRectZero];
//    self.adView.requiredContentSizeIdentifiers = [NSSet setWithObject:ADBannerContentSizeIdentifierPortrait];
//    self.adView.currentContentSizeIdentifier = ADBannerContentSizeIdentifierPortrait;
//    self.adView.delegate=self;
//    self.bannerIsVisible=YES;
//    self.adView.frame = CGRectOffset(self.adView.frame, 0, 980);
//    [self.view addSubview:self.adView];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

-(void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
//    [self.adView setHidden:YES];
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)imagePickerController:(UIImagePickerController *)picker 
        didFinishPickingImage:(UIImage *)image
                  editingInfo:(NSDictionary *)editingInfo
{
    float actualHeight = image.size.height;
    float actualWidth = image.size.width;
    float maxHeight = MAX([[UIScreen mainScreen] bounds].size.height, [[UIScreen mainScreen] bounds].size.width);
    float minHeight = MIN([[UIScreen mainScreen] bounds].size.height, [[UIScreen mainScreen] bounds].size.width);
    float imgRatio = actualWidth/actualHeight;
    float maxRatio = (minHeight*1.0)/maxHeight;
    
    if(imgRatio!=maxRatio){
        if(imgRatio < maxRatio){
            imgRatio = (maxHeight * 1.0) / actualHeight;
            actualWidth = imgRatio * actualWidth;
            actualHeight = maxHeight;
        }
        else{
            imgRatio = (minHeight*1.0) / actualWidth;
            actualHeight = imgRatio * actualHeight;
            actualWidth = minHeight;
        }
    }
    CGRect rect = CGRectMake(0.0, 0.0, actualWidth, actualHeight);
    UIGraphicsBeginImageContext(rect.size);
    [image drawInRect:rect];
    self.imageView.image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    NSLog([NSString stringWithFormat:@"Height%f , width%f",self.imageView.image.size.height,self.imageView.image.size.width]);
    [picker dismissModalViewControllerAnimated:YES];
    [self.uploadBtn setTitle:@"Upload Image" forState:UIControlStateNormal];
    [self.titleView setHidden:NO];
    [self.titleLabel setHidden:NO];
}

-(void) uploadImage{
    if(self.imageView.image){
        NSData *data = [self uploadPhoto:self.imageView.image];
        NSLog(@"%@", data);
        NSString *content = [[NSString alloc] initWithData:data
                                                  encoding:NSUTF8StringEncoding];
        NSString *hash = [[[[content JSONValue] objectForKey:@"upload"] objectForKey:@"image"] objectForKey:@"hash"];
        [self.textView setText:[NSString stringWithFormat:@"http://imgur.com/%@",hash]];
        [self.textView setHidden:NO];
        [self.textView resignFirstResponder];
        [self.uploadBtn setTitle:@"Image Uploaded" forState:UIControlStateNormal];
        [self.textView setHidden:NO];
        [self.retrieveCopy setHidden:NO];
        [self.urlLabel setHidden:NO];
    }else{
        UIAlertView *alertNetwork = [[UIAlertView alloc] initWithTitle:@"No Image Selected" message:nil delegate:self cancelButtonTitle:@"Dismiss" otherButtonTitles:nil, nil];
        if(!alertNetwork.isVisible){
            [alertNetwork show];
        }
    }
    [self.view setUserInteractionEnabled:YES];
    [[SHKActivityIndicator currentIndicator] hide];
    // Do any additional setup after loading the view from its nib.
    
}

-(NSData *)uploadPhoto:(UIImage *) image {
    NSData   *imageData  = UIImageJPEGRepresentation(image,1);
    NSString *imageB64   = [[imageData base64Encoding] stringByEscapingValidURLCharacters];  
    //    NSData *date = [NSData dataWithBase64EncodedString:imageB64];
    //    [self.imageView setImage:[UIImage imageWithData:date]];
    //    NSLog(imageB64);
    NSString *uploadCall = [NSString stringWithFormat:@"key=%@&image=%@&title=%@",@"34556649e90942be63345f5431d3fe55",imageB64,self.titleView.text];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"http://api.imgur.com/2/upload.json"]];
    [request setHTTPMethod:@"POST"];
    [request setValue:[NSString stringWithFormat:@"%d",[uploadCall length]] forHTTPHeaderField:@"Content-length"];
    [request setHTTPBody:[uploadCall dataUsingEncoding:NSUTF8StringEncoding]];
    
    NSURLResponse *response;
    NSError *error = nil;
    
    NSData *XMLResponse= [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    return XMLResponse;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
	[textField resignFirstResponder];
	return YES;
}

-(void) dismissView{
    [self.navigationController popViewControllerAnimated:YES];
};

-(void) actionPopup{
    if(!self.imageView.image){
        UIActionSheet *actionSheet = [[UIActionSheet alloc] init];
        [actionSheet addButtonWithTitle:@"Library"];
        [actionSheet addButtonWithTitle:@"Camera"];
        [actionSheet addButtonWithTitle:@"Cancel"];
        [actionSheet showFromTabBar:self.navigationController.toolbar];
        actionSheet.delegate = self;
        //        self.alert = [[UIAlertView alloc] initWithTitle:nil message:nil delegate:self cancelButtonTitle:nil otherButtonTitles:@"Library",@"Camera", nil];
        //        [self.alert sizeToFit];
        //        [self.alert sho];//  
    }else
    {
        [[SHKActivityIndicator currentIndicator] displayActivity:SHKLocalizedString(@"Uploading...")];
        [[[NSThread alloc] initWithTarget:self selector:@selector(uploadImage) object:nil] start];
        [self.view setUserInteractionEnabled:NO];
        [self.titleView setUserInteractionEnabled:NO];
        [self.uploadBtn setUserInteractionEnabled:NO] ;
    }
}

-(void)alertView:(UIAlertView *)alert_view didDismissWithButtonIndex:(NSInteger)button_index{
    if(alert_view == self.alert){
        if(button_index == 1){
            [self camPicker];
        }
        if(button_index ==0){
            [self galleryPicker];
        }
    }
}

-(void) camPicker{
    UIImagePickerController* picker = [[UIImagePickerController alloc] init];
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera])  {
        [self.navigationController dismissModalViewControllerAnimated:YES];
        picker.sourceType = UIImagePickerControllerSourceTypeCamera;
        picker.delegate = self;
        [[self navigationController] presentModalViewController:picker animated:YES];
    }else{
        UIAlertView *alertNetwork = [[UIAlertView alloc] initWithTitle:@"Camera unavailable" message:@"" delegate:self cancelButtonTitle:@"Dismiss" otherButtonTitles:nil, nil];
        if(!alertNetwork.isVisible){
            [alertNetwork show];
        }
    }
};

-(void) galleryPicker{
    [self.navigationController dismissModalViewControllerAnimated:YES];
    UIImagePickerController *imagePickerController = [[UIImagePickerController alloc]init];
    imagePickerController = [[UIImagePickerController alloc] init];
    imagePickerController.delegate = self;
    imagePickerController.sourceType =  UIImagePickerControllerSourceTypePhotoLibrary;
    
    [self presentModalViewController:imagePickerController animated:YES];
};

- (void)bannerViewDidLoadAd:(ADBannerView *)banner
{
    if (!self.bannerIsVisible)
    {
        [UIView beginAnimations:@"animateAdBannerOn" context:NULL];
        // banner is invisible now and moved out of the screen on 50 px
        banner.frame = CGRectOffset(banner.frame, 0, 50);
        [UIView commitAnimations];
        //        self.bannerIsVisible = YES;
    }
    if(self.adView && ![self.adWhirl.superview isEqual:self.view]){
        self.adWhirl = [AdWhirlView requestAdWhirlViewWithDelegate:self];
        //    self.adViedww.frame = CGRectOffset(self.adView.frame, 0, self.scrollView.contentSize.height);
        [self.view addSubview:self.adWhirl];
        [self.adWhirl setUserInteractionEnabled:NO];
    }
}

- (void)bannerView:(ADBannerView *)banner didFailToReceiveAdWithError:(NSError *)error
{
    if (self.bannerIsVisible)
    {
        [UIView beginAnimations:@"animateAdBannerOff" context:NULL];
        // banner is visible and we move it out of the screen, due to connection issue
        banner.frame = CGRectOffset(banner.frame, 0, -50);
        [UIView commitAnimations];
        self.bannerIsVisible = NO;
    }
}

- (void)share
{
	if([self.textView.text length] > 0){
        // Create the item to share (in this example, a url)
        NSURL *url = [NSURL URLWithString:self.textView.text];
        SHKItem *item = [SHKItem URL:url title:self.titleView.text];
        
        // Get the ShareKit action sheet
        SHKActionSheet *actionSheet = [SHKActionSheet actionSheetForItem:item];
        
        // Display the action sheet
        [actionSheet showFromToolbar:self.navigationController.toolbar];}
    else{
        UIAlertView *alertNetwork = [[UIAlertView alloc] initWithTitle:@"No image uploaded" message:nil delegate:self cancelButtonTitle:@"Dismiss" otherButtonTitles:nil, nil];
        if(!alertNetwork.isVisible){
            [alertNetwork show];
        }
    }
}

-(void) copyTitleText{
    if([self.textView.text length] > 0){
        UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
        [pasteboard setString:self.textView.text];
        UIAlertView *alertNetwork = [[UIAlertView alloc] initWithTitle:@"Link Copied" message:nil delegate:self cancelButtonTitle:@"Dismiss" otherButtonTitles:nil, nil];
        if(!alertNetwork.isVisible){
            [alertNetwork show];
        }
    }
};

-(void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    
	// Sharers
	if (buttonIndex ==0)
	{
        [self galleryPicker];
	}else if(buttonIndex == 1){
        [self camPicker];
    }
	[super dismissModalViewControllerAnimated:YES];
    
}

- (NSString *)adWhirlApplicationKey {
    return @"b3f0c7103cf8429eb0892f71ed5155cb";
}

- (UIViewController *)viewControllerForPresentingModalView 
{
    return [(AppDelegate *)[[UIApplication sharedApplication] delegate] viewController];
}

- (void)adWhirlDidReceiveAd:(AdWhirlView *)adWhirlView{
    if(self.adView){
        self.adView = nil;
        float maxHeight = MAX([[UIScreen mainScreen] bounds].size.height, [[UIScreen mainScreen] bounds].size.width);
        float minHeight = MIN([[UIScreen mainScreen] bounds].size.height, [[UIScreen mainScreen] bounds].size.width);
        self.adWhirl.frame = CGRectOffset(self.adWhirl.frame, 0, (maxHeight-20) - self.adWhirl.frame.size.height);
        [self.adWhirl setUserInteractionEnabled:YES];
    }
}

- (void)adViewDidReceiveAd:(GADBannerView *)bannerView {
    [UIView beginAnimations:@"BannerSlide" context:nil];
    bannerView.frame = CGRectMake(0.0,
                                  self.view.frame.size.height -
                                  bannerView.frame.size.height,
                                  bannerView.frame.size.width,
                                  bannerView.frame.size.height);
    [UIView commitAnimations];
}
@end

@implementation UINavigationController (Rotation_IOS6)

-(BOOL)shouldAutorotate
{
    return NO;
}

-(NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}
@end