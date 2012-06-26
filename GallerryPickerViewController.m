//
//  GallerryPickerViewController.m
//  Webbb
//
//  Created by Varun Goyal on 12-01-13.
//  Copyright (c) 2012 University of Waterloo. All rights reserved.
//

#import "GallerryPickerViewController.h"
#import "SBJson.h"
#import "ViewController.h"
#import "UploadImageController.h"
#import "SHK.h"
#import "AdWhirlView.h"
#import "AppDelegate.h"

@interface GallerryPickerViewController ()
-(void) loadMoreImages;
-(void) loadNewPickerView;
-(void) loadHotPickerView;
-(void) loadTopPickerView;
-(void) reloadView;
-(void) loadNextPage;
-(void) uploadImage;
-(void) loadImageView:(id)sender;
@end

@implementation GallerryPickerViewController

@synthesize results = _results, responseData = _responseData,scrollView = _scrollView,imageController = _imageController,activityView = _activityView, thread = _thread, hotButton = _hotButton, topBtn = _topBtn, latestBtn = _latestBtn,reldButton = _reldButton, currentViewTitle = _currentViewTitle,adWhirl = _adWhirl,adView = _adView, bannerIsVisible = _bannerIsVisible, nxtBtn = _nxtBtn,uploadBtn = _uploadBtn,uploadImageView = _uploadImageView,superScrollView = _superScrollView;
int pagesLoaded, initialImagesLoaded,pageNo = 0;
bool viewloaded = true;
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

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [[UIApplication sharedApplication] setStatusBarHidden:NO];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.currentViewTitle = @"new";
    [self.hotButton setAction:@selector(loadHotPickerView)];
    [self.topBtn setAction:@selector(loadTopPickerView)];
    [self.latestBtn setAction:@selector(loadNewPickerView)];
    [self.reldButton setAction:@selector(reloadView)];
    [self.nxtBtn setAction:@selector(loadNextPage)];
    [self.uploadBtn setAction:@selector(uploadImage)];
    self.thread = [[NSThread alloc] initWithTarget:self selector:@selector(loadMoreImages) object:nil];
    self.imageController = [[ViewController alloc] initWithNibName:@"ViewController" bundle:nil];
    [self.activityView setHidden:NO];
    [self.activityView startAnimating];
    UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"background.png"]];
    [self.view addSubview:imageView];
    [self.view sendSubviewToBack:imageView];
    self.responseData = [NSMutableData data];
    self.results = [NSMutableArray array];  
    self.scrollView = [[UIScrollView alloc] initWithFrame:CGRectZero];
    self.scrollView.frame = CGRectMake(0, 0, 320, 372);
    [self.scrollView setShowsVerticalScrollIndicator:NO];
    [self.scrollView setBounces:NO];
    NSURLRequest *request = [NSURLRequest requestWithURL:  
                             [NSURL URLWithString:@"http://imgur.com/gallery/new.json"]];  
    (void) [[NSURLConnection alloc] initWithRequest:request delegate:self];
    pagesLoaded = 2;

    [self.superScrollView setContentSize:CGSizeMake(320, 372)];
    [self.superScrollView addSubview:self.scrollView];

    // Do any additional setup after loading the view from its nib.
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}


