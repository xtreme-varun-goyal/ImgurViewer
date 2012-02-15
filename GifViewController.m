//
//  GifViewController.m
//  ImgurViewer
//
//  Created by Varun Goyal on 12-01-30.
//  Copyright (c) 2012 University of Waterloo. All rights reserved.
//

#import "GifViewController.h"
#import "AnimatedGif.h"

@implementation GifViewController
@synthesize gifView = _gifView;

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
    NSURL 		* secondUrl = 			[NSURL URLWithString:@"http://i.imgur.com/xN2Ud.gif"];
    UIImageView * secondAnimation = 	[AnimatedGif getAnimationForGifAtUrl: secondUrl];
    [secondAnimation setContentMode:UIViewContentModeScaleAspectFit];
    [self.gifView addSubview:secondAnimation];
    [self.gifView setBackgroundColor:[UIColor clearColor]];
    // Do any additional setup after loading the view from its nib.
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
