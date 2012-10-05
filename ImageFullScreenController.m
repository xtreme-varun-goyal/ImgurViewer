//
//  ImageFullScreenController.m
//  ImgurViewer
//
//  Created by Varun Goyal on 12-01-21.
//  Copyright (c) 2012 University of Waterloo. All rights reserved.
//

#import "ImageFullScreenController.h"

@implementation ImageFullScreenController
@synthesize imageView = _imageView,scrollView = _scrollView;

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    float maxHeight = MAX([[UIScreen mainScreen] bounds].size.height, [[UIScreen mainScreen] bounds].size.width);
    float minHeight = MIN([[UIScreen mainScreen] bounds].size.height, [[UIScreen mainScreen] bounds].size.width);
    [[UIApplication sharedApplication] setStatusBarHidden:YES];
    UIImageView *backgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"background.png"]];
    [backgroundView setFrame:CGRectMake(0, 0, minHeight, maxHeight)];
    [self.view addSubview:backgroundView];
    [self.view sendSubviewToBack:backgroundView];
    self.scrollView.minimumZoomScale=1.0;
    self.scrollView.maximumZoomScale=3.0;
    //    self.scrollView.contentSize=CGSizeMake(self.view.frame.size.height, self.view.frame.size.width);
    
    UIDeviceOrientation * toInterfaceOrientation = [[UIDevice currentDevice] orientation];
    if (toInterfaceOrientation == UIInterfaceOrientationLandscapeLeft ||
        toInterfaceOrientation == UIInterfaceOrientationLandscapeRight)
    {
        
        self.view.frame = CGRectMake(0, 0, maxHeight, minHeight);
        self.scrollView.frame = CGRectMake(0, 0, maxHeight, minHeight);
        self.scrollView.contentSize=CGSizeMake(maxHeight,minHeight);
        self.imageView.frame = CGRectMake(0, 0, maxHeight, minHeight);
    }
    else
    {
        self.view.frame = CGRectMake(0, 0, minHeight,maxHeight);
        self.scrollView.frame = CGRectMake(0, 0, minHeight,maxHeight);
        self.scrollView.contentSize=CGSizeMake(minHeight,maxHeight);
        self.imageView.frame = CGRectMake(0, 0, minHeight,maxHeight);
    }
    ((UIImageView*)[self.view.subviews objectAtIndex:0]).frame = self.scrollView.frame;
    
    
    [self.imageView setContentMode:UIViewContentModeScaleAspectFit];
    [self.scrollView addSubview:self.imageView];
    UITapGestureRecognizer* SingleTap = [[UITapGestureRecognizer alloc] initWithTarget : self action : @selector (handleSingleTap:)];
    [SingleTap setDelaysTouchesBegan : YES];
    
    [SingleTap setNumberOfTapsRequired : 1];
    backgroundView.frame = self.scrollView.frame;
    
    [self.view addGestureRecognizer : SingleTap];
    
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

-(void) viewDidAppear:(BOOL)animated{
    [[UIApplication sharedApplication] setStatusBarHidden:YES];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return true;
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
    zoomRect.size.height = self.scrollView.frame.size.height / scale;
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
    [self dismissModalViewControllerAnimated:NO];
}

- (void)willAnimateRotationToInterfaceOrientation:
(UIInterfaceOrientation)toInterfaceOrientation 
                                         duration:(NSTimeInterval)duration
{
    float maxHeight = MAX([[UIScreen mainScreen] bounds].size.height, [[UIScreen mainScreen] bounds].size.width);
    float minHeight = MIN([[UIScreen mainScreen] bounds].size.height, [[UIScreen mainScreen] bounds].size.width);
    if (toInterfaceOrientation == UIInterfaceOrientationLandscapeLeft ||
        toInterfaceOrientation == UIInterfaceOrientationLandscapeRight)
    {
        
        self.scrollView.frame = CGRectMake(0, 0, maxHeight, minHeight);
        self.scrollView.contentSize=CGSizeMake(maxHeight,minHeight);
        self.imageView.frame = self.scrollView.frame;
    }
    else
    {
        self.scrollView.frame = CGRectMake(0, 0, minHeight, maxHeight);
        self.scrollView.contentSize=CGSizeMake(minHeight,maxHeight);
        self.imageView.frame = self.scrollView.frame;
    }
    ((UIImageView*)[self.view.subviews objectAtIndex:0]).frame = self.scrollView.frame;
}



@end

@implementation UINavigationController (Rotation_IOS6)

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation
{
    return UIInterfaceOrientationPortrait;
}

@end