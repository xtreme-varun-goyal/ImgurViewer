//
//  ImgurAPIManager.h
//  ImgurViewer
//
//  Created for iOS 15+ modernization - 2025
//  Copyright (c) 2025 University of Waterloo. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef void(^APICompletionHandler)(NSDictionary * _Nullable response, NSError * _Nullable error);

/**
 * Modern Imgur API manager using URLSession
 * Replaces legacy NSURLConnection synchronous requests
 */
@interface ImgurAPIManager : NSObject

+ (instancetype)sharedManager;

/**
 * Fetch gallery images (new, hot, top, latest)
 * @param galleryType Type of gallery: "new", "hot", "top", or "latest"
 * @param page Page number (0-indexed)
 * @param completion Completion handler with parsed JSON response
 */
- (void)fetchGallery:(NSString *)galleryType page:(NSInteger)page completion:(APICompletionHandler)completion;

/**
 * Search for images
 * @param query Search query string
 * @param completion Completion handler with parsed JSON response
 */
- (void)searchImages:(NSString *)query completion:(APICompletionHandler)completion;

/**
 * Get image details and comments
 * @param imageHash Imgur image hash
 * @param completion Completion handler with parsed JSON response
 */
- (void)fetchImageDetails:(NSString *)imageHash completion:(APICompletionHandler)completion;

/**
 * Cancel all pending API requests
 */
- (void)cancelAllRequests;

@end

NS_ASSUME_NONNULL_END
