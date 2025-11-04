//
//  ImgurGalleryViewController.h
//  ImgurViewer
//
//  Complete rewrite for iOS 15+ - 2025
//  Modern UICollectionView-based gallery
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Modern gallery view controller using UICollectionView
 * Replaces the old GallerryPickerViewController button grid approach
 */
@interface ImgurGalleryViewController : UIViewController <UISearchBarDelegate, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>

/**
 * Initialize with gallery type
 * @param galleryType "new", "hot", "top", or "latest"
 */
- (instancetype)initWithGalleryType:(NSString *)galleryType;

@end

NS_ASSUME_NONNULL_END
