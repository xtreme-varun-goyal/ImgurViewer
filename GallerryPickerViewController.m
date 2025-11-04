//
//  GallerryPickerViewController.m
//  ImgurViewer
//
//  Created by Varun Goyal on 12-01-13.
//  Updated for iOS 15+ - 2025
//  Copyright (c) 2012 University of Waterloo. All rights reserved.
//

#import "GallerryPickerViewController.h"
#import "ViewController.h"
#import "UploadImageController.h"
#import "ImgurAPIManager.h"
#import "ImgurImageManager.h"
#import "UIView+LiquidGlass.h"

@interface GallerryPickerViewController ()

@property (nonatomic, assign) NSInteger pagesLoaded;
@property (nonatomic, assign) NSInteger initialImagesLoaded;
@property (nonatomic, assign) NSInteger pageNo;
@property (nonatomic, strong) NSMutableDictionary<NSNumber *, UIButton *> *thumbnailButtons;
@property (nonatomic, strong) UIView *glassToolbar;

- (void)loadMoreImages;
- (void)loadNewPickerView;
- (void)loadHotPickerView;
- (void)loadTopPickerView;
- (void)reloadView;
- (void)loadNextPage;
- (void)uploadImage;
- (void)loadImageView:(id)sender;
- (void)showSearchBar;
- (void)loadSearchResults;
- (void)setupLiquidGlassUI;
- (void)showErrorAlert:(NSString *)title message:(NSString *)message;

@end

@implementation GallerryPickerViewController
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        _thumbnailButtons = [NSMutableDictionary dictionary];
        _pagesLoaded = 0;
        _pageNo = 0;
        _initialImagesLoaded = 0;
    }
    return self;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    [[ImgurImageManager sharedManager] clearCache];
}

#pragma mark - View lifecycle

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.navigationController.navigationBarHidden = NO;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    // Setup UI
    CGFloat screenWidth = UIScreen.mainScreen.bounds.size.width;
    CGFloat screenHeight = UIScreen.mainScreen.bounds.size.height;

    // Set title and initial state
    self.currentViewTitle = @"new";
    self.pagesLoaded = 2;
    self.results = @[];

    // Configure buttons
    [self.hotButton setAction:@selector(loadHotPickerView)];
    [self.topBtn setAction:@selector(loadTopPickerView)];
    [self.latestBtn setAction:@selector(loadNewPickerView)];
    [self.reldButton setAction:@selector(reloadView)];
    [self.nxtBtn setAction:@selector(loadNextPage)];
    [self.uploadBtn setAction:@selector(uploadImage)];
    [self.searchBtn setAction:@selector(showSearchBar)];

    // Setup modern background with gradient
    CAGradientLayer *gradientLayer = [CAGradientLayer layer];
    gradientLayer.frame = self.view.bounds;
    gradientLayer.colors = @[
        (__bridge id)[UIColor colorWithRed:0.1 green:0.1 blue:0.15 alpha:1.0].CGColor,
        (__bridge id)[UIColor colorWithRed:0.15 green:0.15 blue:0.2 alpha:1.0].CGColor
    ];
    gradientLayer.locations = @[@0.0, @1.0];
    [self.view.layer insertSublayer:gradientLayer atIndex:0];

    // Setup scroll view with liquid glass effect
    self.scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, screenWidth, screenHeight - 158)];
    self.scrollView.showsVerticalScrollIndicator = NO;
    self.scrollView.bounces = YES;
    self.scrollView.alwaysBounceVertical = YES;
    [self.superScrollView addSubview:self.scrollView];
    [self.superScrollView setContentSize:CGSizeMake(screenWidth, screenHeight - 158)];

    // Setup search bar with modern styling
    self.searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 44, screenWidth, 44)];
    self.searchBar.delegate = self;
    self.searchBar.showsCancelButton = YES;
    self.searchBar.searchBarStyle = UISearchBarStyleMinimal;
    self.searchBar.hidden = YES;
    [self.view addSubview:self.searchBar];

    // Add liquid glass effects
    [self setupLiquidGlassUI];

    // Start loading data
    [self.activityView setHidden:NO];
    [self.activityView startAnimating];
    [self loadGalleryData:@"new" page:0];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    if (self.activityView.isAnimating) {
        [self.activityView stopAnimating];
    }
}

