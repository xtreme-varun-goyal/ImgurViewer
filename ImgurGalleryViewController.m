//
//  ImgurGalleryViewController.m
//  ImgurViewer
//
//  Complete rewrite for iOS 15+ - 2025
//  Modern UICollectionView-based gallery
//

#import "ImgurGalleryViewController.h"
#import "ImgurImageViewController.h"
#import "ImgurAPIManager.h"
#import "ImgurImageManager.h"
#import "UIView+LiquidGlass.h"

@interface ImgurGalleryViewController ()

@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) UIRefreshControl *refreshControl;
@property (nonatomic, strong) UISearchBar *searchBar;
@property (nonatomic, strong) NSArray *galleryItems;
@property (nonatomic, strong) NSString *galleryType;
@property (nonatomic, assign) NSInteger currentPage;
@property (nonatomic, assign) BOOL isLoading;
@property (nonatomic, strong) UIActivityIndicatorView *loadingIndicator;

@end

@implementation ImgurGalleryViewController

static NSString *const kCellIdentifier = @"ImgurImageCell";

- (instancetype)initWithGalleryType:(NSString *)galleryType {
    self = [super init];
    if (self) {
        _galleryType = galleryType ?: @"hot";
        _galleryItems = @[];
        _currentPage = 0;
        _isLoading = NO;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    // Configure view
    self.title = [self.galleryType capitalizedString];
    self.view.backgroundColor = [UIColor systemBackgroundColor];

    [self setupCollectionView];
    [self setupSearchBar];
    [self setupNavigationBar];
    [self setupRefreshControl];
    [self setupLoadingIndicator];

    // Initial load
    [self loadGalleryData:NO];
}

#pragma mark - UI Setup

- (void)setupCollectionView {
    // Create flow layout
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    layout.minimumInteritemSpacing = 8;
    layout.minimumLineSpacing = 8;
    layout.sectionInset = UIEdgeInsetsMake(8, 8, 8, 8);

    // Calculate item size (3 columns)
    CGFloat totalSpacing = layout.sectionInset.left + layout.sectionInset.right + (layout.minimumInteritemSpacing * 2);
    CGFloat itemWidth = (UIScreen.mainScreen.bounds.size.width - totalSpacing) / 3.0;
    layout.itemSize = CGSizeMake(itemWidth, itemWidth);

    // Create collection view
    self.collectionView = [[UICollectionView alloc] initWithFrame:self.view.bounds collectionViewLayout:layout];
    self.collectionView.backgroundColor = [UIColor systemBackgroundColor];
    self.collectionView.delegate = self;
    self.collectionView.dataSource = self;
    self.collectionView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

    // Register cell
    [self.collectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:kCellIdentifier];

    [self.view addSubview:self.collectionView];
}

- (void)setupSearchBar {
    self.searchBar = [[UISearchBar alloc] init];
    self.searchBar.delegate = self;
    self.searchBar.placeholder = @"Search Imgur...";
    self.searchBar.searchBarStyle = UISearchBarStyleMinimal;
}

- (void)setupNavigationBar {
    // Gallery type selector
    UIBarButtonItem *newBtn = [[UIBarButtonItem alloc] initWithTitle:@"New" style:UIBarButtonItemStylePlain target:self action:@selector(loadNewGallery)];
    UIBarButtonItem *hotBtn = [[UIBarButtonItem alloc] initWithTitle:@"Hot" style:UIBarButtonItemStylePlain target:self action:@selector(loadHotGallery)];
    UIBarButtonItem *topBtn = [[UIBarButtonItem alloc] initWithTitle:@"Top" style:UIBarButtonItemStylePlain target:self action:@selector(loadTopGallery)];

    self.navigationItem.leftBarButtonItems = @[newBtn, hotBtn, topBtn];

    // Search button
    UIBarButtonItem *searchBtn = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSearch target:self action:@selector(toggleSearch)];

    // Upload button
    UIBarButtonItem *uploadBtn = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCamera target:self action:@selector(showUpload)];

    self.navigationItem.rightBarButtonItems = @[uploadBtn, searchBtn];
}

- (void)setupRefreshControl {
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self action:@selector(handleRefresh:) forControlEvents:UIControlEventValueChanged];
    self.collectionView.refreshControl = self.refreshControl;
}

- (void)setupLoadingIndicator {
    self.loadingIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleLarge];
    self.loadingIndicator.center = self.view.center;
    self.loadingIndicator.hidesWhenStopped = YES;
    [self.view addSubview:self.loadingIndicator];
}

#pragma mark - Data Loading

