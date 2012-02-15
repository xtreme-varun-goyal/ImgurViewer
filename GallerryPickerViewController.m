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

@interface GallerryPickerViewController ()
-(void) loadMoreImages;
-(void) loadNewPickerView;
-(void) loadHotPickerView;
-(void) loadTopPickerView;
-(void) reloadView;
@end

@implementation GallerryPickerViewController

@synthesize results = _results, responseData = _responseData,scrollView = _scrollView,imageController = _imageController,activityView = _activityView, thread = _thread, hotButton = _hotButton, topBtn = _topBtn, latestBtn = _latestBtn,reldButton = _reldButton, currentViewTitle = _currentViewTitle;
int pagesLoaded;
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
    if(!viewloaded){
        NSURLRequest *request = [NSURLRequest requestWithURL:  
                                 [NSURL URLWithString:@"http://imgur.com/gallery/new.json"]];  
        (void) [[NSURLConnection alloc] initWithRequest:request delegate:self];
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.currentViewTitle = @"New";
    [self.hotButton setAction:@selector(loadHotPickerView)];
    [self.topBtn setAction:@selector(loadTopPickerView)];
    [self.latestBtn setAction:@selector(loadNewPickerView)];
    [self.reldButton setAction:@selector(reloadView)];
    self.thread = [[NSThread alloc] initWithTarget:self selector:@selector(loadMoreImages) object:nil];
    self.imageController = [[ViewController alloc] initWithNibName:@"ViewController" bundle:nil];
    [self.activityView setHidden:NO];
    [self.activityView startAnimating];
    UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"background.png"]];
    imageView.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
    [self.view addSubview:imageView];
    [self.view sendSubviewToBack:imageView];
    self.responseData = [NSMutableData data];
    self.results = [NSMutableArray array];  
   
    NSURLRequest *request = [NSURLRequest requestWithURL:  
                             [NSURL URLWithString:@"http://imgur.com/gallery/new.json"]];  
    (void) [[NSURLConnection alloc] initWithRequest:request delegate:self];
    pagesLoaded = 2;
    
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
    UIAlertView *alertNetwork = [[UIAlertView alloc] initWithTitle:@"No network connection" message:@"The app couldn't load, please check your internet connections and reopen the app" delegate:self cancelButtonTitle:@"Dismiss" otherButtonTitles:nil, nil];
    [alertNetwork show];
    [self.view setUserInteractionEnabled:YES];
    [self.scrollView setUserInteractionEnabled:NO];
}  