- (BOOL)shouldAutorotate {
    return YES;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskAll;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {
    return UIInterfaceOrientationPortrait;
}

#pragma mark - Liquid Glass UI Setup

- (void)setupLiquidGlassUI {
    // Add floating animation to activity indicator
    if (self.activityView) {
        UIView *glassContainer = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
        glassContainer.center = self.view.center;
        [glassContainer applyLiquidGlassEffect:LiquidGlassStyleDark cornerRadius:20];
        [self.view addSubview:glassContainer];
        [self.view bringSubviewToFront:self.activityView];
    }
}


#pragma mark - Modern API Data Loading

- (void)loadGalleryData:(NSString *)galleryType page:(NSInteger)page {
    self.view.userInteractionEnabled = NO;
    [self.activityView startAnimating];

    [[ImgurAPIManager sharedManager] fetchGallery:galleryType page:page completion:^(NSDictionary * _Nullable response, NSError * _Nullable error) {
        [self.activityView stopAnimating];
        self.view.userInteractionEnabled = YES;

        if (error) {
            [self handleAPIError:error];
            return;
        }

        [self processGalleryResponse:response];
    }];
}

- (void)handleAPIError:(NSError *)error {
    NSString *message = @"Failed to load images. Please check your internet connection and try again.";

    if ([error.domain isEqualToString:@"ImgurAPIManager"]) {
        if (error.code == 503) {
            message = @"Imgur is over capacity! This can happen when the site is under very heavy load, or while we're doing maintenance. Please try again in a few minutes.";
        }
    }

    [self showErrorAlert:@"Error" message:message];
}

- (void)processGalleryResponse:(NSDictionary *)response {
    if (!response) {
        [self showErrorAlert:@"Error" message:@"Invalid response from server"];
        return;
    }

    NSArray *keys = [response allKeys];
    if (keys.count == 0) {
        [self showErrorAlert:@"No Results" message:@"No images found"];
        return;
    }

    NSArray *resultsArray = response[keys.firstObject];
    if (resultsArray.count == 0) {
        NSString *message = self.searchBar.hidden ? @"Imgur is over capacity" : @"The search returned no results, please change your query.";
        [self showErrorAlert:@"No Results" message:message];
        return;
    }

    self.results = resultsArray;
    self.searchBar.hidden = YES;

    // Load thumbnails
    [self loadThumbnails:resultsArray];
}

- (void)loadThumbnails:(NSArray *)images {
    CGFloat screenWidth = UIScreen.mainScreen.bounds.size.width;
    CGFloat screenHeight = UIScreen.mainScreen.bounds.size.height;
    CGFloat cellWidth = screenWidth / 4.0;
    CGFloat cellHeight = screenHeight / 6.0;

    self.initialImagesLoaded = MIN(20, images.count);

    // Clear existing thumbnails
    for (UIView *subview in self.scrollView.subviews) {
        [subview removeFromSuperview];
    }
    [self.thumbnailButtons removeAllObjects];

    // Load initial batch
    for (NSInteger i = 0; i < self.initialImagesLoaded; i++) {
        NSDictionary *imageData = images[i];
        NSString *hash = imageData[@"hash"];
        if (!hash) continue;

        UIButton *thumbnail = [UIButton buttonWithType:UIButtonTypeCustom];
        NSInteger row = i / 4;
        NSInteger col = i % 4;
        thumbnail.frame = CGRectMake(col * cellWidth, row * cellHeight, cellWidth, cellHeight);
        thumbnail.tag = i;
        [thumbnail addTarget:self action:@selector(buttonClicked:) forControlEvents:UIControlEventTouchUpInside];

        // Add liquid glass effect to thumbnails
        [thumbnail applyLiquidGlassEffect:LiquidGlassStyleUltraThin cornerRadius:12];

        // Set placeholder
        thumbnail.backgroundColor = [UIColor colorWithWhite:0.2 alpha:0.5];

        [self.scrollView addSubview:thumbnail];
        self.thumbnailButtons[@(i)] = thumbnail;

        // Load image asynchronously
        NSURL *imageURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://i.imgur.com/%@s.jpg", hash]];
        [[ImgurImageManager sharedManager] loadImageFromURL:imageURL completion:^(UIImage * _Nullable image, NSError * _Nullable error) {
            if (image && thumbnail.superview) {
                [thumbnail setImage:image forState:UIControlStateNormal];
                thumbnail.imageView.contentMode = UIViewContentModeScaleAspectFill;
                thumbnail.imageView.clipsToBounds = YES;
            }
        }];
    }

    // Update content size
    NSInteger rows = (self.initialImagesLoaded + 3) / 4;
    [self.scrollView setContentSize:CGSizeMake(screenWidth, rows * cellHeight)];

    // Load remaining images in background
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self loadMoreImages];
    });
}

