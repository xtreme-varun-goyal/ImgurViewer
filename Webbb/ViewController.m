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

@interface ViewController ()
- (void) showComments;
- (void) dismissScreen;
- (void) initialLoadImages;
@end

@implementation ViewController
@synthesize results = _results, responseData = _responseData,scrollView = _scrollView, activityView = _activityView, comments = _comments, toolBar = _toolBar, 
    textView = _textView, currentPage = _currentPage, backButton = _backButton,
    pageCount = _pageCount;

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    for(int i = 0; i<40; i ++){
       ((UIImageView*) [self.scrollView.subviews objectAtIndex:i]).image = NULL;
    }
    // Release any cached data, images, etc that aren't in use.
}


#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.pageCount = 3;
    [self.activityView setHidden:NO];
    [self.activityView startAnimating];
//    self.toolBar.hidden = YES;
    UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"background.png"]];
    [self.view addSubview:imageView];
    [self.view sendSubviewToBack:imageView];
    [self.scrollView setScrollEnabled:YES];
    self.scrollView.maximumZoomScale = 2.0;
    self.scrollView.minimumZoomScale = 1; 
    self.textView.frame = CGRectMake(0, 0, 320, 44);
    self.textView.numberOfLines = 4;
    self.textView.textColor = [UIColor whiteColor];
    self.textView.font = [UIFont systemFontOfSize:18];
    [self.textView setHidden:YES];
//    self.results = [NSMutableArray array];  
//    NSURLRequest *request = [NSURLRequest requestWithURL:  
//                             [NSURL URLWithString:@"http://imgur.com/gallery/new.json"]];  
//    (void) [[NSURLConnection alloc] initWithRequest:request delegate:self];
    [self.comments setAction:@selector(showComments)];
    self.scrollView.autoresizesSubviews = YES;
	self.scrollView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
    [self.backButton setAction:@selector(dismissScreen)];
    [self initialLoadImages];
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
    [self.activityView startAnimating];
    [self.activityView setHidden:NO];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self.activityView setHidden:NO];
    [self.activityView startAnimating];
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
    // Return YES for supported orientations
//    return YES;
    return (interfaceOrientation == UIInterfaceOrientationPortrait | interfaceOrientation == UIInterfaceOrientationPortraitUpsideDown);
}

//- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
//{
//    if (toInterfaceOrientation == UIInterfaceOrientationLandscapeLeft ||
//        toInterfaceOrientation == UIInterfaceOrientationLandscapeRight)
//    {
//        self.scrollView.frame = CGRectMake(0, 44, 480, 212);
//        self.textView.frame = CGRectMake(0, 0, 480, 22);
//        self.toolBar.frame = CGRectMake(0, 256, 480, 44);
//       ((UIImageView*) [self.view.subviews objectAtIndex:0]).frame = CGRectMake(0, 0, 480, 300);
//    }
//}

