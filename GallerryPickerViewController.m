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
-(void) showSearchBar;
-(void) loadSearchResults;
@end

@implementation GallerryPickerViewController

@synthesize results = _results, responseData = _responseData,scrollView = _scrollView,imageController = _imageController,activityView = _activityView, thread = _thread, hotButton = _hotButton, topBtn = _topBtn, latestBtn = _latestBtn,reldButton = _reldButton, currentViewTitle = _currentViewTitle,adWhirl = _adWhirl,adView = _adView, bannerIsVisible = _bannerIsVisible, nxtBtn = _nxtBtn,uploadBtn = _uploadBtn,uploadImageView = _uploadImageView,superScrollView = _superScrollView, searchBar = _searchBar, admobView = _admobView;
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
    float maxHeight = MAX([[UIScreen mainScreen] bounds].size.height, [[UIScreen mainScreen] bounds].size.width);
    float minHeight = MIN([[UIScreen mainScreen] bounds].size.height, [[UIScreen mainScreen] bounds].size.width);
    [super viewDidLoad];
    [self.searchBar setDelegate:self];

    self.currentViewTitle = @"new";
    [self.hotButton setAction:@selector(loadHotPickerView)];
    [self.topBtn setAction:@selector(loadTopPickerView)];
    [self.latestBtn setAction:@selector(loadNewPickerView)];
    [self.reldButton setAction:@selector(reloadView)];
    [self.nxtBtn setAction:@selector(loadNextPage)];
    [self.uploadBtn setAction:@selector(uploadImage)];
    [self.searchBtn setAction:@selector(showSearchBar)];
    self.thread = [[NSThread alloc] initWithTarget:self selector:@selector(loadMoreImages) object:nil];
    self.imageController = [[ViewController alloc] initWithNibName:@"ViewController" bundle:nil];
    [self.activityView setHidden:NO];
    [self.activityView startAnimating];
    UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"background.png"]];
    [imageView setFrame:CGRectMake(0, 0, minHeight, maxHeight)];
    [self.view addSubview:imageView];
    [self.view sendSubviewToBack:imageView];
    self.responseData = [NSMutableData data];
    self.results = [NSMutableArray array];  
    self.scrollView = [[UIScrollView alloc] initWithFrame:CGRectZero];
    self.scrollView.frame = CGRectMake(0, 0, minHeight, maxHeight - 158);
    [self.scrollView setShowsVerticalScrollIndicator:NO];
    [self.scrollView setBounces:NO];
    NSURLRequest *request = [NSURLRequest requestWithURL:  
                             [NSURL URLWithString:@"http://imgur.com/gallery/new.json"]];
    (void) [[NSURLConnection alloc] initWithRequest:request delegate:self];
    pagesLoaded = 2;

    [self.superScrollView setContentSize:CGSizeMake(minHeight, (372*maxHeight)/480)];
    [self.superScrollView addSubview:self.scrollView];
    self.admobView = [[GADBannerView alloc] init];
    [self.admobView setFrame:CGRectMake(0, maxHeight - 114, minHeight, 50)];
    self.admobView.adUnitID = @"a14f409cc9d4b4f";
    self.admobView.rootViewController = self;
    GADRequest *r = [[GADRequest alloc] init];
    [self.admobView loadRequest:r];
    [self.view addSubview:self.admobView];
    self.searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 44, minHeight, 44)];
    [self.view addSubview:self.searchBar];
    [self.searchBar setShowsCancelButton:YES];
    [self.searchBar setBarStyle:UIBarStyleBlackOpaque];
    [self.searchBar setHidden:YES];
    [self.searchBar setDelegate:self];
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

- (BOOL)shouldAutorotate {
    return NO;
}