- (IBAction)buttonClicked:(id)sender {
    [self.activityView startAnimating];
    [self.activityView setHidden:NO];
    [self loadImageView:sender];
}

- (void)loadMoreImages {
    CGFloat screenWidth = UIScreen.mainScreen.bounds.size.width;
    CGFloat screenHeight = UIScreen.mainScreen.bounds.size.height;
    CGFloat cellWidth = screenWidth / 4.0;
    CGFloat cellHeight = screenHeight / 6.0;

    for (NSInteger i = self.initialImagesLoaded; i < self.results.count; i++) {
        NSDictionary *imageData = self.results[i];
        NSString *hash = imageData[@"hash"];
        if (!hash) continue;

        dispatch_async(dispatch_get_main_queue(), ^{
            UIButton *thumbnail = [UIButton buttonWithType:UIButtonTypeCustom];
            NSInteger row = i / 4;
            NSInteger col = i % 4;
            thumbnail.frame = CGRectMake(col * cellWidth, row * cellHeight, cellWidth, cellHeight);
            thumbnail.tag = i;
            [thumbnail addTarget:self action:@selector(buttonClicked:) forControlEvents:UIControlEventTouchUpInside];

            // Add liquid glass effect
            [thumbnail applyLiquidGlassEffect:LiquidGlassStyleUltraThin cornerRadius:12];
            thumbnail.backgroundColor = [UIColor colorWithWhite:0.2 alpha:0.5];

            [self.scrollView addSubview:thumbnail];
            self.thumbnailButtons[@(i)] = thumbnail;

            // Update content size
            NSInteger totalRows = (i + 4) / 4;
            [self.scrollView setContentSize:CGSizeMake(screenWidth, totalRows * cellHeight)];
        });

        // Load image asynchronously
        NSURL *imageURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://i.imgur.com/%@s.jpg", hash]];
        [[ImgurImageManager sharedManager] loadImageFromURL:imageURL completion:^(UIImage * _Nullable image, NSError * _Nullable error) {
            UIButton *btn = self.thumbnailButtons[@(i)];
            if (image && btn && btn.superview) {
                [btn setImage:image forState:UIControlStateNormal];
                btn.imageView.contentMode = UIViewContentModeScaleAspectFill;
                btn.imageView.clipsToBounds = YES;
            }
        }];
    }

    dispatch_async(dispatch_get_main_queue(), ^{
        [self.activityView stopAnimating];
        self.pagesLoaded++;
    });
}

#pragma mark - Gallery Switching

- (void)loadNewPickerView {
    [self switchToGalleryType:@"new"];
}

- (void)loadHotPickerView {
    [self switchToGalleryType:@"hot"];
}

