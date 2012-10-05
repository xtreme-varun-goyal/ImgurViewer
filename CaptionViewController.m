//
//  CaptionViewController.m
//  Webbb
//
//  Created by Varun Goyal on 12-01-12.
//  Copyright (c) 2012 University of Waterloo. All rights reserved.
//

#import "CaptionViewController.h"
#import "SBJson.h"
#import "GifAnimatedView.h"
#import "ImageFullScreenController.h"

@interface CaptionViewController() 
-(void) dismissScreen;
@end

@implementation CaptionViewController
@synthesize results = _results, responseData = _responseData, hash = _hash,
            tableView = _tableView, buttonItem = _buttonItem;

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
    float maxHeight = MAX([[UIScreen mainScreen] bounds].size.height, [[UIScreen mainScreen] bounds].size.width);
    float minHeight = MIN([[UIScreen mainScreen] bounds].size.height, [[UIScreen mainScreen] bounds].size.width);
    UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"background.png"]];
    [imageView setFrame:CGRectMake(0, 0, minHeight, maxHeight)];
    [self.view addSubview:imageView];
    [self.view sendSubviewToBack:imageView];
    self.responseData = [NSMutableData data];  
    self.results = [NSMutableArray array];  
    NSURLRequest *request = [NSURLRequest requestWithURL:  
                             [NSURL URLWithString:[NSString stringWithFormat:@"http://imgur.com/gallery/%@.json",self.hash]]];
    (void) [[NSURLConnection alloc] initWithRequest:request delegate:self];
    [self.buttonItem setAction:@selector(dismissScreen)];
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

#pragma mark UITableView Delegate methods 
- (NSInteger)tableView:(UITableView *)tableView 
 numberOfRowsInSection:(NSInteger)section {
    return [self.results count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView 
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    float maxHeight = MAX([[UIScreen mainScreen] bounds].size.height, [[UIScreen mainScreen] bounds].size.width);
    float minHeight = MIN([[UIScreen mainScreen] bounds].size.height, [[UIScreen mainScreen] bounds].size.width);
    // Attempt to request the reusable cell.
    int i = indexPath.row;
	UITableViewCell *cell = [[UITableViewCell alloc] initWithFrame:CGRectMake(minHeight*i, 60 * i, minHeight, 70)];
    if([self.results objectAtIndex:i]){
        NSDictionary *initial = [self.results objectAtIndex:i] ;
        CGRect contentRect = CGRectMake(10,0, 300*(minHeight/320), 70);
        UILabel *textView = [[UILabel alloc] initWithFrame:contentRect];
        NSString *caption = [initial objectForKey:@"caption"];
        if (([caption rangeOfString:@".gif"].location != NSNotFound || [caption rangeOfString:@".jpg"].location != NSNotFound || [caption rangeOfString:@".png"].location != NSNotFound) && [caption rangeOfString:@"http://"].location != NSNotFound) {
            cell.userInteractionEnabled = YES;
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

//-(BOOL)shouldAutorotate
//{
//    return NO;
//}
//
//-(NSUInteger)supportedInterfaceOrientations
//{
//    return UIInterfaceOrientationMaskPortrait;
//}


- (void)connectionDidFinishLoading:(NSURLConnection *)connection {  
    NSString *responseString = [[NSString alloc] initWithData:self.responseData encoding:NSUTF8StringEncoding];
    NSMutableArray *keys = [(NSDictionary*)[responseString JSONValue] allKeys];
    NSArray *resultsArray = [[(NSDictionary*)[responseString JSONValue] objectForKey:keys[0]] objectForKey:@"captions"];
    self.results = resultsArray;
    [self.tableView reloadData];
}

-(void) dismissScreen{
    [self dismissModalViewControllerAnimated:YES];
}

- (void)willAnimateRotationToInterfaceOrientation:
(UIInterfaceOrientation)toInterfaceOrientation
                                         duration:(NSTimeInterval)duration
{
    float maxHeight = MAX(self.view.frame.size.height, self.view.frame.size.width);
    float minHeight = MIN(self.view.frame.size.height, self.view.frame.size.width);
    if (toInterfaceOrientation == UIInterfaceOrientationLandscapeLeft ||
        toInterfaceOrientation == UIInterfaceOrientationLandscapeRight)
    {
        self.tableView.frame = CGRectMake(0,(44*minHeight)/320,maxHeight, minHeight-(44*minHeight)/320);
    }
    else
    {
        self.tableView.frame = CGRectMake(0, (44*maxHeight)/480, minHeight, maxHeight-(44*maxHeight)/480);
    }
    ((UIImageView*)[self.view.subviews objectAtIndex:0]).frame = self.tableView.frame;
    [self.tableView reloadData];
}
@end

@implementation UINavigationController (Rotation_IOS6)

//-(BOOL)shouldAutorotate
//{
//    return NO;
//}
//
//-(NSUInteger)supportedInterfaceOrientations
//{
//    return UIInterfaceOrientationMaskPortrait;
//}


@end
