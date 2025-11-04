//
//  ImgurImageManager.m
//  ImgurViewer
//
//  Created for iOS 15+ modernization - 2025
//  Copyright (c) 2025 University of Waterloo. All rights reserved.
//

#import "ImgurImageManager.h"

@interface ImgurImageManager ()

@property (nonatomic, strong) NSURLSession *session;
@property (nonatomic, strong) NSCache<NSURL *, UIImage *> *imageCache;
@property (nonatomic, strong) NSMutableDictionary<NSURL *, NSMutableArray<ImageCompletionHandler> *> *pendingHandlers;
@property (nonatomic, strong) dispatch_queue_t processingQueue;

@end

@implementation ImgurImageManager

+ (instancetype)sharedManager {
    static ImgurImageManager *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        // Configure URLSession with caching and timeout
        NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
        config.requestCachePolicy = NSURLRequestReturnCacheDataElseLoad;
        config.timeoutIntervalForRequest = 30.0;
        config.timeoutIntervalForResource = 60.0;

        // Set up URL cache (50MB memory, 200MB disk)
        NSURLCache *urlCache = [[NSURLCache alloc] initWithMemoryCapacity:50 * 1024 * 1024
                                                             diskCapacity:200 * 1024 * 1024
                                                                 diskPath:@"imgurImageCache"];
        config.URLCache = urlCache;

        _session = [NSURLSession sessionWithConfiguration:config];

        // Set up in-memory image cache (100 images max)
        _imageCache = [[NSCache alloc] init];
        _imageCache.countLimit = 100;
        _imageCache.totalCostLimit = 100 * 1024 * 1024; // 100MB

        // Track pending requests to avoid duplicate loads
        _pendingHandlers = [NSMutableDictionary dictionary];

        // Create processing queue for image decoding
        _processingQueue = dispatch_queue_create("com.imgur.imageprocessing", DISPATCH_QUEUE_CONCURRENT);

        // Listen for memory warnings
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(handleMemoryWarning:)
                                                     name:UIApplicationDidReceiveMemoryWarningNotification
                                                   object:nil];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)handleMemoryWarning:(NSNotification *)notification {
    [self clearCache];
}

- (nullable UIImage *)cachedImageForURL:(NSURL *)url {
    return [self.imageCache objectForKey:url];
}

- (void)loadImageFromURL:(NSURL *)url completion:(ImageCompletionHandler)completion {
    if (!url || !completion) {
        if (completion) {
            completion(nil, [NSError errorWithDomain:@"ImgurImageManager"
                                               code:-1
                                           userInfo:@{NSLocalizedDescriptionKey: @"Invalid URL or completion handler"}]);
        }
        return;
    }

    // Check memory cache first
    UIImage *cachedImage = [self.imageCache objectForKey:url];
    if (cachedImage) {
        dispatch_async(dispatch_get_main_queue(), ^{
            completion(cachedImage, nil);
        });
        return;
    }

    @synchronized(self.pendingHandlers) {
        // Check if there's already a request in progress for this URL
        NSMutableArray *handlers = self.pendingHandlers[url];
        if (handlers) {
            // Add to existing request's handlers
            [handlers addObject:completion];
            return;
        }

        // Create new handler array for this URL
        self.pendingHandlers[url] = [NSMutableArray arrayWithObject:completion];
    }

    // Create data task
    NSURLSessionDataTask *task = [self.session dataTaskWithURL:url
                                             completionHandler:^(NSData * _Nullable data,
                                                               NSURLResponse * _Nullable response,
                                                               NSError * _Nullable error) {
        NSMutableArray *handlers;
        @synchronized(self.pendingHandlers) {
            handlers = self.pendingHandlers[url];
            [self.pendingHandlers removeObjectForKey:url];
        }

        if (error) {
            // Network error - notify all handlers
            dispatch_async(dispatch_get_main_queue(), ^{
                for (ImageCompletionHandler handler in handlers) {
                    handler(nil, error);
                }
            });
            return;
        }

        if (!data || data.length == 0) {
            NSError *dataError = [NSError errorWithDomain:@"ImgurImageManager"
                                                    code:-2
                                                userInfo:@{NSLocalizedDescriptionKey: @"No image data received"}];
            dispatch_async(dispatch_get_main_queue(), ^{
                for (ImageCompletionHandler handler in handlers) {
                    handler(nil, dataError);
                }
            });
            return;
        }

        // Decode image on background queue to avoid blocking main thread
        dispatch_async(self.processingQueue, ^{
            UIImage *image = [UIImage imageWithData:data];

            if (!image) {
                NSError *imageError = [NSError errorWithDomain:@"ImgurImageManager"
                                                         code:-3
                                                     userInfo:@{NSLocalizedDescriptionKey: @"Failed to decode image"}];
                dispatch_async(dispatch_get_main_queue(), ^{
                    for (ImageCompletionHandler handler in handlers) {
                        handler(nil, imageError);
                    }
                });
                return;
            }

            // Cache the image
            [self.imageCache setObject:image forKey:url cost:data.length];

            // Notify all handlers on main thread
            dispatch_async(dispatch_get_main_queue(), ^{
                for (ImageCompletionHandler handler in handlers) {
                    handler(image, nil);
                }
            });
        });
    }];

    [task resume];
}

- (void)cancelAllOperations {
    [self.session invalidateAndCancel];

    // Recreate session
    NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
    config.requestCachePolicy = NSURLRequestReturnCacheDataElseLoad;
    config.timeoutIntervalForRequest = 30.0;
    self.session = [NSURLSession sessionWithConfiguration:config];

    @synchronized(self.pendingHandlers) {
        [self.pendingHandlers removeAllObjects];
    }
}

- (void)clearCache {
    [self.imageCache removeAllObjects];
    [self.session.configuration.URLCache removeAllCachedResponses];
}

@end