- (BOOL)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}
// pre-iOS 6 support
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
    return (toInterfaceOrientation == UIInterfaceOrientationPortrait);
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

    }else if([error.domain isEqualToString:@"No results found"]){
        UIAlertView *alertNetwork = [[UIAlertView alloc] initWithTitle:@"No results found" message:@"The search returned no results, please change your query." delegate:self cancelButtonTitle:@"Dismiss" otherButtonTitles:nil, nil];
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
    float maxHeight = MAX([[UIScreen mainScreen] bounds].size.height, [[UIScreen mainScreen] bounds].size.width);
    float minHeight = MIN([[UIScreen mainScreen] bounds].size.height, [[UIScreen mainScreen] bounds].size.width);
    [self.view setUserInteractionEnabled:YES];
    pagesLoaded = 1;
    NSString *responseString = [[NSString alloc] initWithData:self.responseData encoding:NSUTF8StringEncoding];
    NSMutableArray *keys = [(NSDictionary*)[responseString JSONValue] allKeys];
    NSArray *resultsArray = [(NSDictionary*)[responseString JSONValue] objectForKey:keys[0]];
    if([resultsArray count] <= 0 ){
        NSError *error = [[NSError alloc] init];
        if(self.searchBar.isHidden == NO){
            [error initWithDomain:@"No results found" code:nil userInfo:nil];
            [self connection:connection didFailWithError:error];
            return;
        }else{
            [error initWithDomain:@"Imgur over capacity" code:nil userInfo:nil];
            [self connection:connection didFailWithError:error];
            [self.searchBtn setStyle:UIBarStyleBlack];
            [self.searchBar setHidden:YES];
            return;
        };
    }
    [self.searchBtn setStyle:UIBarStyleBlack];
    [self.searchBar setHidden:YES];
    self.results = resultsArray;
    int frameWidth = self.scrollView.frame.size.width;
    initialImagesLoaded = MIN(20, [resultsArray count]);
    int height = MIN(maxHeight*2, (initialImagesLoaded/4)*maxHeight/6);
    [self.scrollView setContentSize:CGSizeMake(frameWidth, height)];
    for(int i = 0; i < initialImagesLoaded ; i++){
        NSDictionary *initial = [self.results objectAtIndex:i];
        
        UIButton *thumbnail = [UIButton buttonWithType:UIButtonTypeCustom];
        [thumbnail setImage:[UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://i.imgur.com/%@s.jpg",[initial objectForKey:@"hash"]]]]] forState:UIControlStateNormal];
        int positionY = maxHeight/6 * (i/4);
        int positionX = minHeight/4 * (i%4);
        
        thumbnail.frame = CGRectMake(positionX,positionY,minHeight/4,maxHeight/6);
        [thumbnail addTarget:self action:@selector(buttonClicked:) forControlEvents:UIControlEventTouchUpInside];
        thumbnail.tag = i;
        self.scrollView.contentSize = CGSizeMake(self.scrollView.frame.size.width, ((i)/4 + 1) * maxHeight/6);
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
    float maxHeight = MAX([[UIScreen mainScreen] bounds].size.height, [[UIScreen mainScreen] bounds].size.width);
    float minHeight = MIN([[UIScreen mainScreen] bounds].size.height, [[UIScreen mainScreen] bounds].size.width);
    for(int i = initialImagesLoaded; i <[self.results count] + 1; i++){
        if(i < [self.results count]){
            NSDictionary *initial = [self.results objectAtIndex:i];
            
            UIButton *thumbnail = [UIButton buttonWithType:UIButtonTypeCustom];
            [thumbnail setImage:[UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://i.imgur.com/%@s.jpg",[initial objectForKey:@"hash"]]]]] forState:UIControlStateNormal];
            int positionY = maxHeight/6 * (i/4);
            int positionX = minHeight/4 * (i%4);
            thumbnail.frame = CGRectMake(positionX,positionY,minHeight/4,maxHeight/6);
            [thumbnail addTarget:self action:@selector(buttonClicked:) forControlEvents:UIControlEventTouchUpInside];
            thumbnail.tag = i;
            
            [self.scrollView addSubview:thumbnail];
            
            self.scrollView.contentSize = CGSizeMake(self.scrollView.frame.size.width, ((i)/4 + 1) * maxHeight/6);
        }
        else {
        }

        
    }
    [self.activityView stopAnimating];
    pagesLoaded ++;
    [self.thread cancel];
}

-(void) loadNewPickerView{
    [self.searchBar setHidden:YES];
    [self.searchBtn setStyle:UIBarStyleBlack];
    GADRequest *r = [[GADRequest alloc] init];
    [self.admobView loadRequest:r];
    float maxHeight = MAX([[UIScreen mainScreen] bounds].size.height, [[UIScreen mainScreen] bounds].size.width);
    float minHeight = MIN([[UIScreen mainScreen] bounds].size.height, [[UIScreen mainScreen] bounds].size.width);
    [self.nxtBtn setEnabled:YES];
    [self.searchBar setText:@""];
    pageNo = 0;
    [self.activityView startAnimating];
    [self.activityView setHidden:NO];
    [self.view setUserInteractionEnabled:NO];
    self.currentViewTitle = @"new";
    self.imageController = [[ViewController alloc] initWithNibName:@"ViewController" bundle:nil];
    [self.scrollView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    self.scrollView.frame = CGRectMake(0, 0, minHeight, maxHeight - 158);
    [self.scrollView setContentOffset:CGPointMake(0, 0)];
    self.responseData = [NSMutableData data];
    self.results = [NSMutableArray array];  
    NSURLRequest *request = [NSURLRequest requestWithURL:  
                             [NSURL URLWithString:@"http://imgur.com/gallery/new.json"]];  
    (void) [[NSURLConnection alloc] initWithRequest:request delegate:self];
    pagesLoaded = 2;
    
};

-(void) loadHotPickerView{
    [self.searchBar setHidden:YES];
    [self.searchBtn setStyle:UIBarStyleBlack];
    GADRequest *r = [[GADRequest alloc] init];
    [self.admobView loadRequest:r];
    float maxHeight = MAX([[UIScreen mainScreen] bounds].size.height, [[UIScreen mainScreen] bounds].size.width);
    float minHeight = MIN([[UIScreen mainScreen] bounds].size.height, [[UIScreen mainScreen] bounds].size.width);
    [self.nxtBtn setEnabled:YES];
    [self.searchBar setText:@""];
    pageNo = 0;
    [self.activityView startAnimating];
    [self.activityView setHidden:NO];
    [self.view setUserInteractionEnabled:NO];
    self.currentViewTitle = @"hot";
    self.imageController = [[ViewController alloc] initWithNibName:@"ViewController" bundle:nil];
    [self.scrollView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    self.scrollView.frame = CGRectMake(0, 0, minHeight, maxHeight - 158);
    [self.scrollView setContentOffset:CGPointMake(0, 0)];
    self.responseData = [NSMutableData data];
    self.results = [NSMutableArray array];  
    NSURLRequest *request = [NSURLRequest requestWithURL:  
                             [NSURL URLWithString:@"http://imgur.com/gallery/hot.json"]];  
    (void) [[NSURLConnection alloc] initWithRequest:request delegate:self];
    pagesLoaded = 1;
    
};

-(void) loadTopPickerView{
    [self.searchBar setHidden:YES];
    [self.searchBtn setStyle:UIBarStyleBlack];
    GADRequest *r = [[GADRequest alloc] init];
    [self.admobView loadRequest:r];
    float maxHeight = MAX([[UIScreen mainScreen] bounds].size.height, [[UIScreen mainScreen] bounds].size.width);
    float minHeight = MIN([[UIScreen mainScreen] bounds].size.height, [[UIScreen mainScreen] bounds].size.width);
    [self.nxtBtn setEnabled:YES];
    [self.searchBar setText:@""];
    pageNo = 0;
    [self.activityView startAnimating];
    [self.activityView setHidden:NO];
    [self.view setUserInteractionEnabled:NO];
    self.currentViewTitle = @"top";
    self.imageController = [[ViewController alloc] initWithNibName:@"ViewController" bundle:nil];
    [self.scrollView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    self.scrollView.frame = CGRectMake(0, 0, minHeight, maxHeight - 158);
    [self.scrollView setContentOffset:CGPointMake(0, 0)];
    self.responseData = [NSMutableData data];
    self.results = [NSMutableArray array];  
    NSURLRequest *request = [NSURLRequest requestWithURL:  
                             [NSURL URLWithString:@"http://imgur.com/gallery/top.json"]];  
    (void) [[NSURLConnection alloc] initWithRequest:request delegate:self];
    pagesLoaded = 1;
    
};

-(void) reloadView{
    [self.searchBar setHidden:YES];
    [self.searchBtn setStyle:UIBarStyleBlack];
    pageNo = 0;
    [self.activityView startAnimating];
    [self.activityView setHidden:NO];
    [self.view setUserInteractionEnabled:NO];
    if([self.currentViewTitle isEqualToString:@"new"]){
        [self loadNewPickerView];
    }else if([self.currentViewTitle isEqualToString:@"top"]){
        [self loadTopPickerView];
    }else if([self.currentViewTitle isEqualToString:@"Search Results"]){
        [self loadSearchResults];
    }else{
        [self loadHotPickerView];
    }
    GADRequest *r = [[GADRequest alloc] init];
    [self.admobView loadRequest:r];
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
    [self.searchBar setHidden:YES];
    [self.searchBtn setStyle:UIBarStyleBlack];
    GADRequest *r = [[GADRequest alloc] init];
    [self.admobView loadRequest:r];
    float maxHeight = MAX([[UIScreen mainScreen] bounds].size.height, [[UIScreen mainScreen] bounds].size.width);
    float minHeight = MIN([[UIScreen mainScreen] bounds].size.height, [[UIScreen mainScreen] bounds].size.width);
    pageNo++;
    [self.activityView startAnimating];
    [self.activityView setHidden:NO];
    [self.view setUserInteractionEnabled:NO];
    [self.activityView startAnimating];
    [self.activityView setHidden:NO];
    [self.view setUserInteractionEnabled:NO];
    self.imageController = [[ViewController alloc] initWithNibName:@"ViewController" bundle:nil];
    [self.scrollView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    self.scrollView.frame = CGRectMake(0, 0, minHeight, maxHeight - 158);
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
    float minHeight = MIN([[UIScreen mainScreen] bounds].size.height, [[UIScreen mainScreen] bounds].size.width);
    UIButton *button = (UIButton *)sender;
    self.imageController.currentPage = [NSString stringWithFormat:@"%i",button.tag];
    self.imageController.results = self.results;
    if(self.imageController.scrollView.subviews > 0){
        NSDictionary *initial = [self.imageController.results objectAtIndex:button.tag];
        [self.imageController.scrollView setContentOffset:CGPointMake(minHeight * button.tag, 0)];
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

-(void)showSearchBar{
    if(self.searchBar.isHidden){
        [self.searchBar setHidden:NO];
        [self.searchBtn setStyle:UIBarStyleBlackTranslucent];
    }else{
        [self.searchBar setHidden:YES];
        [self.searchBtn setStyle:UIBarStyleBlack];
    }

}
- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar{
    [self.searchBar resignFirstResponder];
    [self.searchBar setHidden:YES];
    [self.searchBtn setStyle:UIBarStyleBlack];
    if(self.searchBar.text.length == 0 && self.nxtBtn.isEnabled == NO){
        [self reloadView];
        [self.nxtBtn setEnabled:YES];
    };
};
- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar{
    [self loadSearchResults];
};
- (void)adView:(GADBannerView *)bannerView
didFailToReceiveAdWithError:(GADRequestError *)error {
    [self.scrollView setFrame:CGRectMake(self.scrollView.frame.origin.x, self.scrollView.frame.origin.y, self.scrollView.frame.size.width, self.scrollView.frame.size.width + 50)];
    [self.admobView setHidden:YES];
}
- (void) loadSearchResults{
    self.currentViewTitle = @"Search Results";
    GADRequest *r = [[GADRequest alloc] init];
    [self.admobView loadRequest:r];
    float maxHeight = MAX([[UIScreen mainScreen] bounds].size.height, [[UIScreen mainScreen] bounds].size.width);
    float minHeight = MIN([[UIScreen mainScreen] bounds].size.height, [[UIScreen mainScreen] bounds].size.width);
    [self.nxtBtn setEnabled:NO];
    [self.searchBar resignFirstResponder];
    pageNo = 0;
    [self.activityView startAnimating];
    [self.activityView setHidden:NO];
    [self.view setUserInteractionEnabled:NO];
    self.imageController = [[ViewController alloc] initWithNibName:@"ViewController" bundle:nil];
    [self.scrollView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    self.scrollView.frame = CGRectMake(0, 0, minHeight, maxHeight - 158);
    [self.scrollView setContentOffset:CGPointMake(0, 0)];
    self.responseData = [NSMutableData data];
    self.results = [NSMutableArray array];
    NSURLRequest *request = [NSURLRequest requestWithURL:
                             [NSURL URLWithString:[NSString stringWithFormat:@"http://imgur.com/gallery/new.json?q=%@", [self.searchBar.text stringByReplacingOccurrencesOfString:@" " withString:@"+"]]]];
    (void) [[NSURLConnection alloc] initWithRequest:request delegate:self];
    pagesLoaded = 1;
};
@end
