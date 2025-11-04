//
//  ImgurImageViewController.m
//  ImgurViewer
//
//  Complete rewrite for iOS 15+ - 2025
//  Modern page-based image viewer with zoom and sharing
//

#import "ImgurImageViewController.h"
#import "ImgurImageManager.h"
#import "UIView+LiquidGlass.h"

@interface ImgurImageViewController () <UIScrollViewDelegate>

@property (nonatomic, strong) NSArray *galleryItems;
@property (nonatomic, assign) NSInteger currentIndex;
@property (nonatomic, strong) UIScrollView *pageScrollView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UIView *controlsContainer;
@property (nonatomic, strong) NSMutableDictionary<NSNumber *, UIScrollView *> *imageScrollViews;
@property (nonatomic, assign) BOOL controlsVisible;

@end

@implementation ImgurImageViewController

- (instancetype)initWithGalleryItems:(NSArray *)items currentIndex:(NSInteger)index {
    self = [super init];
    if (self) {
        _galleryItems = items;
        _currentIndex = index;
        _imageScrollViews = [NSMutableDictionary dictionary];
        _controlsVisible = YES;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.view.backgroundColor = [UIColor blackColor];

    [self setupPageScrollView];
    [self setupControls];
    [self setupNavigationBar];
    [self loadImagesAroundCurrentIndex];

    // Start at current index
    [self scrollToIndex:self.currentIndex animated:NO];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.navigationController.hidesBarsOnTap = YES;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    self.navigationController.hidesBarsOnTap = NO;
}

#pragma mark - Setup

- (void)setupPageScrollView {
    self.pageScrollView = [[UIScrollView alloc] initWithFrame:self.view.bounds];
    self.pageScrollView.pagingEnabled = YES;
    self.pageScrollView.showsHorizontalScrollIndicator = NO;
    self.pageScrollView.delegate = self;
    self.pageScrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

    CGFloat width = self.view.bounds.size.width;
    CGFloat height = self.view.bounds.size.height;
    self.pageScrollView.contentSize = CGSizeMake(width * self.galleryItems.count, height);

    [self.view addSubview:self.pageScrollView];
}

- (void)setupControls {
    // Title/caption container with liquid glass
    self.controlsContainer = [[UIView alloc] initWithFrame:CGRectMake(0, self.view.bounds.size.height - 100, self.view.bounds.size.width, 100)];
    self.controlsContainer.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
    [self.controlsContainer applyLiquidGlassEffect:LiquidGlassStyleDark cornerRadius:0];

    // Title label
    self.titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(16, 16, self.view.bounds.size.width - 32, 68)];
    self.titleLabel.textColor = [UIColor whiteColor];
    self.titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightMedium];
    self.titleLabel.numberOfLines = 3;
    self.titleLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [self.controlsContainer addSubview:self.titleLabel];

    [self.view addSubview:self.controlsContainer];

    // Update title
    [self updateTitleForCurrentIndex];
}

- (void)setupNavigationBar {
    // Share button
    UIBarButtonItem *shareBtn = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(shareCurrentImage)];

    // Info button (comments/details)
    UIBarButtonItem *infoBtn = [[UIBarButtonItem alloc] initWithImage:[UIImage systemImageNamed:@"info.circle"] style:UIBarButtonItemStylePlain target:self action:@selector(showImageInfo)];

    self.navigationItem.rightBarButtonItems = @[shareBtn, infoBtn];
}

#pragma mark - Image Loading

- (void)loadImagesAroundCurrentIndex {
    // Load current, previous, and next images
    [self loadImageAtIndex:self.currentIndex];

    if (self.currentIndex > 0) {
        [self loadImageAtIndex:self.currentIndex - 1];
    }

    if (self.currentIndex < self.galleryItems.count - 1) {
        [self loadImageAtIndex:self.currentIndex + 1];
    }
}

- (void)loadImageAtIndex:(NSInteger)index {
    if (index < 0 || index >= self.galleryItems.count) return;
    if (self.imageScrollViews[@(index)]) return; // Already loaded

    NSDictionary *imageData = self.galleryItems[index];
    NSString *hash = imageData[@"hash"];
    if (!hash) return;

    // Create scroll view for zooming
    CGFloat width = self.view.bounds.size.width;
    CGFloat height = self.view.bounds.size.height;
    CGRect frame = CGRectMake(width * index, 0, width, height);

    UIScrollView *scrollView = [[UIScrollView alloc] initWithFrame:frame];
    scrollView.delegate = self;
    scrollView.minimumZoomScale = 1.0;
    scrollView.maximumZoomScale = 6.0;
    scrollView.showsVerticalScrollIndicator = NO;
    scrollView.showsHorizontalScrollIndicator = NO;
    scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

    // Add tap gesture to toggle controls
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
    [scrollView addGestureRecognizer:tapGesture];

    // Create image view
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:scrollView.bounds];
    imageView.contentMode = UIViewContentModeScaleAspectFit;
    imageView.tag = 100; // For viewForZooming
    [scrollView addSubview:imageView];

    // Add loading indicator
    UIActivityIndicatorView *loader = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleLarge];
    loader.center = scrollView.center;
    loader.color = [UIColor whiteColor];
    [loader startAnimating];
    [scrollView addSubview:loader];

    [self.pageScrollView addSubview:scrollView];
    self.imageScrollViews[@(index)] = scrollView;

    // Load image
    NSURL *imageURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://i.imgur.com/%@.jpg", hash]];
    [[ImgurImageManager sharedManager] loadImageFromURL:imageURL completion:^(UIImage * _Nullable image, NSError * _Nullable error) {
        [loader stopAnimating];
        [loader removeFromSuperview];

        if (image) {
            imageView.image = image;

            // Adjust image view frame to match image aspect ratio
            CGSize imageSize = image.size;
            CGFloat imageAspect = imageSize.width / imageSize.height;
            CGFloat scrollAspect = scrollView.bounds.size.width / scrollView.bounds.size.height;

            if (imageAspect > scrollAspect) {
                // Image is wider
                CGFloat imageHeight = scrollView.bounds.size.width / imageAspect;
                imageView.frame = CGRectMake(0, (scrollView.bounds.size.height - imageHeight) / 2, scrollView.bounds.size.width, imageHeight);
            } else {
                // Image is taller
                CGFloat imageWidth = scrollView.bounds.size.height * imageAspect;
                imageView.frame = CGRectMake((scrollView.bounds.size.width - imageWidth) / 2, 0, imageWidth, scrollView.bounds.size.height);
            }

            scrollView.contentSize = imageView.frame.size;
        }
    }];
}