- (void)loadGalleryData:(BOOL)isRefresh {
    if (self.isLoading) return;

    self.isLoading = YES;
    [self.loadingIndicator startAnimating];

    if (isRefresh) {
        self.currentPage = 0;
    }

    [[ImgurAPIManager sharedManager] fetchGallery:self.galleryType page:self.currentPage completion:^(NSDictionary * _Nullable response, NSError * _Nullable error) {
        self.isLoading = NO;
        [self.loadingIndicator stopAnimating];
        [self.refreshControl endRefreshing];

        if (error) {
            [self showError:error.localizedDescription];
            return;
        }

        [self processGalleryResponse:response isRefresh:isRefresh];
    }];
}

- (void)processGalleryResponse:(NSDictionary *)response isRefresh:(BOOL)isRefresh {
    NSArray *keys = [response allKeys];
    if (keys.count == 0) return;

    NSArray *items = response[keys.firstObject];
    if (!items || items.count == 0) {
        [self showError:@"No images found"];
        return;
    }

    if (isRefresh) {
        self.galleryItems = items;
    } else {
        NSMutableArray *combined = [self.galleryItems mutableCopy];
        [combined addObjectsFromArray:items];
        self.galleryItems = combined;
    }

    [self.collectionView reloadData];
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.galleryItems.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:kCellIdentifier forIndexPath:indexPath];

    // Clear previous content
    [[cell.contentView subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];

    // Apply liquid glass effect
    [cell.contentView applyLiquidGlassEffect:LiquidGlassStyleUltraThin cornerRadius:12];
    cell.contentView.backgroundColor = [UIColor colorWithWhite:0.2 alpha:0.3];

    // Get image data
    NSDictionary *imageData = self.galleryItems[indexPath.item];
    NSString *hash = imageData[@"hash"];

    if (hash) {
        // Create image view
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:cell.contentView.bounds];
        imageView.contentMode = UIViewContentModeScaleAspectFill;
        imageView.clipsToBounds = YES;
        imageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [cell.contentView addSubview:imageView];

        // Load image
        NSURL *thumbnailURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://i.imgur.com/%@s.jpg", hash]];
        [[ImgurImageManager sharedManager] loadImageFromURL:thumbnailURL completion:^(UIImage * _Nullable image, NSError * _Nullable error) {
            if (image) {
                imageView.image = image;
            }
        }];
    }

    return cell;
}

#pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *imageData = self.galleryItems[indexPath.item];

    ImgurImageViewController *imageVC = [[ImgurImageViewController alloc] initWithGalleryItems:self.galleryItems currentIndex:indexPath.item];
    [self.navigationController pushViewController:imageVC animated:YES];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    // Load more when near bottom
    CGFloat offsetY = scrollView.contentOffset.y;
    CGFloat contentHeight = scrollView.contentSize.height;
    CGFloat frameHeight = scrollView.frame.size.height;

    if (offsetY > contentHeight - frameHeight * 2 && !self.isLoading) {
        self.currentPage++;
        [self loadGalleryData:NO];
    }
}

#pragma mark - Actions

- (void)handleRefresh:(UIRefreshControl *)refreshControl {
    [self loadGalleryData:YES];
}

- (void)loadNewGallery {
    self.galleryType = @"new";
    self.title = @"New";
    [self loadGalleryData:YES];
}

- (void)loadHotGallery {
    self.galleryType = @"hot";
    self.title = @"Hot";
    [self loadGalleryData:YES];
}

- (void)loadTopGallery {
    self.galleryType = @"top";
    self.title = @"Top";
    [self loadGalleryData:YES];
}

- (void)toggleSearch {
    if (self.searchBar.superview) {
        [self.searchBar removeFromSuperview];
        self.navigationItem.titleView = nil;
    } else {
        self.navigationItem.titleView = self.searchBar;
        [self.searchBar becomeFirstResponder];
    }
}

- (void)showUpload {
    // TODO: Present upload view controller
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Upload" message:@"Upload feature coming soon!" preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - UISearchBarDelegate

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    [searchBar resignFirstResponder];

    if (searchBar.text.length == 0) return;

    self.isLoading = YES;
    [self.loadingIndicator startAnimating];

    [[ImgurAPIManager sharedManager] searchImages:searchBar.text completion:^(NSDictionary * _Nullable response, NSError * _Nullable error) {
        self.isLoading = NO;
        [self.loadingIndicator stopAnimating];

        if (error) {
            [self showError:error.localizedDescription];
            return;
        }

        [self processGalleryResponse:response isRefresh:YES];
    }];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    [searchBar resignFirstResponder];
    [self toggleSearch];
}

#pragma mark - Error Handling

- (void)showError:(NSString *)message {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Error"
                                                                   message:message
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

@end
