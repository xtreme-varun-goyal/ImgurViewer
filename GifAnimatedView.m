//
//  GifAnimatedView.m
//  ImgurViewer
//
//  Created by Varun Goyal on 12-02-12.
//  Copyright (c) 2012 University of Waterloo. All rights reserved.
//

#import "GifAnimatedView.h"
#import "ImageFullScreenController.h"
#import "GifViewController.h"
#import "SBJson.h"

@interface  GifAnimatedView ()
-(void) loadCaptions;
@end

@implementation GifAnimatedView
@synthesize webView = _webView, imageId = _imageId, imageWidth = _imageWidth, imageHeight = _imageHeight, url = _url,results = _results, responseData = _responseData,tableView = _tableView, viewScroll = _viewScroll, hash = _hash;

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
- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [[UIApplication sharedApplication] setStatusBarHidden:YES];
    if(self.view.subviews.count !=0){
        UIInterfaceOrientation *orient = [[UIDevice currentDevice] orientation];
        [self willAnimateRotationToInterfaceOrientation:orient duration:0.0];
    };

}
- (void)viewDidLoad
{
    UIImageView *backgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"background.png"]];
    [self.view addSubview:backgroundView];
    self.viewScroll = [[UIScrollView alloc] init];
    self.tableView = [[UITableView alloc] init];
    [self.tableView setRowHeight:70.0];
    if(self.view.subviews.count !=0){
        UIInterfaceOrientation *orient = [[UIDevice currentDevice] orientation];
        [self willAnimateRotationToInterfaceOrientation:orient duration:0.0];
    }
    [backgroundView sizeToFit];
    self.webView = [[UIWebView alloc] init];
    self.webView.delegate = self;
    //   self.imageHeight = [NSString stringWithFormat:@"%f",MIN(image.size.height,480.0)];
    //    self.imageWidth = [NSString stringWithFormat:@"%f",MIN(image.size.width,320.0)];
    UIImage *image = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://i.imgur.com/%@.gif",self.imageId]]]];
    if(self.imageHeight > 0){
        float actualHeight = image.size.height;
        float actualWidth = image.size.width;
        float imgRatio = actualWidth/actualHeight;
        float maxRatio = 320.0/480.0;
        int height;
        int width;
        if(imgRatio!=maxRatio){
            if(imgRatio < maxRatio){
                imgRatio = 480.0 / actualHeight;
                actualWidth = imgRatio * actualWidth;
                actualHeight = 480.0;
            }
            else{
                imgRatio = 320.0 / actualWidth;
                actualHeight = imgRatio * actualHeight;
                actualWidth = 320.0;
            }
            height = MIN(image.size.height,actualHeight);
            width = MIN(image.size.width,actualWidth);
        }
        else{
            height = MIN(image.size.height,480);
            width = MIN(image.size.width,320);
        }
        self.webView.frame = CGRectMake((320-width)/2,(480 - height)/2,width,height);
        NSLog([NSString stringWithFormat:@"Width -> %f Height-> - %f",self.webView.frame.size.width,self.webView.frame.size.height]);
        [self.webView loadRequest: [NSURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://i.imgur.com/%@.gif",self.imageId]]]];
        self.view.frame = CGRectMake(0, 0, 320,480);
        self.tableView.frame = CGRectMake(0, 480, 320, 480);
        self.viewScroll.frame = CGRectMake(0, 0, 320, 480);
        [self.viewScroll setContentSize:CGSizeMake(320, 960)];
        [self.viewScroll addSubview:self.tableView];
    }else{
        image = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:self.url]]];
        float actualHeight = image.size.height;
        float actualWidth = image.size.width;
        float imgRatio = actualWidth/actualHeight;
        float maxRatio = 320.0/480.0;
        int height;
        int width;
        if(imgRatio!=maxRatio){
            if(imgRatio < maxRatio){
                imgRatio = 480.0 / actualHeight;
                actualWidth = imgRatio * actualWidth;
                actualHeight = 480.0;
            }
            else{
                imgRatio = 320.0 / actualWidth;
                actualHeight = imgRatio * actualHeight;
                actualWidth = 320.0;
            }
            height = MIN(image.size.height,actualHeight);
            width = MIN(image.size.width,actualWidth);
        }
        else{
            height = MIN(image.size.height,480);
            width = MIN(image.size.width,320);
        }
        
        self.webView.frame = CGRectMake((320-width)/2,(480-height)/2,width,height);
        [self.webView setHidden:YES];
        [self.webView loadRequest: [NSURLRequest requestWithURL:[NSURL URLWithString:self.url]]];
        self.view.frame = CGRectMake(0, 0, 320,480);
        self.tableView.frame = CGRectMake(0, 480, 320, 480);
        self.viewScroll.frame = CGRectMake(0, 0, 320, 480);
        [self.viewScroll setContentSize:CGSizeMake(320, 480)];
    }
    
    [self.webView.scrollView setBackgroundColor:[UIColor clearColor]];
    [self.webView setBackgroundColor:[UIColor clearColor]];
    [self.webView setUserInteractionEnabled:YES];
    [self.webView.scrollView setUserInteractionEnabled:NO];
    [self.webView setContentMode:UIViewContentModeCenter];
    UITapGestureRecognizer* SingleTap = [[UITapGestureRecognizer alloc] initWithTarget : self action : @selector (handleSingleTap:)];
    [SingleTap setDelaysTouchesBegan : YES];
    
    [SingleTap setNumberOfTapsRequired : 1];
    
    [self.webView addGestureRecognizer : SingleTap];
    [[UIApplication sharedApplication] setStatusBarHidden:YES];
    if(image.size.width>self.webView.frame.size.width || image.size.height > self.webView.frame.size.height){     
        [self.webView setScalesPageToFit:YES];
    }
    
    if(image.size.width == 0){
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Invalid Link" message:@"Unable to load" delegate:self cancelButtonTitle:@"dismiss" otherButtonTitles:nil, nil];
        [alert show];
    }
    [self.viewScroll addSubview:self.webView];
    [self.view addSubview:self.viewScroll];
    [self.viewScroll setScrollEnabled:YES];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    [self.tableView setBounces:NO];
    self.viewScroll.delegate = self;
    [self.tableView setBackgroundColor:[UIColor clearColor]];
    
    [self.viewScroll setShowsVerticalScrollIndicator:NO];
    
    self.responseData = [NSMutableData data];  
    self.results = [NSMutableArray array]; 
    backgroundView.frame = self.view.frame;
    if([self.tableView.superview isEqual:self.viewScroll]){
        [self loadCaptions];
    }
    // Do any additional setup after loading the view from its nib.
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void) handleSingleTap : (UIGestureRecognizer*) sender
{
    [[UIApplication sharedApplication] setStatusBarHidden:NO];
    [self dismissModalViewControllerAnimated:NO];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return true;
}