- (void)scrollToIndex:(NSInteger)index animated:(BOOL)animated {
    CGFloat width = self.view.bounds.size.width;
    [self.pageScrollView setContentOffset:CGPointMake(width * index, 0) animated:animated];
    self.currentIndex = index;
    [self updateTitleForCurrentIndex];
}

- (void)updateTitleForCurrentIndex {
    if (self.currentIndex < 0 || self.currentIndex >= self.galleryItems.count) return;

    NSDictionary *imageData = self.galleryItems[self.currentIndex];
    id title = imageData[@"title"];

    if (title && title != [NSNull null]) {
        self.titleLabel.text = title;
    } else {
        self.titleLabel.text = @"No title";
    }

    self.title = [NSString stringWithFormat:@"%ld / %lu", (long)(self.currentIndex + 1), (unsigned long)self.galleryItems.count];
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (scrollView != self.pageScrollView) return;

    // Calculate current page
    CGFloat pageWidth = scrollView.bounds.size.width;
    NSInteger newIndex = (NSInteger)(scrollView.contentOffset.x / pageWidth + 0.5);

    if (newIndex != self.currentIndex && newIndex >= 0 && newIndex < self.galleryItems.count) {
        self.currentIndex = newIndex;
        [self updateTitleForCurrentIndex];
        [self loadImagesAroundCurrentIndex];
    }
}

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    if (scrollView == self.pageScrollView) return nil;
    return [scrollView viewWithTag:100]; // Image view
}

- (void)scrollViewDidZoom:(UIScrollView *)scrollView {
    if (scrollView == self.pageScrollView) return;

    // Center the zoomed image
    UIView *imageView = [scrollView viewWithTag:100];
    if (!imageView) return;

    CGFloat offsetX = MAX((scrollView.bounds.size.width - scrollView.contentSize.width) / 2, 0);
    CGFloat offsetY = MAX((scrollView.bounds.size.height - scrollView.contentSize.height) / 2, 0);

    imageView.center = CGPointMake(scrollView.contentSize.width / 2 + offsetX, scrollView.contentSize.height / 2 + offsetY);
}

#pragma mark - Actions

- (void)handleTap:(UITapGestureRecognizer *)gesture {
    // Toggle navigation bar and controls
    self.controlsVisible = !self.controlsVisible;

    [UIView animateWithDuration:0.3 animations:^{
        self.controlsContainer.alpha = self.controlsVisible ? 1.0 : 0.0;
    }];
}

- (void)shareCurrentImage {
    if (self.currentIndex < 0 || self.currentIndex >= self.galleryItems.count) return;

    NSDictionary *imageData = self.galleryItems[self.currentIndex];
    NSString *hash = imageData[@"hash"];
    if (!hash) return;

    NSURL *imageURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://imgur.com/%@", hash]];
    NSString *title = imageData[@"title"];

    NSMutableArray *itemsToShare = [NSMutableArray array];
    [itemsToShare addObject:imageURL];

    if (title && title != [NSNull null]) {
        [itemsToShare addObject:title];
    }

    UIActivityViewController *activityVC = [[UIActivityViewController alloc] initWithActivityItems:itemsToShare applicationActivities:nil];

    // For iPad
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        activityVC.popoverPresentationController.barButtonItem = self.navigationItem.rightBarButtonItems.firstObject;
    }

    [self presentViewController:activityVC animated:YES completion:nil];
}

- (void)showImageInfo {
    if (self.currentIndex < 0 || self.currentIndex >= self.galleryItems.count) return;

    NSDictionary *imageData = self.galleryItems[self.currentIndex];
    id title = imageData[@"title"];
    id description = imageData[@"description"];
    NSNumber *views = imageData[@"views"];
    NSNumber *ups = imageData[@"ups"];
    NSNumber *downs = imageData[@"downs"];

    NSMutableString *info = [NSMutableString string];

    if (title && title != [NSNull null]) {
        [info appendFormat:@"Title: %@\n\n", title];
    }

    if (description && description != [NSNull null]) {
        [info appendFormat:@"Description: %@\n\n", description];
    }

    if (views) {
        [info appendFormat:@"Views: %@\n", views];
    }

    if (ups && downs) {
        [info appendFormat:@"Score: %ld ⬆ / %ld ⬇", (long)ups.integerValue, (long)downs.integerValue];
    }

    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Image Info"
                                                                   message:info.length > 0 ? info : @"No information available"
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

@end