- (void)connectionDidFinishLoading:(NSURLConnection *)connection { 
    [self.view setUserInteractionEnabled:YES];
    pagesLoaded = 2;
    NSString *responseString = [[NSString alloc] initWithData:self.responseData encoding:NSUTF8StringEncoding]; 
    NSArray *resultsArray = [(NSDictionary*)[responseString JSONValue] objectForKey:@"gallery"];
    if([resultsArray count] < 10){
        [self connection:connection didFailWithError:nil];
        return;
    }
    self.results = resultsArray;
    int frameWidth = self.scrollView.frame.size.width;
    [self.scrollView setContentSize:CGSizeMake(frameWidth, self.scrollView.frame.size.height * 2)];
    for(int i = 0; i < 20 ; i++){
        NSDictionary *initial = [self.results objectAtIndex:i];
        
        UIButton *thumbnail = [UIButton buttonWithType:UIButtonTypeCustom];
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
        {
            [thumbnail setImage:[UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://i.imgur.com/%@m.jpg",[initial objectForKey:@"hash"]]]]] forState:UIControlStateNormal];

        }
        else
        {
            [thumbnail setImage:[UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://i.imgur.com/%@s.jpg",[initial objectForKey:@"hash"]]]]] forState:UIControlStateNormal];

        }
                int thumbWidth = (self.scrollView.frame.size.width/4);
        int positionY = thumbWidth * (i/4);
        int positionX = thumbWidth * (i%4);
        
        thumbnail.frame = CGRectMake(positionX,positionY,thumbWidth,thumbWidth);
        [thumbnail addTarget:self action:@selector(buttonClicked:) forControlEvents:UIControlEventTouchUpInside];
        thumbnail.tag = i;
        
        [self.scrollView addSubview:thumbnail];
        
    }
    self.thread = [[NSThread alloc] initWithTarget:self selector:@selector(loadMoreImages) object:nil];
    [self.thread start];
    
    [self.activityView setHidden:YES];
    [self.activityView stopAnimating];
}

- (IBAction)buttonClicked:(id)sender{
    [self.activityView setColor:[UIColor redColor]];
    [self.activityView startAnimating];
    [self.activityView setHidden:NO];
    UIButton *button = (UIButton *)sender;
    self.imageController.currentPage = [NSString stringWithFormat:@"%i",button.tag];
    self.imageController.results = self.results;
    UIImageView *curView = [self.imageController.scrollView.subviews objectAtIndex:button.tag];
    if(self.imageController.scrollView.subviews > 0){
        NSDictionary *initial = [self.imageController.results objectAtIndex:button.tag];
        if(!curView.image){
            [self.imageController loadMoreImages];
        }
        [self.imageController.scrollView setContentOffset:CGPointMake(320 * button.tag, 0)];
        id isTextNull = [initial objectForKey:@"title"];
        if(isTextNull != [NSNull null]){
            self.imageController.textView.text = [initial objectForKey:@"title"];
        }else{
            self.imageController.textView.text = @"";
        }
            
    };
    [self.navigationController pushViewController:self.imageController animated:YES];
//    [self presentModalViewController:self.imageController animated:YES];
};

-(void) loadMoreImages{
//    int height = MIN(480 * (pagesLoaded + 1), ([self.results count]/4 + 1) * 80);
//    self.scrollView.contentSize = CGSizeMake(self.scrollView.frame.size.width, height);
    for(int i = 20; [self.scrollView.subviews count] <[self.results count]; i++){
        if(i < [self.results count]){
            NSDictionary *initial = [self.results objectAtIndex:i];
            
            UIButton *thumbnail = [UIButton buttonWithType:UIButtonTypeCustom];
            if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
            {
                [thumbnail setImage:[UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://i.imgur.com/%@m.jpg",[initial objectForKey:@"hash"]]]]] forState:UIControlStateNormal];
                
            }
            else
            {
                [thumbnail setImage:[UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://i.imgur.com/%@s.jpg",[initial objectForKey:@"hash"]]]]] forState:UIControlStateNormal];
            }
            int thumbWidth = (self.scrollView.frame.size.width/4);
            int thumbHeight = (self.scrollView.frame.size.height/4);
            int positionY = thumbWidth * (i/4);
            int positionX = thumbWidth * (i%4);
            
            thumbnail.frame = CGRectMake(positionX,positionY,thumbWidth,thumbWidth);
            [thumbnail addTarget:self action:@selector(buttonClicked:) forControlEvents:UIControlEventTouchUpInside];
            thumbnail.tag = i;
            
            [self.scrollView addSubview:thumbnail];
            
            self.scrollView.contentSize = CGSizeMake(self.scrollView.frame.size.width, ((i)/4 + 1) * thumbWidth);
        }
        
    }
    //        [self.activityView stopAnimating];
    pagesLoaded ++;
    [self.thread cancel];
}

-(void) loadNewPickerView{
    [self.view setUserInteractionEnabled:NO];
    self.currentViewTitle = @"New";
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
    [self.view setUserInteractionEnabled:NO];
    self.currentViewTitle = @"Hot";
    self.imageController = [[ViewController alloc] initWithNibName:@"ViewController" bundle:nil];
    [self.scrollView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    self.scrollView.frame = CGRectMake(0, 44, 320, 372);
    [self.scrollView setContentOffset:CGPointMake(0, 0)];
    self.responseData = [NSMutableData data];
    self.results = [NSMutableArray array];  
    NSURLRequest *request = [NSURLRequest requestWithURL:  
                             [NSURL URLWithString:@"http://imgur.com/gallery/hot.json"]];  
    (void) [[NSURLConnection alloc] initWithRequest:request delegate:self];
    pagesLoaded = 2;

};

-(void) loadTopPickerView{
    [self.view setUserInteractionEnabled:NO];
    self.currentViewTitle = @"Top";
    self.imageController = [[ViewController alloc] initWithNibName:@"ViewController" bundle:nil];
    [self.scrollView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    self.scrollView.frame = CGRectMake(0, 44, self.scrollView.frame.size.width, self.scrollView.frame.size.height);
    [self.scrollView setContentOffset:CGPointMake(0, 0)];
    self.responseData = [NSMutableData data];
    self.results = [NSMutableArray array];  
    NSURLRequest *request = [NSURLRequest requestWithURL:  
                             [NSURL URLWithString:@"http://imgur.com/gallery/top.json"]];  
    (void) [[NSURLConnection alloc] initWithRequest:request delegate:self];
    pagesLoaded = 2;
    
};

-(void) reloadView{
    [self.view setUserInteractionEnabled:NO];
    if([self.currentViewTitle isEqualToString:@"New"]){
        [self loadNewPickerView];
    }else if([self.currentViewTitle isEqualToString:@"Top"]){
        [self loadTopPickerView];
    }else{
        [self loadHotPickerView];
    }
};

@end
