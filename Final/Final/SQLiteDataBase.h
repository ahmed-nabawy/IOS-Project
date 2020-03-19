//
//  SQLiteDataBase.h
//  Friends
//
//  Created by JETS on 2/4/20.
//  Copyright (c) 2020 JETS. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <sqlite3.h>
#import "Movie.swift"

@interface SQLiteDataBase : NSObject

@property (strong , nonatomic) NSString *databasePath;
@property (nonatomic) sqlite3 *contactDB;

-(void)insertMovie:(Movie)m;
-(void)insertFavorite(Movie)m;
-(NSMutableArray*)selectMovie;
-(NSMutableArray*)selectFavorite;
-(void)delete:()f;

@end
