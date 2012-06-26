//
//  FBSharedViewController.m
//  ImgurViewer
//
//  Created by Varun Goyal on 12-03-22.
//  Copyright (c) 2012 University of Waterloo. All rights reserved.
//

#import "FBSharedViewController.h"
#import "GifAnimatedView.h"
#import "ImageFullScreenController.h"
#import "SBJson.h"

@interface FBSharedViewController()
-(void)loadCaptions;
@end

@implementation FBSharedViewController
@synthesize results = _results, responseData = _responseData, hash = _hash,tableView = _tableView,imageView = _imageView,scrollViewImage = _scrollViewImage, viewScroll = _viewScroll;

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
    self.scrollViewImage = [[UIScrollView alloc] init];
    self.viewScroll = [[UIScrollView alloc] init];
    self.tableView = [[UITableView alloc] init];
    [self.tableView setRowHeight:70.0];
    if(!self.imageView.image)
    {
        self.imageView = [[UIImageView alloc] initWithImage:[UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://imgur.com/%@.jpg",self.hash]]]]];
    };
    UIDeviceOrientation *toInterfaceOrientation = [[UIDevice currentDevice] orientation];
    if (toInterfaceOrientation == UIInterfaceOrientationLandscapeLeft ||
        toInterfaceOrientation == UIInterfaceOrientationLandscapeRight)
    {
//        self.view.frame = CGRectMake(0, 0, 480, 320);
        self.scrollViewImage.frame = CGRectMake(0, 0, 480, 320);
        self.tableView.frame = CGRectMake(0,320,480, 320);
        self.viewScroll.frame = CGRectMake(0, 0, 480, 320);
        self.viewScroll.contentSize = CGSizeMake(480, 640);
        self.imageView.frame = self.scrollViewImage.frame;
    }
    else
    {
//        self.view.frame = CGRectMake(0, 0, 320,480);
        self.imageView.frame = CGRectMake(0, 0, 320,480);
        self.scrollViewImage.frame = CGRectMake(0, 0, 320,480);
        self.tableView.frame = CGRectMake(0, 480, 320, 480);
        self.viewScroll.frame = CGRectMake(0, 0, 320, 480);
        [self.viewScroll setContentSize:CGSizeMake(320, 960)];
    }
    [self.imageView setContentMode:UIViewContentModeScaleAspectFit];
    [[UIApplication sharedApplication] setStatusBarHidden:YES];
    UIImageView *backgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"background.png"]];
    [self.view addSubview:backgroundView];
    [self.view sendSubviewToBack:backgroundView];
    [self.scrollViewImage addSubview:self.imageView];
    self.scrollViewImage.delegate = self;
    self.scrollViewImage.minimumZoomScale=1.0;
    self.scrollViewImage.maximumZoomScale=3.0;

    [self.view addSubview:self.viewScroll];
    [self.viewScroll setScrollEnabled:YES];
    self.tableView.delegate = self;
      self.tableView.dataSource = self;
    [self.tableView setBounces:NO];
    self.viewScroll.delegate = self;
    self.imageView.frame = self.scrollViewImage.frame;
    [self.tableView setBackgroundColor:[UIColor clearColor]];
    [self.viewScroll addSubview:self.scrollViewImage];
    [self.viewScroll addSubview:self.tableView];
    [self.viewScroll setShowsVerticalScrollIndicator:NO];
    UITapGestureRecognizer* SingleTap = [[UITapGestureRecognizer alloc] initWithTarget : self action : @selector (handleSingleTap:)];
    [SingleTap setDelaysTouchesBegan : YES];
    
    [SingleTap setNumberOfTapsRequired : 1];
    backgroundView.frame = self.view.frame;
    
    [self.scrollViewImage addGestureRecognizer : SingleTap];
    
    self.responseData = [NSMutableData data];  
    self.results = [NSMutableArray array]; 