- (void)initialLoadImages {  
    int frameWidth = self.scrollView.frame.size.width;
    int frameHeight = self.scrollView.frame.size.height;
    [self.scrollView setContentSize:CGSizeMake(frameWidth * 120, frameHeight)];
    
//    for(int i = 0; i < [self.currentPage intValue] + 1; i++){
        NSDictionary *initial = [self.results objectAtIndex:[self.currentPage intValue]] ;
        UIImageView *accountImage = [[UIImageView alloc] init];
        UIImage *image = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://i.imgur.com/%@m.jpg",[initial objectForKey:@"hash"]]]]];
        
        int initialHeight = [[initial objectForKey:@"height"] intValue];
        int initialWidth = [[initial objectForKey:@"width"] intValue];
        if(initialHeight > frameHeight | initialWidth > frameWidth){
            int height = MIN((frameWidth * image.size.height) / image.size.width, frameHeight);
            accountImage.frame = CGRectMake(frameWidth*[self.currentPage intValue], (frameHeight-height)/2, frameWidth,height);
        }else{
            accountImage.frame = CGRectMake(frameWidth*[self.currentPage intValue], (frameHeight-initialHeight)/2, initialWidth,initialHeight);
        };
        accountImage.image = image;
        [self.scrollView addSubview:accountImage];
        [accountImage setMultipleTouchEnabled:YES];
        [accountImage setUserInteractionEnabled:YES];
        accountImage.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
//    }
    self.pageCount = 1;
    for(int i = self.pageCount; i < 120; i ++){
        UIImageView *accountImage = [[UIImageView alloc] init];
        [self.scrollView addSubview:accountImage];
        accountImage.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);

    }
    [self.activityView stopAnimating];
    [self.activityView setHidden:YES];
    self.toolBar.hidden = NO;
    [self.scrollView setContentOffset:CGPointMake(320 * [self.currentPage intValue], 0)];
    self.textView.text = [initial objectForKey:@"title"];
    [self.textView setHidden:NO];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    int frameWidth = self.scrollView.frame.size.width;
    int frameHeight = self.scrollView.frame.size.height;
    CGFloat pageWidth = scrollView.frame.size.width;
    float fractionalPage = scrollView.contentOffset.x / pageWidth;
    NSInteger page = lround(fractionalPage);
    NSDictionary *initial = [self.results objectAtIndex:page];
    self.textView.text = [initial objectForKey:@"title"];
    UIImageView *currentView = [self.scrollView.subviews objectAtIndex:[self.currentPage intValue]];
    if (!currentView.image && self.pageCount < 121 ) {        
        [self.activityView startAnimating];
        [self.activityView setHidden:NO];
        self.pageCount++;
        UIImageView *currentView = [self.scrollView.subviews objectAtIndex:page];
        initial = [self.results objectAtIndex:page] ;
        UIImage *image = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://i.imgur.com/%@m.jpg",[initial objectForKey:@"hash"]]]]];
        int initialHeight = [[initial objectForKey:@"height"] intValue];
        int initialWidth = [[initial objectForKey:@"width"] intValue];
        if(initialHeight > frameHeight | initialWidth > frameWidth){
            int height = MIN((frameWidth * image.size.height) / image.size.width, frameHeight);
            currentView.frame = CGRectMake(frameWidth*page + (320 - frameWidth)/2, (frameHeight-height)/2, frameWidth,height);
        }else{
            currentView.frame = CGRectMake(frameWidth*page + (320 - initialWidth)/2, (frameHeight-initialHeight)/2, initialWidth,initialHeight);
        };
        currentView.image = image;

        [self.activityView stopAnimating];
        [self.activityView setHidden:YES];
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
    UIImage *image = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://i.imgur.com/%@m.jpg",[initial objectForKey:@"hash"]]]]];
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
    [self dismissModalViewControllerAnimated:YES];
}

-(void) loadMoreImages{
    int frameWidth = self.scrollView.frame.size.width;
    int frameHeight = self.scrollView.frame.size.height;
//    for(int i = self.pageCount; i < [self.currentPage intValue] + 1; i++) {
//        self.pageCount++;
        [self.activityView startAnimating];
        [self.activityView setHidden:NO];
        UIImageView *currentView = [self.scrollView.subviews objectAtIndex:[self.currentPage intValue]];
        NSDictionary *initial= [self.results objectAtIndex:[self.currentPage intValue]] ;
        UIImage *image = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://i.imgur.com/%@m.jpg",[initial objectForKey:@"hash"]]]]];
        int initialHeight = [[initial objectForKey:@"height"] intValue];
        int initialWidth = [[initial objectForKey:@"width"] intValue];
        if(initialHeight > frameHeight | initialWidth > frameWidth){
            int height = MIN((frameWidth * image.size.height) / image.size.width, frameHeight);
            currentView.frame = CGRectMake(frameWidth*[self.currentPage intValue] + (320 - frameWidth)/2, (frameHeight-height)/2, frameWidth,height);
        }else{
            currentView.frame = CGRectMake(frameWidth*[self.currentPage intValue] + (320 - initialWidth)/2, (frameHeight-initialHeight)/2, initialWidth,initialHeight);
        };
        currentView.image = image;
        image = NULL;
        [self.activityView stopAnimating];
        [self.activityView setHidden:YES];
//    }
}
//- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
//    CGFloat pageWidth = self.scrollView.frame.size.width;
//    int currentPage = floor((self.scrollView.contentOffset.x - pageWidth / 2) / pageWidth) + 1;
//    UIImageView *currentView = [self.scrollView.subviews objectAtIndex:currentPage];
//	return currentView;
//}

@end