- (void)loadTopPickerView {
    [self switchToGalleryType:@"top"];
}

- (void)switchToGalleryType:(NSString *)type {
    self.searchBar.hidden = YES;
    self.searchBar.text = @"";
    self.pageNo = 0;
    self.currentViewTitle = type;
    self.nxtBtn.enabled = YES;

    // Clear existing thumbnails
    [self.scrollView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    [self.thumbnailButtons removeAllObjects];
    [self.scrollView setContentOffset:CGPointZero animated:NO];

    // Load new data
    [self loadGalleryData:type page:0];
}

- (void)reloadView {
    self.searchBar.hidden = YES;
    self.pageNo = 0;
    [self.activityView startAnimating];
    [self.activityView setHidden:NO];

    if ([self.currentViewTitle isEqualToString:@"Search Results"]) {
        [self loadSearchResults];
    } else {
        [self loadGalleryData:self.currentViewTitle page:0];
    }
}

- (void)loadNextPage {
    self.searchBar.hidden = YES;
    self.pageNo++;

    // Clear and prepare for next page
    [self.scrollView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    [self.thumbnailButtons removeAllObjects];
    [self.scrollView setContentOffset:CGPointZero animated:NO];

    // Load next page
    [self loadGalleryData:self.currentViewTitle page:self.pageNo];
}

- (void)uploadImage {
    if (!self.uploadImageView) {
        self.uploadImageView = [[UploadImageController alloc] init];
    }
    [self.navigationController pushViewController:self.uploadImageView animated:YES];
}

- (void)loadImageView:(id)sender {
    UIButton *button = (UIButton *)sender;

    if (!self.imageController) {
        self.imageController = [[ViewController alloc] initWithNibName:@"ViewController" bundle:nil];
    }

    self.imageController.currentPage = [NSString stringWithFormat:@"%ld", (long)button.tag];
    self.imageController.results = self.results;

    if (button.tag < self.results.count) {
        NSDictionary *imageData = self.results[button.tag];
        id title = imageData[@"title"];

        if (self.imageController.textView) {
            self.imageController.textView.text = (title && title != [NSNull null]) ? title : @"";
        }
    }

    [self.navigationController pushViewController:self.imageController animated:YES];
}

#pragma mark - Search

- (void)showSearchBar {
    self.searchBar.hidden = !self.searchBar.hidden;
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    [self.searchBar resignFirstResponder];
    self.searchBar.hidden = YES;

    if (self.searchBar.text.length == 0 && !self.nxtBtn.isEnabled) {
        [self reloadView];
        self.nxtBtn.enabled = YES;
    }
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    [self loadSearchResults];
}

- (void)loadSearchResults {
    if (self.searchBar.text.length == 0) {
        [self showErrorAlert:@"Search Error" message:@"Please enter a search query"];
        return;
    }

    self.currentViewTitle = @"Search Results";
    self.nxtBtn.enabled = NO;
    [self.searchBar resignFirstResponder];
    self.pageNo = 0;

    [self.scrollView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    [self.thumbnailButtons removeAllObjects];

    [[ImgurAPIManager sharedManager] searchImages:self.searchBar.text completion:^(NSDictionary * _Nullable response, NSError * _Nullable error) {
        [self.activityView stopAnimating];
        self.view.userInteractionEnabled = YES;

        if (error) {
            [self handleAPIError:error];
            return;
        }

        [self processGalleryResponse:response];
    }];
}

#pragma mark - Helper Methods

- (void)showErrorAlert:(NSString *)title message:(NSString *)message {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title
                                                                   message:message
                                                            preferredStyle:UIAlertControllerStyleAlert];

    UIAlertAction *dismissAction = [UIAlertAction actionWithTitle:@"Dismiss"
                                                           style:UIAlertActionStyleDefault
                                                         handler:nil];
    [alert addAction:dismissAction];

    [self presentViewController:alert animated:YES completion:nil];
}

@end