//    NSThread *loadTable = [[NSThread alloc] initWithTarget:self selector:@selector(loadCaptions) object:nil];
    [self loadCaptions];
     //  
        // Do any additional setup after loading the view from its nib.
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [[UIApplication sharedApplication] setStatusBarHidden:YES];
    UIDeviceOrientation *toInterfaceOrientation = [[UIDevice currentDevice] orientation];
    if (toInterfaceOrientation == UIInterfaceOrientationLandscapeLeft ||
        toInterfaceOrientation == UIInterfaceOrientationLandscapeRight)
    {
        self.view.frame = CGRectMake(0, 0, 480,320);
        self.scrollViewImage.frame = CGRectMake(0, 0, 480, 320);
        self.tableView.frame = CGRectMake(0,320,480, 320);
        self.viewScroll.frame = CGRectMake(0, 0, 480, 320);
        self.viewScroll.contentSize = CGSizeMake(480, 640);
        self.imageView.frame = CGRectMake(0, 0, 320,480);
    }
    else
    {
        self.view.frame = CGRectMake(0, 0, 320, 480);
        self.imageView.frame = CGRectMake(0, 0, 320,480);
        self.scrollViewImage.frame = CGRectMake(0, 0, 320,480);
        self.tableView.frame = CGRectMake(0, 480, 320, 480);
        self.viewScroll.frame = CGRectMake(0, 0, 320, 480);
        [self.viewScroll setContentSize:CGSizeMake(320, 960)];
    }
    ((UIImageView*)[self.view.subviews objectAtIndex:0]).frame = self.scrollViewImage.frame;
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return true;
}

#pragma mark UITableView Delegate methods 
- (NSInteger)tableView:(UITableView *)tableView 
 numberOfRowsInSection:(NSInteger)section {
    return [self.results count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView 
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    // Attempt to request the reusable cell.
    int i = indexPath.row;
	UITableViewCell *cell = [[UITableViewCell alloc] initWithFrame:CGRectMake(self.tableView.frame.size.width*i, 60 * i, self.tableView.frame.size.width, 70)];
    if([self.results objectAtIndex:i]){
        NSDictionary *initial = [self.results objectAtIndex:i] ;
        CGRect contentRect = CGRectMake(10,0, self.tableView.frame.size.width - 20, 70);
        UILabel *textView = [[UILabel alloc] initWithFrame:contentRect];
        NSString *caption = [initial objectForKey:@"caption"];
        if (([caption rangeOfString:@".gif"].location != NSNotFound || [caption rangeOfString:@".jpg"].location != NSNotFound || [caption rangeOfString:@".png"].location != NSNotFound) && [caption rangeOfString:@"http://"].location != NSNotFound) {
            cell.userInteractionEnabled = YES;
            [cell setSelectionStyle:UITableViewCellSelectionStyleBlue];
        }
        else{
            cell.userInteractionEnabled = NO;
        }
        //        [cell 
        textView.text = [NSString stringWithFormat:@"%@ - %@",[initial objectForKey:@"author"],[initial objectForKey:@"caption"]];
        textView.numberOfLines = 4;
        textView.textColor = [UIColor whiteColor];
        textView.font = [UIFont systemFontOfSize:15];
        textView.backgroundColor = [UIColor clearColor];
        self.view.backgroundColor = [UIColor clearColor];
        textView.minimumFontSize = 10;
        [cell.contentView addSubview:textView];
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView 
didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *initial = [self.results objectAtIndex:indexPath.row] ;
    NSString *caption = [initial objectForKey:@"caption"];
    if ([caption rangeOfString:@".gif"].location != NSNotFound) {
        GifAnimatedView *fullWebView = [[GifAnimatedView alloc] init];
        int locStr = [caption rangeOfString:@".gif" options:NSBackwardsSearch].location;
        int lochttp = [caption rangeOfString:@"http"].location;
        NSString *subUrl = [caption substringWithRange:NSMakeRange(lochttp, (locStr-lochttp)+4)];
        fullWebView.url = subUrl;
        [self presentModalViewController:fullWebView animated:NO];
    }else if([caption rangeOfString:@".jpg"].location != NSNotFound){
        ImageFullScreenController *fullJpgView = [[ImageFullScreenController alloc] init];
        int locStr = [caption rangeOfString:@".jpg"].location;
        int lochttp = [caption rangeOfString:@"http"].location;
        NSString *subUrl = [caption substringWithRange:NSMakeRange(lochttp, (locStr-lochttp)+4)];
        UIImage *image = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:subUrl]]];
        fullJpgView.imageView = [[UIImageView alloc] initWithImage:image];
        [self presentModalViewController:fullJpgView animated:NO];
    }else if([caption rangeOfString:@".png"].location != NSNotFound){
        ImageFullScreenController *fullJpgView = [[ImageFullScreenController alloc] init];
        int locStr = [caption rangeOfString:@".png"].location;
        int lochttp = [caption rangeOfString:@"http"].location;
        NSString *subUrl = [caption substringWithRange:NSMakeRange(lochttp, (locStr-lochttp)+4)];
        UIImage *image = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:subUrl]]];
        fullJpgView.imageView = [[UIImageView alloc] initWithImage:image];
        [self presentModalViewController:fullJpgView animated:NO];
    }
}         

