//
//  BCSDKMediaService.m
//  CatalogPlaylistApp
//
//  Created by Tom Abbott on 4/11/13.
//  Copyright (c) 2013 brightcove. All rights reserved.
//

#import "BCSDKMediaService.h"
#import "BCVideo.h"
#import "BCEvent.h"

@implementation BCSDKMediaService

-(BCVideo *)makeVideoWithJSON:(NSDictionary *)json
{
    //To streamline the creation of the video, we want super to create it first
    BCVideo *video = [super makeVideoWithJSON:json];
    
    //Initialize new properties based on the existing video properties
    NSMutableDictionary *properties = [[NSMutableDictionary alloc] initWithDictionary:video.properties];
    
    //This is where we can populate any other parameter for the video object, for example we can add longDescription
    if ([json objectForKey:@"longDescription"] && ![[json objectForKey:@"longDescription"] isEqual:[NSNull null]]) {
        [properties setValue:[json objectForKey:@"longDescription"] forKey:@"longDescription"];
    }
    
    BCRendition *rendition = nil;
    BCRenditionSet *renditionSet = nil;
    
    // Check if HLSURL property exists and is not null. If not, use FLVURL instead.
    // For this to work request HLSURL as a video_field and set media_type to HTTP, e.g.
    // NSDictionary *apiOptions = [[NSDictionary alloc] initWithObjectsAndKeys: @"HTTP", @"media_delivery", @"FLVFullLength,videoStillURL,name,shortDescription,referenceId,id,customFields,FLVURL,HLSURL", @"video_fields", nil];
    // catalog = [[BCSDKCatalog alloc] initWithToken:token];
    // [catalog findVideoByID:videoId options:apiOptions callBlock:^(BCError *error, BCVideo *video) { … }];
    if([json objectForKey:@"HLSURL"] && ![[json objectForKey:@"HLSURL"] isEqual:[NSNull null]]) {
        rendition = [[BCRendition alloc] initWithURL:[NSURL URLWithString:[json objectForKey:@"HLSURL"]]];
        NSLog(@"Video has transcoded HLS");
    } else {
        // if no HLS rendition is found, attempt to playback the FLVURL as a normal video.
        rendition = [[BCRendition alloc] initWithURL:[NSURL URLWithString:[json objectForKey:@"FLVURL"]]];
        NSLog(@"Video does not have transcoded HLS");
    }
    renditionSet = [[BCRenditionSet alloc] initWithRenditions:[NSArray arrayWithObject:rendition]
                                                deliveryMethod:[NSDictionary dictionary]];
    
    //Return a newly created video with the new properties
    return [[BCVideo alloc] initWithRenditionSet:renditionSet properties:properties];
}

@end
