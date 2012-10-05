//  Created by Varun Goyal on 12-01-12.
//  Copyright (c) 2012 University of Waterloo. All rights reserved.
//

#import "ViewController.h"
#import "SBJson.h"
#import "CaptionViewController.h"
#import "ImageFullScreenController.h"
#import "GifAnimatedView.h"
#import "SHK.h"
#import "SHKItem.h"
#import "SHKActionSheet.h"
#import "FBSharedViewController.h"

@interface ViewController ()
- (void) showComments;
- (void) dismissScreen;
- (void) initialLoadImages;
- (void) loadImage;
- (UIImage*) getImage;
- (void) loadGif;
@end

@implementation ViewController
@synthesize results = _results, responseData = _responseData,scrollView = _scrollView, activityView = _activityView, comments = _comments, toolBar = _toolBar, textView = _textView, currentPage = _currentPage, backButton = _backButton,pageCount = _pageCount,thread = _thread,interstitial = _interstitial, alertNetwork = _alertNetwork,shareBtn = _shareBtn,playBtn = _playBtn,fullScreenThread = _fullScreenThread;

bool isInterstitialLoaded;
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    for(int i = 0; i< [self.results count]; i ++){
        if(i!=[self.currentPage intValue]){
            ((UIImageView*) [self.scrollView.subviews objectAtIndex:i]).image = NULL;
            ((UIImageView*) [self.scrollView.subviews objectAtIndex:i]).tag = -4;
        }
    }
    // Release any cached data, images, etc that aren't in use.
}


#pragma mark - View lifecycle

- (void)viewDidLoad
{
    float maxHeight = MAX([[UIScreen mainScreen] bounds].size.height, [[UIScreen mainScreen] bounds].size.width);
    float minHeight = MIN([[UIScreen mainScreen] bounds].size.height, [[UIScreen mainScreen] bounds].size.width);
    [super viewDidLoad];
    self.playBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.playBtn showsTouchWhenHighlighted];
//    [self.scrollView setDelaysContentTouches:NO];
    [self.playBtn setImage:[UIImage imageNamed:@"Play_imgur.png"] forState:UIControlStateNormal];
    [self.playBtn addTarget:self action:@selector(loadGif) forControlEvents:UIControlEventTouchUpInside];
    self.thread = [[NSThread alloc] initWithTarget:self selector:@selector(loadImage) object:nil];
    [self.shareBtn setAction:@selector(share)];
    [self.activityView setHidden:NO];
    [self.activityView startAnimating];
    UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"background.png"]];
    [imageView setFrame:CGRectMake(0, 0, minHeight, maxHeight)];
    [self.view addSubview:imageView];
    [self.view sendSubviewToBack:imageView];
    [self.scrollView setScrollEnabled:YES];
    self.scrollView.maximumZoomScale = 2.0;
    self.scrollView.minimumZoomScale = 1; 
    self.textView.frame = CGRectMake(0, 0, minHeight, 44);
    self.textView.numberOfLines = 2;
    self.textView.textColor = [UIColor whiteColor];

    self.textView.font = [UIFont systemFontOfSize:14];
    self.textView.minimumFontSize = 10;
    [self.textView setAdjustsFontSizeToFitWidth:YES];
    [self.textView setLineBreakMode:UILineBreakModeTailTruncation];
    [self.textView setHidden:YES];
    [self.comments setAction:@selector(showComments)];
    self.scrollView.autoresizesSubviews = YES;
	self.scrollView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
    [self.backButton setAction:@selector(dismissScreen)];
    self.scrollView.minimumZoomScale=0.5;
    self.scrollView.maximumZoomScale=6.0;
    [self initialLoadImages];
    
    UITapGestureRecognizer* singleTap = [[UITapGestureRecognizer alloc] initWithTarget :self action : @selector (handleSingleTap:)];
    [singleTap setDelaysTouchesBegan : YES];
    
    [singleTap setNumberOfTapsRequired : 1];
    
    [self.scrollView addGestureRecognizer : singleTap];
    
    self.alertNetwork = [[UIAlertView alloc] initWithTitle:@"Unable to load image" message:@"The image couldn't load, please check your internet connections and reopen the app" delegate:self cancelButtonTitle:@"Dismiss" otherButtonTitles:nil, nil];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait | interfaceOrientation == UIInterfaceOrientationPortraitUpsideDown);
}

