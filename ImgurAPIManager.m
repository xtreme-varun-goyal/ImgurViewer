//
//  ImgurAPIManager.m
//  ImgurViewer
//
//  Created for iOS 15+ modernization - 2025
//  Copyright (c) 2025 University of Waterloo. All rights reserved.
//

#import "ImgurAPIManager.h"

@interface ImgurAPIManager ()

@property (nonatomic, strong) NSURLSession *session;
@property (nonatomic, strong) NSMutableSet<NSURLSessionDataTask *> *activeTasks;

@end

@implementation ImgurAPIManager

+ (instancetype)sharedManager {
    static ImgurAPIManager *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
        config.timeoutIntervalForRequest = 30.0;
        config.timeoutIntervalForResource = 60.0;

        _session = [NSURLSession sessionWithConfiguration:config];
        _activeTasks = [NSMutableSet set];
    }
    return self;
}

- (void)fetchGallery:(NSString *)galleryType page:(NSInteger)page completion:(APICompletionHandler)completion {
    if (!completion) return;

    NSString *urlString;
    if (page > 0) {
        urlString = [NSString stringWithFormat:@"https://imgur.com/gallery/%@/page/%ld.json",
                     galleryType, (long)page];
    } else {
        urlString = [NSString stringWithFormat:@"https://imgur.com/gallery/%@.json", galleryType];
    }

    [self performRequest:urlString completion:completion];
}

- (void)searchImages:(NSString *)query completion:(APICompletionHandler)completion {
    if (!completion) return;

    NSString *encodedQuery = [query stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    NSString *urlString = [NSString stringWithFormat:@"https://imgur.com/gallery/?q=%@", encodedQuery];

    [self performRequest:urlString completion:completion];
}

- (void)fetchImageDetails:(NSString *)imageHash completion:(APICompletionHandler)completion {
    if (!completion) return;

    NSString *urlString = [NSString stringWithFormat:@"https://imgur.com/gallery/%@.json", imageHash];

    [self performRequest:urlString completion:completion];
}

- (void)performRequest:(NSString *)urlString completion:(APICompletionHandler)completion {
    NSURL *url = [NSURL URLWithString:urlString];
    if (!url) {
        NSError *error = [NSError errorWithDomain:@"ImgurAPIManager"
                                            code:-1
                                        userInfo:@{NSLocalizedDescriptionKey: @"Invalid URL"}];
        dispatch_async(dispatch_get_main_queue(), ^{
            completion(nil, error);
        });
        return;
    }

    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:@"GET"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [request setValue:@"ImgurViewer/3.0" forHTTPHeaderField:@"User-Agent"];

    NSURLSessionDataTask *task = [self.session dataTaskWithRequest:request
                                                  completionHandler:^(NSData * _Nullable data,
                                                                    NSURLResponse * _Nullable response,
                                                                    NSError * _Nullable error) {
        @synchronized(self.activeTasks) {
            [self.activeTasks removeObject:[NSURLSessionDataTask self]];
        }

        if (error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(nil, error);
            });
            return;
        }

        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        if (httpResponse.statusCode != 200) {
            NSError *httpError = [NSError errorWithDomain:@"ImgurAPIManager"
                                                    code:httpResponse.statusCode
                                                userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat:@"HTTP Error: %ld", (long)httpResponse.statusCode]}];
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(nil, httpError);
            });
            return;
        }

        if (!data || data.length == 0) {
            NSError *dataError = [NSError errorWithDomain:@"ImgurAPIManager"
                                                    code:-2
                                                userInfo:@{NSLocalizedDescriptionKey: @"No data received"}];
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(nil, dataError);
            });
            return;
        }

        // Parse JSON on background thread
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSError *jsonError = nil;
            NSDictionary *jsonResponse = [NSJSONSerialization JSONObjectWithData:data
                                                                        options:0
                                                                          error:&jsonError];

            dispatch_async(dispatch_get_main_queue(), ^{
                if (jsonError) {
                    completion(nil, jsonError);
                } else {
                    completion(jsonResponse, nil);
                }
            });
        });
    }];

    @synchronized(self.activeTasks) {
        [self.activeTasks addObject:task];
    }

    [task resume];
}

- (void)cancelAllRequests {
    @synchronized(self.activeTasks) {
        for (NSURLSessionDataTask *task in self.activeTasks) {
            [task cancel];
        }
        [self.activeTasks removeAllObjects];
    }
}

@end
