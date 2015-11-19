//
//  CodingNetAPIClient.m
//  Coding_iOS
//
//  Created by 王 原闯 on 14-7-30.
//  Copyright (c) 2014年 Coding. All rights reserved.
//

#define kNetworkMethodName @[@"Get", @"Post", @"Put", @"Delete",@"Post_Mulit"]

#import "CodingNetAPIClient.h"
#import "Login.h"

@implementation CodingNetAPIClient

static CodingNetAPIClient *_sharedClient = nil;
static dispatch_once_t onceToken;

static CodingNetAPIClient *_codingClient = nil;
static dispatch_once_t onceToken_Coding;

+ (CodingNetAPIClient *)sharedJsonClient {
    dispatch_once(&onceToken, ^{
        _sharedClient = [[CodingNetAPIClient alloc] initWithBaseURL:[NSURL URLWithString:self.baseURLStr]];
    });
    return _sharedClient;
}
+ (id)codingJsonClient{
    dispatch_once(&onceToken_Coding, ^{
        _codingClient = [[CodingNetAPIClient alloc] initWithBaseURL:[NSURL URLWithString:self.codingURLStr]];
    });
    return _codingClient;
}
+ (void)changeJsonClient{
    _sharedClient = [[CodingNetAPIClient alloc] initWithBaseURL:[NSURL URLWithString:self.baseURLStr]];
    _codingClient = [[CodingNetAPIClient alloc] initWithBaseURL:[NSURL URLWithString:self.codingURLStr]];
}

- (id)initWithBaseURL:(NSURL *)url {
    self = [super initWithBaseURL:url];
    if (!self) {
        return nil;
    }
    self.responseSerializer = [AFJSONResponseSerializer serializer];
    self.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"application/json", @"text/plain", @"text/javascript", @"text/json", @"text/html", nil];
    
    [self.requestSerializer setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [self.requestSerializer setValue:url.absoluteString forHTTPHeaderField:@"Referer"];
    
    self.securityPolicy.allowInvalidCertificates = YES;
    
    return self;
}

- (void)requestJsonDataWithPath:(NSString *)aPath
                     withParams:(NSDictionary*)params
                 withMethodType:(NetworkMethod)method
                       andBlock:(void (^)(id data, NSError *error))block{
    [self requestJsonDataWithPath:aPath withParams:params withMethodType:method autoShowError:YES andBlock:block];
}

- (void)requestJsonDataWithPath:(NSString *)aPath
                     withParams:(NSDictionary*)params
                 withMethodType:(NetworkMethod)method
                  autoShowError:(BOOL)autoShowError
                       andBlock:(void (^)(id data, NSError *error))block{
    if (!aPath || aPath.length <= 0) {
        return;
    }
    //log请求数据
    DebugLog(@"\n===========request===========\n%@\n%@:\n%@", kNetworkMethodName[method], aPath, params);
    aPath = [aPath stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
//    发起请求
    switch (method) {
        case Get:{
            //所有 Get 请求，增加缓存机制
            NSMutableString *localPath = [aPath mutableCopy];
            if (params) {
                [localPath appendString:params.description];
            }
            [self GET:aPath parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
                DebugLog(@"\n===========response===========\n%@:\n%@", aPath, responseObject);
                id error = [self handleResponse:responseObject autoShowError:autoShowError];
                if (error) {
                    block(nil, error);
                }else{
                    if ([responseObject isKindOfClass:[NSDictionary class]]) {
                        //判断数据是否符合预期，给出提示
                        if ([responseObject[@"data"] isKindOfClass:[NSDictionary class]]) {
                            if (responseObject[@"data"][@"too_many_files"]) {
                                if (autoShowError) {
                                    [NSObject showHudTipStr:@"文件太多，不能正常显示"];
                                }
                            }
                        }
                        [NSObject saveResponseData:responseObject toPath:localPath];
                    }
                    block(responseObject, nil);
                }
            } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                DebugLog(@"\n===========response===========\n%@:\n%@", aPath, error);
                !autoShowError || [NSObject showError:error];
                if ([Login isLogin]) {
                    id responseObject = [NSObject loadResponseWithPath:localPath];
                    block(responseObject, error);
                }
            }];
            break;}
        case Post:{
            [self POST:aPath parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
                DebugLog(@"\n===========response===========\n%@:\n%@", aPath, responseObject);
                id error = [self handleResponse:responseObject autoShowError:autoShowError];
                if (error) {
                    block(nil, error);
                }else{
                    block(responseObject, nil);
                }
            } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                DebugLog(@"\n===========response===========\n%@:\n%@", aPath, error);
                !autoShowError || [NSObject showError:error];
                block(nil, error);
            }];
            break;}
        case Post_Mulit:{
            [self POST:aPath parameters:params constructingBodyWithBlock:^(id<AFMultipartFormData> formData)
            {
                NSMutableData *data = [[NSMutableData alloc] init];
                NSKeyedArchiver *archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:data];
                [archiver encodeObject:params[@"answers"] forKey:@"answers"];
                [archiver finishEncoding];
                
                [formData appendPartWithFormData:data name:@"answers"];
            } success:^(AFHTTPRequestOperation *operation, id responseObject) {
                DebugLog(@"\n===========response===========\n%@:\n%@", aPath, responseObject);
//                id error = [self handleResponse:responseObject autoShowError:autoShowError];
//                if (error)
//                {
//                    block(nil, error);
//                }else{
//                    block(responseObject, nil);
//                }
                block(responseObject, nil);
            } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                DebugLog(@"\n===========response===========\n%@:\n%@", aPath, error);
                !autoShowError || [NSObject showError:error];
                block(nil, error);
            }];
            
            break;}
        case Put:{
            [self PUT:aPath parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
                DebugLog(@"\n===========response===========\n%@:\n%@", aPath, responseObject);
                id error = [self handleResponse:responseObject autoShowError:autoShowError];
                if (error) {
                    block(nil, error);
                }else{
                    block(responseObject, nil);
                }
            } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                DebugLog(@"\n===========response===========\n%@:\n%@", aPath, error);
                !autoShowError || [NSObject showError:error];
                block(nil, error);
            }];
            break;}
        case Delete:{
            [self DELETE:aPath parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
                DebugLog(@"\n===========response===========\n%@:\n%@", aPath, responseObject);
                id error = [self handleResponse:responseObject autoShowError:autoShowError];
                if (error) {
                    block(nil, error);
                }else{
                    block(responseObject, nil);
                }
            } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                DebugLog(@"\n===========response===========\n%@:\n%@", aPath, error);
                !autoShowError || [NSObject showError:error];
                block(nil, error);
            }];}
        default:
            break;
    }
    
}