- (void)initialLoadImages {
    float maxHeight = MAX([[UIScreen mainScreen] bounds].size.height, [[UIScreen mainScreen] bounds].size.width);
    float minHeight = MIN([[UIScreen mainScreen] bounds].size.height, [[UIScreen mainScreen] bounds].size.width);
    int frameWidth = self.scrollView.frame.size.width;
    int frameHeight = self.scrollView.frame.size.height;
    for(int i = self.pageCount; i < [self.results count]; i ++){
        UIImageView *accountImage = [[UIImageView alloc] init];
        accountImage.frame = CGRectMake(frameWidth*i,0, minHeight, self.scrollView.frame.size.height);
        accountImage.image = [UIImage imageNamed:@"Loading.png"];
        accountImage.contentMode = UIViewContentModeScaleAspectFit;
        [self.scrollView addSubview:accountImage];
        accountImage.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
        accountImage.tag = -4;
        //        }
    }
    [self.scrollView addSubview:self.playBtn];
    [self.scrollView setContentSize:CGSizeMake(frameWidth * [self.results count], frameHeight)];
    
    NSDictionary *initial = [self.results objectAtIndex:[self.currentPage intValue]] ;
    UIView *currentView = [self.scrollView.subviews objectAtIndex:[self.currentPage intValue]];
    UIImage *image = [self getImage];
    
    int initialHeight = image.size.height;
    int initialWidth = image.size.width;
    int height = MIN((frameWidth * image.size.height) / image.size.width, frameHeight);
    if(initialHeight > frameHeight | initialWidth > frameWidth){
        currentView.frame = CGRectMake(frameWidth*[self.currentPage intValue], (frameHeight-height)/2, frameWidth,height);
    }else{
        currentView.frame = CGRectMake(frameWidth*[self.currentPage intValue] + (minHeight - initialWidth)/2, (frameHeight-initialHeight)/2, initialWidth,initialHeight);
    };
    
    NSString *ext = [initial objectForKey:@"ext"];
    
    if([ext isEqualToString:@".gif"]){
        [self.playBtn setHidden:NO];
        [self.playBtn setFrame:CGRectMake(frameWidth*[self.currentPage intValue] + (minHeight-32)/2, ((372*maxHeight)/480-32)/2, 32, 32)];
    }
    if(image!=NULL){
        ((UIImageView*)currentView).image = image;
        currentView.contentMode = UIViewContentModeScaleAspectFit;
        currentView.tag = 1;
        self.pageCount = 1;
    }
    //    } 
    
    [self.scrollView setUserInteractionEnabled:YES];
    
    [self.activityView stopAnimating];
    [self.activityView setHidden:YES];
    self.toolBar.hidden = NO;
    [self.scrollView setContentOffset:CGPointMake(minHeight * [self.currentPage intValue], 0)];
    id isTextNull = [initial objectForKey:@"title"];
    if(isTextNull == [NSNull null]){
        self.textView.text = @"";
    }else{
        self.textView.text = [initial objectForKey:@"title"];
    }
    [self.textView setHidden:NO];
}


- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    float maxHeight = MAX([[UIScreen mainScreen] bounds].size.height, [[UIScreen mainScreen] bounds].size.width);
    float minHeight = MIN([[UIScreen mainScreen] bounds].size.height, [[UIScreen mainScreen] bounds].size.width);
    CGFloat pageWidth = self.scrollView.frame.size.width;
    float fractionalPage = self.scrollView.contentOffset.x / pageWidth;
    NSInteger page = lroundf(fractionalPage);
    if(page == [self.results count] - 1){
        self.interstitial = [[GADInterstitial alloc] init];
        
        self.interstitial.delegate = self;
        
        // Note: Edit InterstitialExampleAppDelegate.m to update 
        // INTERSTITIAL_AD_UNIT_ID with your interstitial ad unit id.
        self.interstitial.adUnitID = @"a14f409cc9d4b4f";
        GADRequest *request = [GADRequest request];
        
        // Here we're setting test mode for the simulator.
        request.testDevices = [NSArray arrayWithObjects:
                               GAD_SIMULATOR_ID, // Simulator
                               nil];
        
        [self.interstitial loadRequest: request];
    }
    self.currentPage = [NSString stringWithFormat:@"%i",page];
    int pageTag= ((UIImageView*)[self.scrollView.subviews objectAtIndex:page]).tag;
    NSDictionary *initial = [self.results objectAtIndex:page];
    id titleIsNull = [initial objectForKey:@"title"];
    if(titleIsNull != [NSNull null]){
        self.textView.text = [initial objectForKey:@"title"];
    }else{
        self.textView.text = @"";
    }
    if((![self.thread isExecuting] && page < self.results.count && pageTag==-4)){
        self.thread = [[NSThread alloc] initWithTarget:self selector:@selector(loadImage) object:nil];
        [self.thread start];
    }
    NSString *ext = [initial objectForKey:@"ext"];
    
    if([ext isEqualToString:@".gif"] && ![self.thread isExecuting]){
        [self.playBtn setHidden:NO];
        [self.playBtn setFrame:CGRectMake(minHeight*[self.currentPage intValue] + (minHeight-32)/2, ((372*maxHeight)/480-32)/2, 32, 32)];
    }
}


- (void) showComments{
    CGFloat pageWidth = self.scrollView.frame.size.width;
    int currentPage = floor((self.scrollView.contentOffset.x - pageWidth / 2) / pageWidth) + 1;
    CaptionViewController *captionView = [[CaptionViewController alloc] init];
    NSDictionary *initial = [self.results objectAtIndex:currentPage] ;
    captionView.hash = [initial objectForKey:@"hash"];
    [self presentModalViewController:captionView animated:YES];
    
};


-(IBAction)download{
    [self.scrollView setUserInteractionEnabled:NO];
    CGFloat pageWidth = self.scrollView.frame.size.width;
    int currentPage = floor((self.scrollView.contentOffset.x - pageWidth / 2) / pageWidth) + 1;
    
    NSDictionary *initial = [self.results objectAtIndex:currentPage] ;
    UIImage *image = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://i.imgur.com/%@l.jpg",[initial objectForKey:@"hash"]]]]];
    UIImageWriteToSavedPhotosAlbum(image, self, @selector(image:didFinishSavingWithError:contextInfo:), nil);
}

-(void)image:(UIImage *)image didFinishSavingWithError:(NSError*)error contextInfo:(void*)contextInfo{
    if(error !=NULL){
        UIAlertView *error = [[UIAlertView alloc] initWithTitle:@"ERROR" message:@"Image wasn't saved" delegate:self cancelButtonTitle:@"Close" otherButtonTitles:nil] ;
        [error show];
    }else {
        UIAlertView *error = [[UIAlertView alloc] initWithTitle:nil message:@"Image successfully saved" delegate:self cancelButtonTitle:@"Close" otherButtonTitles:nil];  
        [error show];
    };
    [self.scrollView setUserInteractionEnabled:YES];
}


-(void) dismissScreen{
    [self.navigationController popViewControllerAnimated:YES];
}