#pragma mark NSURLConnection Delegate methods  
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    [self.responseData setLength:0];  
}  

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {  
    [self.responseData appendData:data];  
}  

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {  
    //    self.label.text = [NSString stringWithFormat:@"Connection failed: %@", [error description]];  
}  

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {  
    NSString *responseString = [[NSString alloc] initWithData:self.responseData encoding:NSUTF8StringEncoding]; 
    NSArray *resultsArray = [[(NSDictionary*)[responseString JSONValue] objectForKey:@"gallery"] objectForKey:@"captions"];
    self.results = resultsArray;
    [self.tableView reloadData];
}

#pragma Zoom implementation

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
    [scrollView setBouncesZoom:NO];
    return self.imageView;
}

- (CGRect)zoomRectForScrollView:(UIScrollView *)scrollView withScale:(float)scale withCenter:(CGPoint)center {
    
    CGRect zoomRect;
    
    // The zoom rect is in the content view's coordinates.
    // At a zoom scale of 1.0, it would be the size of the
    // imageScrollView's bounds.
    // As the zoom scale decreases, so more content is visible,
    // the size of the rect grows.
    zoomRect.size.height = self.scrollViewImage.frame.size.height / scale;
    //    zoomRect.size.width  = self.scrollView.frame.size.width  / scale;
    zoomRect.size.width = self.view.frame.size.width;
    
    // choose an origin so as to get the right center.
    zoomRect.origin.x = center.x - (zoomRect.size.width  / 2.0);
    zoomRect.origin.y = center.y - (zoomRect.size.height / 2.0);
    
    return zoomRect;
    
}

- (void) handleSingleTap : (UIGestureRecognizer*) sender
{
    [[UIApplication sharedApplication] setStatusBarHidden:NO];
    [self.navigationController popViewControllerAnimated:YES];
    [self dismissModalViewControllerAnimated:NO];
}

- (void)willAnimateRotationToInterfaceOrientation:
(UIInterfaceOrientation)toInterfaceOrientation 
                                         duration:(NSTimeInterval)duration
{
    if (toInterfaceOrientation == UIInterfaceOrientationLandscapeLeft ||
        toInterfaceOrientation == UIInterfaceOrientationLandscapeRight)
    {
        
        self.scrollViewImage.frame = CGRectMake(0, 0, 480, 320);
        self.tableView.frame = CGRectMake(0,320,480, 320);
        self.viewScroll.frame = CGRectMake(0, 0, 480, 320);
        self.viewScroll.contentSize = CGSizeMake(480, 640);
        self.imageView.frame = self.scrollViewImage.frame;
    }
    else
    {
        self.imageView.frame = CGRectMake(0, 0, 320,480);
        self.scrollViewImage.frame = CGRectMake(0, 0, 320,480);
        self.tableView.frame = CGRectMake(0, 480, 320, 480);
        self.viewScroll.frame = CGRectMake(0, 0, 320, 480);
        [self.viewScroll setContentSize:CGSizeMake(320, 960)];
    }
    ((UIImageView*)[self.view.subviews objectAtIndex:0]).frame = self.scrollViewImage.frame;
    [self.tableView reloadData];
}

-(void)loadCaptions{ 
    NSURLRequest *request = [NSURLRequest requestWithURL:  
                             [NSURL URLWithString:[NSString stringWithFormat:@"http://imgur.com/gallery/%@.json",self.hash]]];  
    (void) [[NSURLConnection alloc] initWithRequest:request delegate:self];

};

@end
