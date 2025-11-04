//
//  ImgurImageViewController.h
//  ImgurViewer
//
//  Complete rewrite for iOS 15+ - 2025
//  Modern page-based image viewer with zoom and sharing
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Modern image viewer with swipe navigation and zoom
 * Replaces old ViewController.h/m
 */
@interface ImgurImageViewController : UIViewController

/**
 * Initialize with gallery items and starting index
 */
- (instancetype)initWithGalleryItems:(NSArray *)items currentIndex:(NSInteger)index;

@end

NS_ASSUME_NONNULL_END