-(void) loadMoreImages{
    int frameWidth = self.scrollView.frame.size.width;
    int frameHeight = self.scrollView.frame.size.height;
    float maxHeight = MAX([[UIScreen mainScreen] bounds].size.height, [[UIScreen mainScreen] bounds].size.width);
    float minHeight = MIN([[UIScreen mainScreen] bounds].size.height, [[UIScreen mainScreen] bounds].size.width);
    self.pageCount++;
    [self.activityView startAnimating];
    [self.activityView setHidden:NO];
    UIView *currentView = [self.scrollView.subviews objectAtIndex:[self.currentPage intValue]];
    UIImage *image = [self getImage];
    int initialHeight = image.size.height;
    int initialWidth = image.size.width;
    int height = MIN((frameWidth * image.size.height) / image.size.width, frameHeight);

    if(initialHeight > frameHeight | initialWidth > frameWidth){
        currentView.frame = CGRectMake(frameWidth*[self.currentPage intValue] + (minHeight - frameWidth)/2, (frameHeight-height)/2, frameWidth,height);
    }else{
        currentView.frame = CGRectMake(frameWidth*[self.currentPage intValue] + (minHeight - initialWidth)/2, (frameHeight-initialHeight)/2, initialWidth,initialHeight);
    };
    NSDictionary *initial = [self.results objectAtIndex:[self.currentPage intValue]] ;
    NSString *ext = [initial objectForKey:@"ext"];
    
    if([ext isEqualToString:@".gif"]){
        [self.playBtn setHidden:NO];
        [self.playBtn setFrame:CGRectMake(frameWidth*[self.currentPage intValue] + (minHeight-32)/2, ((372*maxHeight)/480-32)/2, 32, 32)];
    }
    
    if(image!=NULL){
        ((UIImageView*)currentView).image = image;
        currentView.contentMode = UIViewContentModeScaleAspectFit;
        currentView.tag = 1;
    }
    image = NULL;
    [self.activityView stopAnimating];
    [self.activityView setHidden:YES];
}

- (void) loadImage{
    [self.scrollView setUserInteractionEnabled:NO];
    float maxHeight = MAX([[UIScreen mainScreen] bounds].size.height, [[UIScreen mainScreen] bounds].size.width);
    float minHeight = MIN([[UIScreen mainScreen] bounds].size.height, [[UIScreen mainScreen] bounds].size.width);
    int frameWidth = self.scrollView.frame.size.width;
    int frameHeight = self.scrollView.frame.size.height;
    CGFloat pageWidth = self.scrollView.frame.size.width;
    float fractionalPage = self.scrollView.contentOffset.x / pageWidth;
    NSInteger page = lround(fractionalPage);
    UIView *currentView = [self.scrollView.subviews objectAtIndex:page];
    UIImage *image = [self getImage]; 
    
    int initialHeight = image.size.height;
    int initialWidth = image.size.width;
    int height = MIN((frameWidth * image.size.height) / image.size.width, frameHeight);
    if(initialHeight > frameHeight | initialWidth > frameWidth){
        currentView.frame = CGRectMake(frameWidth*page + (minHeight - frameWidth)/2, (frameHeight-height)/2, frameWidth,height);
    }else{
        currentView.frame = CGRectMake(frameWidth*page + (minHeight - initialWidth)/2, (frameHeight-initialHeight)/2, initialWidth,initialHeight);
    };
    if (currentView.tag == -4) {
        self.currentPage = [NSString stringWithFormat:@"%i",page];
        self.pageCount++;
        
        currentView.contentMode = UIViewContentModeScaleAspectFit;
        
        //        if(![ext isEqualToString:@".gif"]){
        if(image!=NULL){
            ((UIImageView*)currentView).image = image;
            currentView.contentMode = UIViewContentModeScaleAspectFit;
            currentView.tag = 1;
        }
        //        } 
        
        NSDictionary *initial = [self.results objectAtIndex:[self.currentPage intValue]] ;
        NSString *ext = [initial objectForKey:@"ext"];
        
        if([ext isEqualToString:@".gif"]){
            [self.playBtn setHidden:NO];
            [self.playBtn setFrame:CGRectMake(frameWidth*[self.currentPage intValue] + (minHeight-32)/2, ((372*maxHeight)/480-32)/2, 32, 32)];
        }
        
        [self.activityView stopAnimating];
        [self.activityView setHidden:YES];
        
    }
    [self.scrollView setUserInteractionEnabled:YES];
    
};


