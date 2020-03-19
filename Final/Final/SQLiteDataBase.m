//
//  SQLiteDataBase.m
//  Friends
//
//  Created by JETS on 2/4/20.
//  Copyright (c) 2020 JETS. All rights reserved.
//

#import "SQLiteDataBase.h"

@implementation SQLiteDataBase

@synthesize databasePath = _databasePath;
@synthesize contactDB= _contactDB;

-(void)insert:(JETSFriend *)f{
    sqlite3_stmt *statement;
    const char *dbpath = [_databasePath UTF8String];
    
    if (sqlite3_open(dbpath, &_contactDB) == SQLITE_OK)
    {
        NSString *ageStr = [NSString stringWithFormat:@"%d", f.age];
        NSString *insertSQL = [NSString stringWithFormat:
                               @"INSERT INTO FRIENDS (name, phone, age, email, address, imagePath, long, lat) VALUES (\"%@\", \"%@\", \"%@\", \"%@\", \"%@\", \"%@\", \"%@\", \"%@\")",
                               f.name, f.phone, ageStr, f.email, f.address, f.image, f.lng, f.lat];
        
        const char *insert_stmt = [insertSQL UTF8String];
        sqlite3_prepare_v2(_contactDB, insert_stmt, -1, &statement, NULL);
        if (sqlite3_step(statement) == SQLITE_DONE)
        {
            printf("Contact added");
            
        }
        else
            printf("Failed to add contact");
        sqlite3_finalize(statement);
        sqlite3_close(_contactDB);
    }
}

-(NSMutableArray*)select{
    NSMutableArray *marr = [NSMutableArray new];
    
    const char *dbpath = [_databasePath UTF8String];
    sqlite3_stmt *statement;
    
    if (sqlite3_open(dbpath, &_contactDB) == SQLITE_OK)
    {
        NSString *querySQL = [NSString stringWithFormat:@"SELECT * FROM friends"];
        
        const char *query_stmt = [querySQL UTF8String];
        
        if (sqlite3_prepare_v2(_contactDB, query_stmt, -1, &statement, NULL) == SQLITE_OK)
        {
            while (sqlite3_step(statement) == SQLITE_ROW)
            {
                JETSFriend *f = [JETSFriend new];
                NSString *nameField = [[NSString alloc] initWithUTF8String:(const char *) sqlite3_column_text(statement, 1)];
                f.name = nameField;
                //printf("%s", [f.name UTF8String]);
                NSString *phoneField = [[NSString alloc] initWithUTF8String:(const char *)sqlite3_column_text(statement, 2)];
                f.phone = phoneField;
                NSString *ageString = [[NSString alloc] initWithUTF8String:(const char *)sqlite3_column_text(statement, 3)];
                f.age = [ageString intValue];
                NSString *emailField = [[NSString alloc] initWithUTF8String:(const char *)sqlite3_column_text(statement, 4)];
                f.email = emailField;
                NSString *addressField = [[NSString alloc] initWithUTF8String:(const char *)sqlite3_column_text(statement, 5)];
                f.address = addressField;
                NSString *imageField = [[NSString alloc] initWithUTF8String:(const char *)sqlite3_column_text(statement, 6)];
                f.image = imageField;
                NSString *lngField = [[NSString alloc] initWithUTF8String:(const char *)sqlite3_column_text(statement, 7)];
                f.lng = lngField;
                NSString *latField = [[NSString alloc] initWithUTF8String:(const char *)sqlite3_column_text(statement, 8)];
                f.lat = latField;
                [marr addObject:f];
            }
            if (sqlite3_step(statement) != SQLITE_ROW)
                printf("Match not found");
            sqlite3_finalize(statement);
        }
        sqlite3_close(_contactDB);
    }
    return marr;
}

-(void)delete:(JETSFriend *)f{
    sqlite3_stmt *statement;
    const char *dbpath = [_databasePath UTF8String];
    
    if (sqlite3_open(dbpath, &_contactDB) == SQLITE_OK)
    {
        NSString *ageStr = [NSString stringWithFormat:@"%d", f.age];
        NSString *deleteSQL = [NSString stringWithFormat:
                               @"delete from FRIENDS where name = \"%@\" and phone = \"%@\" and age = \"%@\" and email = \"%@\" and address = \"%@\"",
                               f.name, f.phone, ageStr, f.email, f.address];
        
        const char *delete_stmt = [deleteSQL UTF8String];
        sqlite3_prepare_v2(_contactDB, delete_stmt, -1, &statement, NULL);
        if (sqlite3_step(statement) == SQLITE_DONE)
        {
            printf("Contact deleted");
            
        }
        else
            printf("Failed to delete contact");
        sqlite3_finalize(statement);
        sqlite3_close(_contactDB);
    }
}

-(instancetype)init{
    self = [super init];
    NSString *docsDir;
    NSArray *dirPaths;
    dirPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    docsDir = dirPaths[0];
    _databasePath = [[NSString alloc]initWithString:[docsDir stringByAppendingPathComponent:@"friends.db"]];
    const char *dbpath = [_databasePath UTF8String];
    
    if (sqlite3_open(dbpath, &_contactDB) == SQLITE_OK)
    {
        char *errMsg;
        const char *sql_stmt =
        "CREATE TABLE IF NOT EXISTS FRIENDS (ID INTEGER PRIMARY KEY AUTOINCREMENT, NAME TEXT, PHONE TEXT, AGE INTEGER, EMAIL TEXT, ADDRESS TEXT, imagePath TEXT, long TEXT, LAT TEXT)";
        
        if (sqlite3_exec(_contactDB, sql_stmt, NULL, NULL, &errMsg) != SQLITE_OK)
        {
            printf("Failed to create table");
        }
        sqlite3_close(_contactDB);
    }
    else
        printf("Failed to open/create database");

    return self;
}

@end