-(void)requestJsonDataWithPath:(NSString *)aPath file:(NSDictionary *)file withParams:(NSDictionary *)params withMethodType:(NetworkMethod)method andBlock:(void (^)(id, NSError *))block{
    //log请求数据
    DebugLog(@"\n===========request===========\n%@:\n%@", aPath, params);
    aPath = [aPath stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    // Data
    NSData *data;
    NSString *name, *fileName;
    
    if (file) {
        UIImage *image = file[@"image"];
        
        // 缩小到最大 800x800
//        image = [image scaledToMaxSize:CGSizeMake(500, 500)];
        
        // 压缩
        data = UIImageJPEGRepresentation(image, 1.0);
        if ((float)data.length/1024 > 1000) {
            data = UIImageJPEGRepresentation(image, 1024*1000.0/(float)data.length);
        }
        
        name = file[@"name"];
        fileName = file[@"fileName"];
    }
    
    switch (method) {
        case Post:{
            
            AFHTTPRequestOperation *operation = [self POST:aPath parameters:params constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
                if (file) {
                    [formData appendPartWithFileData:data name:name fileName:fileName mimeType:@"image/jpeg"];
                }
            } success:^(AFHTTPRequestOperation *operation, id responseObject) {
                DebugLog(@"\n===========response===========\n%@:\n%@", aPath, responseObject);
                id error = [self handleResponse:responseObject];
                if (error) {
                    block(nil, error);
                }else{
                    block(responseObject, nil);
                }

            } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                DebugLog(@"\n===========response===========\n%@:\n%@", aPath, error);
                [NSObject showError:error];
                block(nil, error);
            }];
            [operation start];
            
            break;
        }
        default:
            break;
    }
}

- (void)reportIllegalContentWithType:(IllegalContentType)type
                          withParams:(NSDictionary*)params{
    NSString *aPath;
    switch (type) {
        case IllegalContentTypeTweet:
            aPath = @"/api/inform/tweet";
            break;
        case IllegalContentTypeTopic:
            aPath = @"/api/inform/topic";
            break;
        case IllegalContentTypeProject:
            aPath = @"/api/inform/project";
            break;
        case IllegalContentTypeWebsite:
            aPath = @"/api/inform/website";
            break;
        default:
            aPath = @"/api/inform/tweet";
            break;
    }
    DebugLog(@"\n===========request===========\n%@:\n%@", aPath, params);
    [self POST:aPath parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        DebugLog(@"\n===========response===========\n%@:\n%@", aPath, responseObject);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        DebugLog(@"\n===========response===========\n%@:\n%@", aPath, error);
    }];
}

