//
//  ImgurImageManager.h
//  ImgurViewer
//
//  Created for iOS 15+ modernization - 2025
//  Copyright (c) 2025 University of Waterloo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef void(^ImageCompletionHandler)(UIImage * _Nullable image, NSError * _Nullable error);

/**
 * Modern image loading manager with URLSession and NSCache
 * Replaces legacy synchronous NSData image loading
 */
@interface ImgurImageManager : NSObject

+ (instancetype)sharedManager;

/**
 * Load image asynchronously from URL with caching
 * @param url The URL of the image to load
 * @param completion Completion handler called with the loaded image or error
 */
- (void)loadImageFromURL:(NSURL *)url completion:(ImageCompletionHandler)completion;

/**
 * Cancel all pending image load operations
 */
- (void)cancelAllOperations;

/**
 * Clear the image cache
 */
- (void)clearCache;

/**
 * Check if image exists in cache
 */
- (nullable UIImage *)cachedImageForURL:(NSURL *)url;

@end

NS_ASSUME_NONNULL_END
