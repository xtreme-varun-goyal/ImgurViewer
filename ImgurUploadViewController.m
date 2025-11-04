//
//  ImgurUploadViewController.m
//  ImgurViewer
//
//  Complete rewrite for iOS 15+ - 2025
//  Modern image upload with PHPickerViewController
//

#import "ImgurUploadViewController.h"
#import "UIView+LiquidGlass.h"

@interface ImgurUploadViewController () <PHPickerViewControllerDelegate>

@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) UITextField *titleField;
@property (nonatomic, strong) UITextView *descriptionView;
@property (nonatomic, strong) UIButton *selectButton;
@property (nonatomic, strong) UIButton *uploadButton;
@property (nonatomic, strong) UIImage *selectedImage;
@property (nonatomic, strong) UIProgressView *progressView;
@property (nonatomic, strong) UIActivityIndicatorView *activityIndicator;

@end

@implementation ImgurUploadViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.title = @"Upload to Imgur";
    self.view.backgroundColor = [UIColor systemBackgroundColor];

    [self setupUI];
    [self setupNavigationBar];
}

- (void)setupNavigationBar {
    UIBarButtonItem *cancelBtn = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancel)];
    self.navigationItem.leftBarButtonItem = cancelBtn;
}

- (void)setupUI {
    UIScrollView *scrollView = [[UIScrollView alloc] initWithFrame:self.view.bounds];
    scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:scrollView];

    CGFloat padding = 20;
    CGFloat y = 20;
    CGFloat width = self.view.bounds.size.width - (padding * 2);

    // Image preview
    self.imageView = [[UIImageView alloc] initWithFrame:CGRectMake(padding, y, width, 250)];
    self.imageView.contentMode = UIViewContentModeScaleAspectFit;
    self.imageView.backgroundColor = [UIColor secondarySystemBackgroundColor];
    self.imageView.layer.cornerRadius = 12;
    self.imageView.clipsToBounds = YES;
    [self.imageView applyLiquidGlassEffect:LiquidGlassStyleLight cornerRadius:12];
    [scrollView addSubview:self.imageView];
    y += 250 + padding;

    // Select photo button
    self.selectButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.selectButton.frame = CGRectMake(padding, y, width, 50);
    [self.selectButton setTitle:@"Select Photo" forState:UIControlStateNormal];
    self.selectButton.titleLabel.font = [UIFont systemFontOfSize:18 weight:UIFontWeightSemibold];
    self.selectButton.backgroundColor = [UIColor systemBlueColor];
    [self.selectButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.selectButton.layer.cornerRadius = 12;
    [self.selectButton addTarget:self action:@selector(selectPhoto) forControlEvents:UIControlEventTouchUpInside];
    [scrollView addSubview:self.selectButton];
    y += 50 + padding;

    // Title field
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(padding, y, width, 20)];
    titleLabel.text = @"Title (optional)";
    titleLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightMedium];
    titleLabel.textColor = [UIColor secondaryLabelColor];
    [scrollView addSubview:titleLabel];
    y += 20 + 8;

    self.titleField = [[UITextField alloc] initWithFrame:CGRectMake(padding, y, width, 44)];
    self.titleField.placeholder = @"Enter a title...";
    self.titleField.borderStyle = UITextBorderStyleRoundedRect;
    self.titleField.font = [UIFont systemFontOfSize:16];
    [scrollView addSubview:self.titleField];
    y += 44 + padding;

    // Description field
    UILabel *descLabel = [[UILabel alloc] initWithFrame:CGRectMake(padding, y, width, 20)];
    descLabel.text = @"Description (optional)";
    descLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightMedium];
    descLabel.textColor = [UIColor secondaryLabelColor];
    [scrollView addSubview:descLabel];
    y += 20 + 8;

    self.descriptionView = [[UITextView alloc] initWithFrame:CGRectMake(padding, y, width, 100)];
    self.descriptionView.font = [UIFont systemFontOfSize:16];
    self.descriptionView.layer.cornerRadius = 8;
    self.descriptionView.layer.borderColor = [[UIColor separatorColor] CGColor];
    self.descriptionView.layer.borderWidth = 0.5;
    [scrollView addSubview:self.descriptionView];
    y += 100 + padding;

    // Progress view (hidden initially)
    self.progressView = [[UIProgressView alloc] initWithFrame:CGRectMake(padding, y, width, 4)];
    self.progressView.hidden = YES;
    [scrollView addSubview:self.progressView];
    y += 4 + 8;

    // Activity indicator
    self.activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleMedium];
    self.activityIndicator.center = CGPointMake(self.view.bounds.size.width / 2, y + 20);
    self.activityIndicator.hidesWhenStopped = YES;
    [scrollView addSubview:self.activityIndicator];
    y += 40 + padding;

    // Upload button
    self.uploadButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.uploadButton.frame = CGRectMake(padding, y, width, 50);
    [self.uploadButton setTitle:@"Upload to Imgur" forState:UIControlStateNormal];
    self.uploadButton.titleLabel.font = [UIFont systemFontOfSize:18 weight:UIFontWeightBold];
    self.uploadButton.backgroundColor = [UIColor systemGreenColor];
    [self.uploadButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.uploadButton.layer.cornerRadius = 12;
    self.uploadButton.enabled = NO;
    self.uploadButton.alpha = 0.5;
    [self.uploadButton addTarget:self action:@selector(uploadImage) forControlEvents:UIControlEventTouchUpInside];
    [scrollView addSubview:self.uploadButton];
    y += 50 + padding;

    scrollView.contentSize = CGSizeMake(self.view.bounds.size.width, y);
}