- (void)willAnimateRotationToInterfaceOrientation:
(UIInterfaceOrientation)toInterfaceOrientation 
                                         duration:(NSTimeInterval)duration
{
    if (toInterfaceOrientation == UIInterfaceOrientationLandscapeLeft ||
        toInterfaceOrientation == UIInterfaceOrientationLandscapeRight){

        if(self.imageWidth > 0){
            self.webView.frame = CGRectMake((480-[self.imageWidth intValue])/2,(320 - [self.imageHeight intValue])/2,[self.imageWidth intValue],[self.imageHeight intValue]);
        }else{
            self.webView.frame = CGRectMake((480-self.webView.frame.size.width)/2,(320-self.webView.frame.size.height)/2,self.webView.frame.size.width,self.webView.frame.size.height);
        }

        self.viewScroll.frame = CGRectMake(0, 0, 480, 320);
        self.viewScroll.contentSize = CGSizeMake(480, 320);
        if([self.tableView.superview isEqual:self.viewScroll]){
            self.tableView.frame = CGRectMake(0,320,480, 320);
            self.viewScroll.contentSize = CGSizeMake(480, 640);
        }
        ((UIImageView*)[self.view.subviews objectAtIndex:0]).frame = CGRectMake(0, 0, 480, 320);
    }
    else
    {
        if(self.imageWidth >0){
            self.webView.frame =  CGRectMake((320-[self.imageWidth intValue])/2,(480 - [self.imageHeight intValue])/2,[self.imageWidth intValue],[self.imageHeight intValue]);
        }else{ 
            self.webView.frame = CGRectMake((320-self.webView.frame.size.width)/2,(480-self.webView.frame.size.height)/2,self.webView.frame.size.width,self.webView.frame.size.height);
        }
        self.viewScroll.frame = CGRectMake(0, 0, 320, 480);
        self.viewScroll.contentSize = CGSizeMake(320,480);
        if([self.tableView.superview isEqual:self.viewScroll]){
            self.tableView.frame = CGRectMake(0, 480, 320, 480);
            [self.viewScroll setContentSize:CGSizeMake(320, 960)];
        }
        

        ((UIImageView*)[self.view.subviews objectAtIndex:0]).frame = CGRectMake(0, 0, 320, 480);
    }
    NSLog(@"The frame position is %d, %d",self.view.frame.origin.x,self.view.frame.origin.y);
    
}
- (void) webViewDidFinishLoad:(UIWebView *)webView{
    if(self.imageWidth <=0){
        self.webView.hidden = NO;
   }    
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 0)
    {
        [[UIApplication sharedApplication] setStatusBarHidden:NO];
        [self dismissModalViewControllerAnimated:NO];
        
    }
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

-(void)loadCaptions{ 
    NSURLRequest *request = [NSURLRequest requestWithURL:  
                             [NSURL URLWithString:[NSString stringWithFormat:@"http://imgur.com/gallery/%@.json",self.imageId]]];  
    (void) [[NSURLConnection alloc] initWithRequest:request delegate:self];
    
};
@end
