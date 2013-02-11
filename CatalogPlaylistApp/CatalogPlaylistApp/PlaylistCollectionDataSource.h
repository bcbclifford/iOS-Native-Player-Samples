//
//  PlaylistCollectionDataSource.h
//  CatalogPlaylistApp
//
//  Created by Tom Abbott on 2/7/13.
//  Copyright (c) 2013 brightcove. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BCPlaylist.h"
#import "BCCatalog.h"
#import "BCVideo.h"
#import "BCError.h"

@interface PlaylistCollectionDataSource : NSObject <UICollectionViewDataSource>

@property (strong, nonatomic) BCCatalog *catalog;
@property (strong, nonatomic) BCPlaylist *playlist;

-(id)initAndLoadPlaylist;
-(NSString *)makeReadable:(NSNumber *)number;
@end
