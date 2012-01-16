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

@implementation GallerryPickerViewController

@synthesize results = _results, responseData = _responseData,scrollView = _scrollView,imageController = _imageController,activityView = _activityView;

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
    self.imageController = [[ViewController alloc] init];
    [self.activityView setHidden:NO];
    [self.activityView startAnimating];
    UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"background.png"]];
    [self.view addSubview:imageView];
    [self.view sendSubviewToBack:imageView];
    self.responseData = [NSMutableData data];
    self.results = [NSMutableArray array];  
    NSURLRequest *request = [NSURLRequest requestWithURL:  
                             [NSURL URLWithString:@"http://imgur.com/gallery/new.json"]];  
    (void) [[NSURLConnection alloc] initWithRequest:request delegate:self];
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
    NSArray *resultsArray = [(NSDictionary*)[responseString JSONValue] objectForKey:@"gallery"];
    self.results = resultsArray;
    int frameWidth = self.scrollView.frame.size.width;
    [self.scrollView setContentSize:CGSizeMake(frameWidth, 2000)];
    for(int i = 0; i < 100 ; i++){
        NSDictionary *initial = [self.results objectAtIndex:i];
        
        UIButton *thumbnail = [UIButton buttonWithType:UIButtonTypeCustom];
        [thumbnail setImage:[UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://i.imgur.com/%@s.jpg",[initial objectForKey:@"hash"]]]]] forState:UIControlStateNormal];
        int positionY = 80 * (i/4);
        int positionX = 80 * (i%4);
        thumbnail.frame = CGRectMake(positionX,positionY,80,80);
        [thumbnail addTarget:self action:@selector(buttonClicked:) forControlEvents:UIControlEventTouchUpInside];
        thumbnail.tag = i;
        
        [self.scrollView addSubview:thumbnail];
        
    }
    [self.activityView setHidden:YES];
    [self.activityView stopAnimating];
}

- (IBAction)buttonClicked:(id)sender{ 
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
        self.imageController.textView.text = [initial objectForKey:@"title"];
    };
    [self presentModalViewController:self.imageController animated:YES];
//    int currentPage = floor((self.scrollView.contentOffset.x - pageWidth / 2) / pageWidth) + 1;
    //    UIImageView *currentView = [self.scrollView.subviews objectAtIndex:currentPage];
};

@end