- (void) handleSingleTap : (UIGestureRecognizer*) sender
{ 
    [[SHKActivityIndicator currentIndicator] displayActivity:SHKLocalizedString(@"Loading...")];
    CGFloat pageWidth = self.scrollView.frame.size.width;
    float fractionalPage = self.scrollView.contentOffset.x / pageWidth;
    NSInteger page = lround(fractionalPage);
    NSDictionary *initial = [self.results objectAtIndex:page];
    UIImageView *curView = (UIImageView*)[self.scrollView.subviews objectAtIndex:page];
    if([[initial objectForKey:@"ext"] isEqualToString:@".gif"]){
        GifAnimatedView *fullWebView = [[GifAnimatedView alloc] init];
        fullWebView.imageId = [initial objectForKey:@"hash"];
        fullWebView.imageHeight = [NSString stringWithFormat:@"%f",curView.image.size.height];
        fullWebView.imageWidth = [NSString stringWithFormat:@"%f",curView.image.size.width];
        [self presentModalViewController:fullWebView animated:NO];
    }else{
//        ImageFullScreenController *fullScreen = [[ImageFullScreenController alloc] initWithNibName:@"ImageFullScreenController" bundle:nil];
        FBSharedViewController *fullScreen = [[FBSharedViewController alloc] init];
        fullScreen.imageView =  [[UIImageView alloc] initWithImage:((UIImageView*)[self.scrollView.subviews objectAtIndex:page]).image];
        fullScreen.hash = [initial objectForKey:@"hash"];
        [[UIApplication sharedApplication] setStatusBarHidden:YES];
        [self presentModalViewController:fullScreen animated:NO];
    }
    [[SHKActivityIndicator currentIndicator] hide];
}

- (UIImage*) getImage{
    NSDictionary *initial = [self.results objectAtIndex:[self.currentPage intValue]];
    UIImage *image = [[UIImage alloc] init];
    if([[initial objectForKey:@".ext"] isEqualToString:@".gif"]){
        image = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://i.imgur.com/%@s.jpg",[initial   objectForKey:@"hash"]]]]]; 
    }else{
        image = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://i.imgur.com/%@l.jpg",[initial   objectForKey:@"hash"]]]]]; 
    }
    if (!image && ![self.alertNetwork isVisible]) {
        [self.alertNetwork show];
    }
    return image;
};

- (void)interstitial:(GADInterstitial *)interstitial
didFailToReceiveAdWithError:(GADRequestError *)error {
}

- (void)interstitialDidReceiveAd:(GADInterstitial *)interstitial {
//    [interstitial presentFromRootViewController:self];
}

- (void)share
{
    CGFloat pageWidth = self.scrollView.frame.size.width;
    int currentPage = floor((self.scrollView.contentOffset.x - pageWidth / 2) / pageWidth) + 1;
    
    NSDictionary *initial = [self.results objectAtIndex:currentPage] ;
	// Create the item to share (in this example, a url)
	NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"http://i.imgur.com/%@",[initial objectForKey:@"hash"]]];
    UIImageView *curView = (UIImageView*)[self.scrollView.subviews objectAtIndex:currentPage];
    SHKItem *item = [[SHKItem alloc] init];
    item.image = curView.image;
	item.shareType = SHKShareTypeURL;
	item.URL = url;
	item.title = self.textView.text;
    
	// Get the ShareKit action shee
	SHKActionSheet *actionSheet = [SHKActionSheet actionSheetForItem:item];
    
	// Display the action sheet
	[actionSheet showFromToolbar:self.toolBar];
}

-(void) loadGif{
    CGFloat pageWidth = self.scrollView.frame.size.width;
    float fractionalPage = self.scrollView.contentOffset.x / pageWidth;
    NSInteger page = lround(fractionalPage);
    NSDictionary *initial = [self.results objectAtIndex:page];
    UIView *curView = (UIImageView*)[self.scrollView.subviews objectAtIndex:page];
    GifAnimatedView *fullWebView = [[GifAnimatedView alloc] init];
    fullWebView.imageId = [initial objectForKey:@"hash"];
    fullWebView.imageHeight = [NSString stringWithFormat:@"%f",curView.frame.size.height];
    fullWebView.imageWidth = [NSString stringWithFormat:@"%f",curView.frame.size.width];
    [self presentModalViewController:fullWebView animated:YES];
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
