//
//  ViewController.m
//  Webbb
//
//  Created by Varun Goyal on 12-01-12.
//  Copyright (c) 2012 University of Waterloo. All rights reserved.
//

#import "ViewController.h"
#import "SBJson.h"
#import "CaptionViewController.h"
#import "ImageFullScreenController.h"
#import "GifAnimatedView.h"

@interface ViewController ()
- (void) showComments;
- (void) dismissScreen;
- (void) initialLoadImages;
- (void) loadImage;
- (UIImage*) getImage;
@end

@implementation ViewController
@synthesize results = _results, responseData = _responseData,scrollView = _scrollView, activityView = _activityView, comments = _comments, toolBar = _toolBar, 
    textView = _textView, currentPage = _currentPage, backButton = _backButton,
    pageCount = _pageCount,thread = _thread;

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
    [super viewDidLoad];
    int frameWidth, frameHeight;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
    {
        frameWidth = 768;
        frameHeight = 1024;
        self.textView.numberOfLines = 4;
        self.textView.textColor = [UIColor whiteColor];
        self.textView.font = [UIFont systemFontOfSize:14];
        self.textView.minimumFontSize = 12;
    }
    else
    {
        frameWidth = self.view.frame.size.width;
        frameHeight = self.view.frame.size.height;
        self.textView.numberOfLines = 4;
        self.textView.textColor = [UIColor whiteColor];
        self.textView.font = [UIFont systemFontOfSize:14];
        self.textView.minimumFontSize = 12;
    }
    
    self.thread = [[NSThread alloc] initWithTarget:self selector:@selector(loadImage) object:nil];
    [self.activityView setHidden:NO];
    [self.activityView startAnimating];
    UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"background.png"]];
    [self.view addSubview:imageView];
    [self.view sendSubviewToBack:imageView];
    [self.scrollView setScrollEnabled:YES];
    self.scrollView.maximumZoomScale = 2.0;
    self.scrollView.minimumZoomScale = 1; 
    self.textView.frame = CGRectMake(0, 0, frameWidth, (frameHeight*44)/460);
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
    int frameWidth = 768;
    int frameHeight = self.scrollView.frame.size.height;
    for(int i = self.pageCount; i < [self.results count]; i ++){
        UIImageView *accountImage = [[UIImageView alloc] init];
        accountImage.frame = CGRectMake(frameWidth*i,6, frameWidth, frameHeight);
        accountImage.image = [UIImage imageNamed:@"Loading.png"];
        [self.scrollView addSubview:accountImage];
        accountImage.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
        accountImage.tag = -4;
    }
    [self.scrollView setContentSize:CGSizeMake(frameWidth * [self.results count], frameHeight)];
    
        NSDictionary *initial = [self.results objectAtIndex:[self.currentPage intValue]] ;
        UIImageView *currentView = [self.scrollView.subviews objectAtIndex:[self.currentPage intValue]];
        UIImage *image = [self getImage];
  
        int initialHeight = [[initial objectForKey:@"height"] intValue];
        int initialWidth = [[initial objectForKey:@"width"] intValue];
        if(initialHeight > frameHeight | initialWidth > frameWidth){
            int height = MIN((frameWidth * image.size.height) / image.size.width, frameHeight);
            currentView.frame = CGRectMake(frameWidth*[self.currentPage intValue], (frameHeight-height)/2, frameWidth,height);
        }else{
            currentView.frame = CGRectMake(frameWidth*[self.currentPage intValue], (frameHeight-initialHeight)/2, initialWidth,initialHeight);
        };
    
//    NSString *ext = [initial objectForKey:@"ext"];
    
//    if([ext isEqualToString:@".gif"]){
//        UIWebView *webView = [[UIWebView alloc] init];
//        [webView loadRequest: [NSURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://i.imgur.com/%@.gif",[initial   objectForKey:@"hash"]]]]];
//        webView.frame = currentView.frame;
//        [self.scrollView addSubview:webView];
//        currentView.tag = self.scrollView.subviews.count - 1;
//        currentView.hidden = YES;
//        webView.userInteractionEnabled = NO;
//
//    }else{
        currentView.image = image;
        currentView.contentMode = UIViewContentModeScaleAspectFit;
         currentView.tag = 1;
