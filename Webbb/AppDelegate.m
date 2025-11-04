//
//  AppDelegate.m
//  ImgurViewer
//
//  Completely rewritten for iOS 15+ - 2025
//  Copyright (c) 2012-2025 University of Waterloo. All rights reserved.
//

#import "AppDelegate.h"
#import "ImgurGalleryViewController.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];

    // Create modern gallery view controller
    ImgurGalleryViewController *galleryVC = [[ImgurGalleryViewController alloc] initWithGalleryType:@"hot"];

    // Wrap in navigation controller with modern appearance
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:galleryVC];

    // Configure modern navigation bar appearance
    UINavigationBarAppearance *appearance = [[UINavigationBarAppearance alloc] init];
    [appearance configureWithOpaqueBackground];
    appearance.backgroundColor = [UIColor systemBackgroundColor];

    navController.navigationBar.standardAppearance = appearance;
    navController.navigationBar.scrollEdgeAppearance = appearance;
    navController.navigationBar.prefersLargeTitles = NO;
    navController.navigationBar.tintColor = [UIColor systemBlueColor];

    // Set as root
    self.window.rootViewController = navController;
    [self.window makeKeyAndVisible];

    return YES;
}

- (UIInterfaceOrientationMask)application:(UIApplication *)application
    supportedInterfaceOrientationsForWindow:(UIWindow *)window {
    return UIInterfaceOrientationMaskAll;
}

@end

@implementation UINavigationController (ImgurViewer_Rotation)

- (BOOL)shouldAutorotate {
    return YES;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return [[self.viewControllers lastObject] supportedInterfaceOrientations];
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {
    if ([self.viewControllers.lastObject respondsToSelector:@selector(preferredInterfaceOrientationForPresentation)]) {
        return [[self.viewControllers lastObject] preferredInterfaceOrientationForPresentation];
    }
    return UIInterfaceOrientationPortrait;
}

@end