- (void)viewDidDisappear:(BOOL)animated{
    if (self.activityView.isAnimating) {
        [self.activityView stopAnimating];
    }
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark NSURLConnection Delegate methods  
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {  
    [self.responseData setLength:0];  
}  

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {  
    [self.responseData appendData:data];  
    [self.scrollView setUserInteractionEnabled:YES];
}  

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error { 
    [self.activityView stopAnimating];
    viewloaded = false;
    if([error.domain isEqualToString:@"Imgur over capacity"]){
        UIAlertView *alertNetwork = [[UIAlertView alloc] initWithTitle:error.domain message:@" Imgur is over capacity! This can happen when the site is under very heavy load, or while we're doing maintenance. Please try again in a few minutes." delegate:self cancelButtonTitle:@"Dismiss" otherButtonTitles:nil, nil];
        [alertNetwork show];
        [self.view setUserInteractionEnabled:YES];
        [self.scrollView setUserInteractionEnabled:NO];

    }else{
    UIAlertView *alertNetwork = [[UIAlertView alloc] initWithTitle:@"No network connection could be established" message:@"The app couldn't load, please check your internet connection" delegate:self cancelButtonTitle:@"Dismiss" otherButtonTitles:nil, nil];
    [alertNetwork show];
    [self.view setUserInteractionEnabled:YES];
    [self.scrollView setUserInteractionEnabled:NO];
    }
}  

- (void)connectionDidFinishLoading:(NSURLConnection *)connection { 
    [self.view setUserInteractionEnabled:YES];
    pagesLoaded = 1;
    NSString *responseString = [[NSString alloc] initWithData:self.responseData encoding:NSUTF8StringEncoding]; 
    NSArray *resultsArray = [(NSDictionary*)[responseString JSONValue] objectForKey:@"gallery"];
    if([resultsArray count] <= 0){
        NSError *error = [[NSError alloc] init];
        [error initWithDomain:@"Imgur over capacity" code:nil userInfo:nil];
        [self connection:connection didFailWithError:error];
        return;
    }
    self.results = resultsArray;
    int frameWidth = self.scrollView.frame.size.width;
    initialImagesLoaded = MIN(20, [resultsArray count]);
    int height = MIN(960, (initialImagesLoaded/4)*80);
    [self.scrollView setContentSize:CGSizeMake(frameWidth, height)];
    for(int i = 0; i < initialImagesLoaded ; i++){
        NSDictionary *initial = [self.results objectAtIndex:i];
        
        UIButton *thumbnail = [UIButton buttonWithType:UIButtonTypeCustom];
        [thumbnail setImage:[UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://i.imgur.com/%@s.jpg",[initial objectForKey:@"hash"]]]]] forState:UIControlStateNormal];
        int positionY = 80 * (i/4);
        int positionX = 80 * (i%4);
        
        thumbnail.frame = CGRectMake(positionX,positionY,80,90);
        [thumbnail addTarget:self action:@selector(buttonClicked:) forControlEvents:UIControlEventTouchUpInside];
        thumbnail.tag = i;
        self.scrollView.contentSize = CGSizeMake(self.scrollView.frame.size.width, ((i)/4 + 1) * 80);
        [self.scrollView addSubview:thumbnail];
        
    }
    self.thread = [[NSThread alloc] initWithTarget:self selector:@selector(loadMoreImages) object:nil];
    [self.thread start];
    
    [self.activityView setHidden:YES];
    [self.activityView stopAnimating];
}

- (IBAction)buttonClicked:(id)sender{
    [self.activityView startAnimating];
    [self.activityView setHidden:NO];  
    [[SHKActivityIndicator currentIndicator] displayActivity:SHKLocalizedString(@"Loading...")];
    [self loadImageView:sender];
};

-(void) loadMoreImages{
    for(int i = initialImagesLoaded; i <[self.results count] + 1; i++){
        if(i < [self.results count]){
            NSDictionary *initial = [self.results objectAtIndex:i];
            
            UIButton *thumbnail = [UIButton buttonWithType:UIButtonTypeCustom];
            [thumbnail setImage:[UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://i.imgur.com/%@s.jpg",[initial objectForKey:@"hash"]]]]] forState:UIControlStateNormal];
            int positionY =80 * (i/4);
            int positionX =80 * (i%4); 
            thumbnail.frame = CGRectMake(positionX,positionY,80,80);
            [thumbnail addTarget:self action:@selector(buttonClicked:) forControlEvents:UIControlEventTouchUpInside];
            thumbnail.tag = i;
            
            [self.scrollView addSubview:thumbnail];
            
            self.scrollView.contentSize = CGSizeMake(self.scrollView.frame.size.width, ((i)/4 + 1) * 80);
        }
        else {
     ;
//            [self.thread cancel];
//            self.adWhirl = [[AdWhirlView alloc] initWithFrame:CGRectZero];
//            self.adWhirl.delegate = self;
//            self.adWhirl.frame = CGRectOffset(self.adWhirl.frame, 0, self.scrollView.contentSize.height);
            //    self.adViedww.frame = CGRectOffset(self.adView.frame, 0, self.scrollView.contentSize.height);
//            [self.scrollView addSubview:self.adWhirl];
//            [self.adWhirl setUserInteractionEnabled:YES];
//            self.adView = [[ADBannerView alloc] initWithFrame:CGRectZero];
//            
//            self.adView.requiredContentSizeIdentifiers = [NSSet setWithObject:ADBannerContentSizeIdentifierPortrait];
//            self.adView.currentContentSizeIdentifier = ADBannerContentSizeIdentifierPortrait;
//            self.adView.delegate=self;
//            self.bannerIsVisible=NO;
//            self.adView.frame = CGRectOffset(self.adView.frame, 0, self.scrollView.contentSize.height);
//            [self.adView setHidden:YES];
//            self.scrollView.contentSize = CGSizeMake(self.scrollView.frame.size.width, self.scrollView.contentSize.height + self.adView.frame.size.height);
//            [self.scrollView ]addSubview:self.adWhirl]; ;
        }

        
    }
    [self.activityView stopAnimating];
    pagesLoaded ++;
    [self.thread cancel];
}

-(void) loadNewPickerView{
    pageNo = 0;
    [self.activityView startAnimating];
    [self.activityView setHidden:NO];
    [self.view setUserInteractionEnabled:NO];
    self.currentViewTitle = @"new";
    self.imageController = [[ViewController alloc] initWithNibName:@"ViewController" bundle:nil];
    [self.scrollView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    self.scrollView.frame = CGRectMake(0, 44, 320, 372);
    [self.scrollView setContentOffset:CGPointMake(0, 0)];
    self.responseData = [NSMutableData data];
    self.results = [NSMutableArray array];  
    NSURLRequest *request = [NSURLRequest requestWithURL:  
                             [NSURL URLWithString:@"http://imgur.com/gallery/new.json"]];  
    (void) [[NSURLConnection alloc] initWithRequest:request delegate:self];
    pagesLoaded = 2;
    
};

-(void) loadHotPickerView{
    pageNo = 0;
    [self.activityView startAnimating];
    [self.activityView setHidden:NO];
    [self.view setUserInteractionEnabled:NO];
    self.currentViewTitle = @"hot";
    self.imageController = [[ViewController alloc] initWithNibName:@"ViewController" bundle:nil];
    [self.scrollView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    self.scrollView.frame = CGRectMake(0, 0, 320, 372);
    [self.scrollView setContentOffset:CGPointMake(0, 0)];
    self.responseData = [NSMutableData data];
    self.results = [NSMutableArray array];  
    NSURLRequest *request = [NSURLRequest requestWithURL:  
                             [NSURL URLWithString:@"http://imgur.com/gallery/hot.json"]];  
    (void) [[NSURLConnection alloc] initWithRequest:request delegate:self];
    pagesLoaded = 1;
    
};

-(void) loadTopPickerView{
    pageNo = 0;
    [self.activityView startAnimating];
    [self.activityView setHidden:NO];
    [self.view setUserInteractionEnabled:NO];
    self.currentViewTitle = @"top";
    self.imageController = [[ViewController alloc] initWithNibName:@"ViewController" bundle:nil];
    [self.scrollView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    self.scrollView.frame = CGRectMake(0, 0,320,372);
    [self.scrollView setContentOffset:CGPointMake(0, 0)];
    self.responseData = [NSMutableData data];
    self.results = [NSMutableArray array];  
    NSURLRequest *request = [NSURLRequest requestWithURL:  
                             [NSURL URLWithString:@"http://imgur.com/gallery/top.json"]];  
    (void) [[NSURLConnection alloc] initWithRequest:request delegate:self];
    pagesLoaded = 1;
    
};

-(void) reloadView{
    pageNo = 0;
    [self.activityView startAnimating];
    [self.activityView setHidden:NO];
    [self.view setUserInteractionEnabled:NO];
    if([self.currentViewTitle isEqualToString:@"new"]){
        [self loadNewPickerView];
    }else if([self.currentViewTitle isEqualToString:@"top"]){
        [self loadTopPickerView];
    }else{
        [self loadHotPickerView];
    }
};

////AD delegate
//- (void)bannerViewDidLoadAd:(ADBannerView *)banner
//{
////    if (!self.bannerIsVisible)
////    {
////        [self.adView setHidden:NO];
////        self.scrollView.contentSize = CGSizeMake(self.scrollView.frame.size.width, self.scrollView.contentSize.height + self.adView.frame.size.height);
////        [UIView beginAnimations:@"animateAdBannerOn" context:NULL];
////        // banner is invisible now and moved out of the screen on 50 px
////        banner.frame = CGRectOffset(banner.frame, 0, 50);
////        [UIView commitAnimations];
////        self.bannerIsVisible = YES;
////   }
//    if(self.adView && ![self.adWhirl.superview isEqual:self.scrollView]){
//        self.adWhirl = [AdWhirlView requestAdWhirlViewWithDelegate:self];
////    self.adViedww.frame = CGRectOffset(self.adView.frame, 0, self.scrollView.contentSize.height);
//        [self.scrollView addSubview:self.adWhirl];
//        [self.adWhirl setUserInteractionEnabled:NO];
//    }
////    [self.adView isBannerLoaded]
//}
//
//- (void)bannerView:(ADBannerView *)banner didFailToReceiveAdWithError:(NSError *)error
//{
//    if (self.bannerIsVisible)
//    {
//        [UIView beginAnimations:@"animateAdBannerOff" context:NULL];
//        // banner is visible and we move it out of the screen, due to connection issue
//        banner.frame = CGRectOffset(banner.frame, 0, -50);
//        [UIView commitAnimations];
//        self.bannerIsVisible = NO;
//    
//    }
//}

-(void) loadNextPage{
    pageNo++;
    [self.activityView startAnimating];
    [self.activityView setHidden:NO];
    [self.view setUserInteractionEnabled:NO];
    [self.activityView startAnimating];
    [self.activityView setHidden:NO];
    [self.view setUserInteractionEnabled:NO];
    self.imageController = [[ViewController alloc] initWithNibName:@"ViewController" bundle:nil];
    [self.scrollView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    self.scrollView.frame = CGRectMake(0, 0,320,372);
    [self.scrollView setContentOffset:CGPointMake(0, 0)];
    self.responseData = [NSMutableData data];
    self.results = [NSMutableArray array];  
    NSString *suburl = [NSString stringWithFormat: @"http://imgur.com/gallery/%@/page/%i.json", self.currentViewTitle,pageNo];
    NSURLRequest *request = [NSURLRequest requestWithURL:  
                             [NSURL URLWithString:suburl]];  
    (void) [[NSURLConnection alloc] initWithRequest:request delegate:self];
    pagesLoaded = 1;
};


-(void) uploadImage{
    self.uploadImageView = [[UploadImageController alloc] init];
    [self.navigationController pushViewController:self.uploadImageView animated:YES];
};

-(void) loadImageView:(id)sender{
    UIButton *button = (UIButton *)sender;
    self.imageController.currentPage = [NSString stringWithFormat:@"%i",button.tag];
    self.imageController.results = self.results;
    if(self.imageController.scrollView.subviews > 0){
        NSDictionary *initial = [self.imageController.results objectAtIndex:button.tag];
        [self.imageController.scrollView setContentOffset:CGPointMake(320 * button.tag, 0)];
        id isTextNull = [initial objectForKey:@"title"];
        if(isTextNull != [NSNull null]){
            self.imageController.textView.text = [initial objectForKey:@"title"];
        }else{
            self.imageController.textView.text = @"";
        }
        
    };
    [self.navigationController pushViewController:self.imageController animated:YES];
    [[SHKActivityIndicator currentIndicator] hide];
};

- (NSString *)adWhirlApplicationKey {
    return @"b3f0c7103cf8429eb0892f71ed5155cb";
}

- (UIViewController *)viewControllerForPresentingModalView 
{
    return [(AppDelegate *)[[UIApplication sharedApplication] delegate] viewController];
}

- (void)adWhirlDidReceiveAd:(AdWhirlView *)adWhirlView{
    if(!self.adWhirl.userInteractionEnabled){
        [self.adWhirl setHidden:NO];
        [self.adWhirl setUserInteractionEnabled:YES];
//        [self.superScrollView setContentSize:CGSizeMake(320, 372 + self.adWhirl.frame.size.height)];
    }
}

@end