- (void)uploadImage:(UIImage *)image path:(NSString *)path name:(NSString *)name
       successBlock:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success
       failureBlock:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure
      progerssBlock:(void (^)(CGFloat progressValue))progress{

    NSData *data = UIImageJPEGRepresentation(image, 1.0);
    if ((float)data.length/1024 > 1000) {
        data = UIImageJPEGRepresentation(image, 1024*1000.0/(float)data.length);
    }
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = @"yyyyMMddHHmmss";
    NSString *str = [formatter stringFromDate:[NSDate date]];
    NSString *fileName = [NSString stringWithFormat:@"%@_%@.jpg", [Login curLoginUser].global_key, str];
    DebugLog(@"\nuploadImageSize\n%@ : %.0f", fileName, (float)data.length/1024);

    AFHTTPRequestOperation *operation = [self POST:path parameters:nil constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
        [formData appendPartWithFileData:data name:name fileName:fileName mimeType:@"image/jpeg"];
    } success:^(AFHTTPRequestOperation *operation, id responseObject) {
        DebugLog(@"Success: %@ ***** %@", operation.responseString, responseObject);
        id error = [self handleResponse:responseObject];
        if (error && failure) {
            failure(operation, error);
        }else{
            success(operation, responseObject);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        DebugLog(@"Error: %@ ***** %@", operation.responseString, error);
        if (failure) {
            failure(operation, error);
        }
    }];
    
    [operation setUploadProgressBlock:^(NSUInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite) {
        CGFloat progressValue = (float)totalBytesWritten/(float)totalBytesExpectedToWrite;
        if (progress) {
            progress(progressValue);
        }
    }];
    [operation start];
}

- (void)uploadVoice:(NSString *)file
           withPath:(NSString *)path
         withParams:(NSDictionary*)params
           andBlock:(void (^)(id data, NSError *error))block {
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:file]) {
        return;
    }
    
    NSData *data = [NSData dataWithContentsOfFile:file];
    NSString *fileName = [file lastPathComponent];

    DebugLog(@"\nuploadVoiceSize\n%@ : %.0f", fileName, (float)data.length/1024);
    
    AFHTTPRequestOperation *operation = [self POST:path parameters:params constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
        [formData appendPartWithFileData:data name:@"file" fileName:fileName mimeType:@"audio/amr"];
    } success:^(AFHTTPRequestOperation *operation, id responseObject) {
        DebugLog(@"\n===========response===========\n%@:\n%@", path, responseObject);
        id error = [self handleResponse:responseObject autoShowError:YES];
        if (error) {
            block(nil, error);
        }else{
            block(responseObject, nil);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        DebugLog(@"\n===========response===========\n%@:\n%@", path, error);
        [NSObject showError:error];
        block(nil, error);
    }];
    
    [operation start];
}
- (void)downloadFileWithOption:(NSDictionary *)paramDic
                 withInferface:(NSString*)requestURL
                     savedPath:(NSString*)savedPath
               downloadSuccess:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success
               downloadFailure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure
                      progress:(void (^)(float progress))progress

{
    
    //沙盒路径    //NSString *savedPath = [NSHomeDirectory() stringByAppendingString:@"/Documents/xxx.zip"];
    AFHTTPRequestSerializer *serializer = [AFHTTPRequestSerializer serializer];
    NSMutableURLRequest *request =[serializer requestWithMethod:@"GET" URLString:requestURL parameters:paramDic error:nil];
    
    //以下是手动创建request方法 AFQueryStringFromParametersWithEncoding有时候会保存
    //    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:requestURL]];
    //   NSMutableURLRequest *request =[[[AFHTTPRequestOperationManager manager]requestSerializer]requestWithMethod:@"POST" URLString:requestURL parameters:paramaterDic error:nil];
    //
    //    NSString *charset = (__bridge NSString *)CFStringConvertEncodingToIANACharSetName(CFStringConvertNSStringEncodingToEncoding(NSUTF8StringEncoding));
    //
    //    [request setValue:[NSString stringWithFormat:@"application/x-www-form-urlencoded; charset=%@", charset] forHTTPHeaderField:@"Content-Type"];
    //    [request setHTTPMethod:@"POST"];
    //
    //    [request setHTTPBody:[AFQueryStringFromParametersWithEncoding(paramaterDic, NSASCIIStringEncoding) dataUsingEncoding:NSUTF8StringEncoding]];
    
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc]initWithRequest:request];
    [operation setOutputStream:[NSOutputStream outputStreamToFileAtPath:savedPath append:NO]];
    [operation setDownloadProgressBlock:^(NSUInteger bytesRead, long long totalBytesRead, long long totalBytesExpectedToRead) {
        float p = (float)totalBytesRead / totalBytesExpectedToRead;
        progress(p);
        DebugLog(@"download：%f", (float)totalBytesRead / totalBytesExpectedToRead);
        
    }];
    
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        success(operation,responseObject);
        DebugLog(@"下载成功");
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        success(operation,error);
        
        DebugLog(@"下载失败");
        
    }];
    
    [operation start];
    
}
@end