//    } 
    
        [currentView setUserInteractionEnabled:YES];
   
//    }
    self.pageCount = 1;

    [self.activityView stopAnimating];
    [self.activityView setHidden:YES];
    self.toolBar.hidden = NO;
    [self.scrollView setContentOffset:CGPointMake(frameWidth * [self.currentPage intValue], 0)];
    id isTextNull = [initial objectForKey:@"title"];
    if(isTextNull == [NSNull null]){
        self.textView.text = @"";
    }else{
        self.textView.text = [initial objectForKey:@"title"];
    }
    [self.textView setHidden:NO];
}


- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    CGFloat pageWidth = self.scrollView.frame.size.width;
    float fractionalPage = self.scrollView.contentOffset.x / pageWidth;
    NSInteger page = lroundf(fractionalPage);
    self.currentPage = [NSString stringWithFormat:@"%i",page];
    int pageTag= ((UIImageView*)[self.scrollView.subviews objectAtIndex:page]).tag;
    NSDictionary *initial = [self.results objectAtIndex:page];
    id titleIsNull = [initial objectForKey:@"title"];
    if(titleIsNull != [NSNull null]){
        self.textView.text = [initial objectForKey:@"title"];
    }else{
        self.textView.text = @"";
    }
    if(![self.thread isExecuting] && page < self.results.count && pageTag==-4){
        self.thread = [[NSThread alloc] initWithTarget:self selector:@selector(loadImage) object:nil];
        [self.thread start];
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
    self.pageCount++;
    [self.activityView startAnimating];
    [self.activityView setHidden:NO];
    UIImageView *currentView = [self.scrollView.subviews objectAtIndex:[self.currentPage intValue]];
    NSDictionary *initial= [self.results objectAtIndex:[self.currentPage intValue]] ;
    UIImage *image = [self getImage];
    int initialHeight = [[initial objectForKey:@"height"] intValue];
    int initialWidth = [[initial objectForKey:@"width"] intValue];
    if(initialHeight > frameHeight | initialWidth > frameWidth){
        int height = MIN((frameWidth * image.size.height) / image.size.width, frameHeight);
        currentView.frame = CGRectMake(frameWidth*[self.currentPage intValue] + (320 - frameWidth)/2, (frameHeight-height)/2, frameWidth,height);
    }else{
        currentView.frame = CGRectMake(frameWidth*[self.currentPage intValue] + (320 - initialWidth)/2, (frameHeight-initialHeight)/2, initialWidth,initialHeight);
    };
    
//    NSString *ext = [initial objectForKey:@"ext"];
    
//    if([ext isEqualToString:@".gif"]){
//        UIWebView *webView = [[UIWebView alloc] init];
//        [webView loadRequest: [NSURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://i.imgur.com/%@.gif",[initial   objectForKey:@"hash"]]]]];
//        webView.frame = currentView.frame;
//        [self.scrollView addSubview:webView];
//        webView.userInteractionEnabled = NO;
//        currentView.hidden = YES;
//        currentView.tag = self.scrollView.subviews.count - 1;
//    }else{
        currentView.image = image;
        currentView.contentMode = UIViewContentModeScaleAspectFit;
//    } 
    
    currentView.tag = -4;
    image = NULL;
    [self.activityView stopAnimating];
    [self.activityView setHidden:YES];
}

