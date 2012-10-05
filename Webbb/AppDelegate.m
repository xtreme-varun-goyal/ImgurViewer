//
//  AppDelegate.m
//  Webbb
//
//  Created by Varun Goyal on 12-01-12.
//  Copyright (c) 2012 University of Waterloo. All rights reserved.
//

#import "AppDelegate.h"

#import "ViewController.h"
#import "GallerryPickerViewController.h"
#import "SHKReadItLater.h"
#import "SHKConfiguration.h"
#import "SHKFacebook.h"
#import "Facebook.h"
#import "FBSharedViewController.h"
#import "ImageFullScreenController.h"

@interface AppDelegate ()
-(NSDictionary*)parseURLParams:(NSString *)query;
@end
@implementation AppDelegate

@synthesize window = _window;
@synthesize viewController = _viewController;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{

    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // Override point for customization after application launch.
    self.viewController = [[GallerryPickerViewController alloc] initWithNibName:@"GallerryPickerViewController" bundle:nil];

    
    UINavigationController *navControl = [[UINavigationController alloc] initWithRootViewController:self.viewController];
    navControl.navigationBarHidden = YES;
    [self.window addSubview:navControl.view];
    [self.window setRootViewController:navControl];
    [self.window makeKeyAndVisible];
    [navControl setDelegate:self];
    return YES;
}

- (BOOL)handleOpenURL:(NSURL*)url
{
	NSString* scheme = [url scheme];
    if ([scheme hasPrefix:[NSString stringWithFormat:@"fb%@", SHKCONFIG(facebookAppId)]])
        return [SHKFacebook handleOpenURL:url];
    return YES;
}

- (BOOL)application:(UIApplication *)application 
            openURL:(NSURL *)url 
  sourceApplication:(NSString *)sourceApplication 
         annotation:(id)annotation 
{
    
    NSString *query = [url fragment];
    
    // Version 3.2.3 of the Facebook app encodes the parameters in the query but
    // version 3.3 and above encode the parameters in the fragment. To support
    // both versions of the Facebook app, we try to parse the query if
    // the fragment is missing.
    if (!query) {
        query = [url query];
    }
    NSDictionary *params = [self parseURLParams:query];
    NSString *shareUrl =[params valueForKey:@"target_url"];
    if([query rangeOfString:@"target_url"].location != NSNotFound){
        FBSharedViewController *shareViewController = [[FBSharedViewController alloc] init];   
        shareViewController.hash = [shareUrl substringFromIndex:[shareUrl rangeOfString:@".com/"].location + 5];
        [self.window.rootViewController presentModalViewController:shareViewController animated:YES];
//        NSLog(shareViewController.hash);
        return true;
    }

    return [self handleOpenURL:url];
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    /*
     Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
     Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
     */
//    if(self.viewController.isViewLoaded && self.viewController.adWhirl){
//        [self.viewController.adView setHidden:YES];
//        [self.viewController.adView removeFromSuperview];
//        [self.viewController.scrollView setContentSize:CGSizeMake(320, self.viewController.scrollView.contentSize.height - self.viewController.adWhirl.frame.size.height)];
//        self.viewController.adView = nil;
//        [self.viewController.adWhirl setHidden:YES];
//        [self.viewController.adWhirl removeFromSuperview];
//        self.viewController.adWhirl = nil;
//    }
    if(self.viewController.uploadImageView.isViewLoaded && self.viewController.uploadImageView.adWhirl){
        [self.viewController.uploadImageView.adView setHidden:YES];
        [self.viewController.uploadImageView.adView removeFromSuperview];
        self.viewController.uploadImageView.adView = nil;
        [self.viewController.uploadImageView.adWhirl setHidden:YES];
        [self.viewController.uploadImageView.adWhirl removeFromSuperview];
        self.viewController.uploadImageView.adWhirl = nil;
//        
    }
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    /*
     Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
     If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
//     */
//    if(self.viewController.isViewLoaded && self.viewController.adWhirl){
//        [self.viewController.adView setHidden:YES];
//        [self.viewController.adView removeFromSuperview];
//        [self.viewController.scrollView setContentSize:CGSizeMake(320, self.viewController.scrollView.contentSize.height - self.viewController.adWhirl.frame.size.height)];
//        self.viewController.adView = nil;
//        [self.viewController.adWhirl setHidden:YES];
//        [self.viewController.adWhirl removeFromSuperview];
//        self.viewController.adWhirl = nil;
//    }
    if(self.viewController.uploadImageView.isViewLoaded && self.viewController.uploadImageView.adWhirl){
        [self.viewController.uploadImageView.adView setHidden:YES];
        [self.viewController.uploadImageView.adView removeFromSuperview];
        self.viewController.uploadImageView.adView = nil;
        [self.viewController.uploadImageView.adWhirl setHidden:YES];
        [self.viewController.uploadImageView.adWhirl removeFromSuperview];
        self.viewController.uploadImageView.adWhirl = nil;

    }
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{

    /*
     Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
     */
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{

//    [[UIApplication sharedApplication] setStatusBarHidden:NO];  
    /*
     Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
     */
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    /*
     Called when the application is about to terminate.
     Save data if appropriate.
     See also applicationDidEnterBackground:.
     */
}

- (NSDictionary*)parseURLParams:(NSString *)query {
	NSArray *pairs = [query componentsSeparatedByString:@"&"];
	NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
	for (NSString *pair in pairs) {
		NSArray *kv = [pair componentsSeparatedByString:@"="];
		NSString *val =
        [[kv objectAtIndex:1]
         stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        
		[params setObject:val forKey:[kv objectAtIndex:0]];
	}
    return params;
}
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return interfaceOrientation == UIInterfaceOrientationPortrait;
}

- (NSUInteger) supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

- (BOOL)shouldAutorotate {
    return NO;
}
@end

@implementation UINavigationController (Rotation_IOS6)

-(BOOL)shouldAutorotate
{
    return [[self.viewControllers lastObject] shouldAutorotate];
}

-(NSUInteger)supportedInterfaceOrientations
{
    return [[self.viewControllers lastObject] supportedInterfaceOrientations];
}

@end