#pragma mark - Actions

- (void)selectPhoto {
    PHPickerConfiguration *config = [[PHPickerConfiguration alloc] initWithPhotoLibrary:[PHPhotoLibrary sharedPhotoLibrary]];
    config.filter = [PHPickerFilter imagesFilter];
    config.selectionLimit = 1;

    PHPickerViewController *picker = [[PHPickerViewController alloc] initWithConfiguration:config];
    picker.delegate = self;
    [self presentViewController:picker animated:YES completion:nil];
}

- (void)uploadImage {
    if (!self.selectedImage) {
        [self showError:@"Please select an image first"];
        return;
    }

    [self.activityIndicator startAnimating];
    self.progressView.hidden = NO;
    self.progressView.progress = 0;
    self.uploadButton.enabled = NO;
    self.selectButton.enabled = NO;

    // Convert image to data
    NSData *imageData = UIImageJPEGRepresentation(self.selectedImage, 0.8);
    if (!imageData) {
        [self showError:@"Failed to process image"];
        return;
    }

    // TODO: Implement actual Imgur upload API
    // For now, simulate upload
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.activityIndicator stopAnimating];
        self.progressView.hidden = YES;
        self.uploadButton.enabled = YES;
        self.selectButton.enabled = YES;

        [self showSuccess:@"Upload feature requires Imgur API credentials. Add your API key to complete the upload functionality."];
    });
}

- (void)cancel {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - PHPickerViewControllerDelegate

- (void)picker:(PHPickerViewController *)picker didFinishPicking:(NSArray<PHPickerResult *> *)results {
    [picker dismissViewControllerAnimated:YES completion:nil];

    if (results.count == 0) return;

    PHPickerResult *result = results.firstObject;

    [result.itemProvider loadObjectOfClass:[UIImage class] completionHandler:^(__kindof id<NSItemProviderReading>  _Nullable object, NSError * _Nullable error) {
        if ([object isKindOfClass:[UIImage class]]) {
            UIImage *image = (UIImage *)object;

            dispatch_async(dispatch_get_main_queue(), ^{
                self.selectedImage = image;
                self.imageView.image = image;
                self.uploadButton.enabled = YES;
                self.uploadButton.alpha = 1.0;
            });
        }
    }];
}

#pragma mark - Helpers

- (void)showError:(NSString *)message {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Error"
                                                                   message:message
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)showSuccess:(NSString *)message {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Success"
                                                                   message:message
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self dismissViewControllerAnimated:YES completion:nil];
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}

@end