- (void) loadImage{
    [self.scrollView setUserInteractionEnabled:NO];
    int frameWidth = self.scrollView.frame.size.width;
    int frameHeight = self.scrollView.frame.size.height;
    CGFloat pageWidth = self.scrollView.frame.size.width;
    float fractionalPage = self.scrollView.contentOffset.x / pageWidth;
    NSInteger page = lround(fractionalPage);
    NSDictionary *initial = [self.results objectAtIndex:page];
    UIImageView *currentView = [self.scrollView.subviews objectAtIndex:page];
    if (currentView.tag == -4) {
        self.currentPage = [NSString stringWithFormat:@"%i",page];
        self.pageCount++;
        UIImage *image = [self getImage]; 
        
        int initialHeight = [[initial objectForKey:@"height"] intValue];
        int initialWidth = [[initial objectForKey:@"width"] intValue];
        if(initialHeight > frameHeight | initialWidth > frameWidth){
            int height = MIN((frameWidth * image.size.height) / image.size.width, frameHeight);
            currentView.frame = CGRectMake(frameWidth*page + (320 - frameWidth)/2, (frameHeight-height)/2, frameWidth,height);
        }else{
            currentView.frame = CGRectMake(frameWidth*page + (320 - initialWidth)/2, (frameHeight-initialHeight)/2, initialWidth,initialHeight);
        };
        currentView.image = image;
        currentView.contentMode = UIViewContentModeScaleAspectFit;
        
//        NSString *ext = [initial objectForKey:@"ext"];
        
//        if([ext isEqualToString:@".gif"]){
//            [self.thread cancel];
//            UIWebView *webView = [[UIWebView alloc] init];
//            [webView loadRequest: [NSURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://i.imgur.com/%@.gif",[initial   objectForKey:@"hash"]]]]];
//            webView.frame = currentView.frame;
//            webView.userInteractionEnabled = NO;
//            [self.scrollView addSubview:webView];
//            currentView.tag = self.scrollView.subviews.count - 1;
//            currentView.hidden = YES;
//        }else{
            currentView.image = image;
            currentView.contentMode = UIViewContentModeScaleAspectFit;
            [self.thread cancel];
                    currentView.tag = 1;
//        } 
        
        [self.activityView stopAnimating];
        [self.activityView setHidden:YES];

    }
    [self.scrollView setUserInteractionEnabled:YES];

};


- (void) handleSingleTap : (UIGestureRecognizer*) sender
{ 
//    CGFloat pageWidth = self.scrollView.frame.size.width;
//    float fractionalPage = self.scrollView.contentOffset.x / pageWidth;
//    NSInteger page = lround(fractionalPage);
//    NSDictionary *initial = [self.results objectAtIndex:page];
//    if([[initial objectForKey:@"ext"] isEqualToString:@".gif"]){
//        UIImageView *currentView = [self.scrollView.subviews objectAtIndex:page];
//        int tag = currentView.tag;
//        UIWebView *webView = [self.scrollView.subviews objectAtIndex:currentView.tag];
//        GifAnimatedView *fullWebView = [[GifAnimatedView alloc] init];
//        fullWebView.webView = [[UIWebView alloc] init];
//        [fullWebView.webView loadRequest:webView.request];
//        fullWebView.webView.frame = CGRectMake((320 - currentView.frame.size.width)/2 , (460 -currentView.frame.size.height)/2, currentView.frame.size.width,currentView.frame.size.height);
////        fullWebView.webView = webView;
//        [self presentModalViewController:fullWebView animated:NO];
//    }else{
        CGFloat pageWidth = self.scrollView.frame.size.width;
        float fractionalPage = self.scrollView.contentOffset.x / pageWidth;
        NSInteger page = lround(fractionalPage);
        ImageFullScreenController *fullScreen = [[ImageFullScreenController alloc] initWithNibName:@"ImageFullScreenController" bundle:nil];
        fullScreen.imageView =  [[UIImageView alloc] initWithImage:((UIImageView*)[self.scrollView.subviews objectAtIndex:page]).image];
        [[UIApplication sharedApplication] setStatusBarHidden:YES];
        [self presentModalViewController:fullScreen animated:NO];
//    }
}

- (UIImage*) getImage{
    NSDictionary *initial = [self.results objectAtIndex:[self.currentPage intValue]];

    UIImage *image = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://i.imgur.com/%@l.jpg",[initial   objectForKey:@"hash"]]]]]; 
    if (!image) {
        UIAlertView *alertNetwork = [[UIAlertView alloc] initWithTitle:@"Unable to load image" message:@"The image couldn't load, please check your internet connections and reopen the app" delegate:self cancelButtonTitle:@"Dismiss" otherButtonTitles:nil, nil];
        [alertNetwork show];
    }
    return image;
};

@end
