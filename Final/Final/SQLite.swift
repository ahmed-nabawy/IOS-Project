//
//  SQLite.swift
//  Final
//
//  Created by iOS Training on 3/17/20.
//  Copyright © 2020 JETS. All rights reserved.
//

import Foundation
//import SQLite

class SQLite: NSObject {
    
    static let instance = SQLite()
    var sqliteDB: COpaquePointer = nil
    var path: String!
    internal let trans = unsafeBitCast(-1, sqlite3_destructor_type.self)
    
    override init() {
        var dirPaths = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)
        let docsDir = dirPaths[0];
        path = docsDir + "final.db"
        if sqlite3_open(path, &sqliteDB) == SQLITE_OK {
            let create_table =
            "CREATE TABLE IF NOT EXISTS MOVIES (ID INTEGER PRIMARY KEY , TITLE TEXT, IMAGE TEXT, REL_YEAR TEXT, RATE DOUBLE, DESC TEXT, fav INTEGER)"
            if sqlite3_exec(sqliteDB, create_table, nil, nil, nil) != SQLITE_OK {
                print("failed to create table")
            }
            
            sqlite3_close(sqliteDB)
        }
        else {
            print("failed to create database")
        }
        
    }
    
    func insert(movie: Movie) {
        var statement: COpaquePointer = nil
        if sqlite3_open(path, &sqliteDB) == SQLITE_OK {
            let insertMovie = "INSERT INTO MOVIES (id, title, image, rel_year, rate, desc, fav) VALUES (?, ?, ?, ?, ?, ?, ?)"
//
//            sqlite3_bind_text(statement, 6, String(false), -1, trans)
            if sqlite3_prepare_v2(sqliteDB, insertMovie, -1, &statement, nil) == SQLITE_OK {
                sqlite3_bind_int(statement, 1, Int32(movie.id))
                sqlite3_bind_text(statement, 2, movie.title, -1, trans)
                sqlite3_bind_text(statement, 3, movie.image, -1, trans)
                sqlite3_bind_text(statement, 4, movie.relYear, -1, trans)
                sqlite3_bind_double(statement, 5, movie.rating)
                sqlite3_bind_text(statement, 6, movie.desc, -1, trans)
                sqlite3_bind_int(statement, 7, 0)
                if (sqlite3_step(statement) == SQLITE_DONE) {
                    print("Contact added")
                    sqlite3_close(sqliteDB);
                }
                else {
                    //print("Failed to add contact")
                    sqlite3_finalize(statement)
                    sqlite3_close(sqliteDB)
                }
            }
            else {
                print(String(CString: sqlite3_errmsg(sqliteDB), encoding: NSStringEncoding()))
            }
        }
    }
    
    func update(id: Int) {
        if sqlite3_open(path, &sqliteDB) == SQLITE_OK {
            var temp: Int32!
            var statement: COpaquePointer = nil
            if sqlite3_prepare_v2(sqliteDB, "select fav from movies where id = \(id)", -1, &statement, nil) == SQLITE_OK {
                if sqlite3_step(statement) == SQLITE_ROW {
                    temp = sqlite3_column_int(statement, 0)
                }
            }
            sqlite3_finalize(statement)
            if sqlite3_prepare_v2(sqliteDB, "update movies set fav = ? where id = \(id)", -1, &statement, nil) == SQLITE_OK {
                if temp == 0 {
                    if sqlite3_bind_int(statement, 1, 1) == SQLITE_OK {
                        print("ok")
                    }
                }
                else {
                    sqlite3_bind_int(statement, 1, 0)
                    print("else")
                }
                sqlite3_step(statement)
            }
            else {
                print(String(CString: sqlite3_errmsg(sqliteDB), encoding: NSStringEncoding()))
            }
            sqlite3_finalize(statement)
            sqlite3_close(sqliteDB);
        }
    }
    
    func getAll() -> [Movie] {
        var movies: [Movie] = []
        if sqlite3_open(path, &sqliteDB) == SQLITE_OK {
            var statement: COpaquePointer = nil
            if sqlite3_prepare_v2(sqliteDB, "select * from movies", -1, &statement, nil) == SQLITE_OK {
                while sqlite3_step(statement) == SQLITE_ROW {
                    movies.append(Movie(title: String.fromCString(UnsafePointer<CChar>(sqlite3_column_text(statement, 1)))!, image: String.fromCString(UnsafePointer<CChar>(sqlite3_column_text(statement, 2)))!, relYear: String.fromCString(UnsafePointer<CChar>(sqlite3_column_text(statement, 3)))!, rate: sqlite3_column_double(statement, 4), desc: String.fromCString(UnsafePointer<CChar>(sqlite3_column_text(statement, 5)))!, id: Int(sqlite3_column_int(statement, 0))))
                }
            }
            sqlite3_finalize(statement)
            sqlite3_close(sqliteDB);
        }
        
        return movies
    }
    
    func getFavorites() -> [Movie] {
        var movies: [Movie] = []
        if sqlite3_open(path, &sqliteDB) == SQLITE_OK {
            var statement: COpaquePointer = nil
            if sqlite3_prepare_v2(sqliteDB, "select * from movies where FAV = 1", -1, &statement, nil) == SQLITE_OK {
                while sqlite3_step(statement) == SQLITE_ROW {
                    movies.append(Movie(title: String.fromCString(UnsafePointer<CChar>(sqlite3_column_text(statement, 1)))!, image: String.fromCString(UnsafePointer<CChar>(sqlite3_column_text(statement, 2)))!, relYear: String.fromCString(UnsafePointer<CChar>(sqlite3_column_text(statement, 3)))!, rate: sqlite3_column_double(statement, 4), desc: String.fromCString(UnsafePointer<CChar>(sqlite3_column_text(statement, 5)))!, id: Int(sqlite3_column_int(statement, 0))))
                }
            }
            sqlite3_finalize(statement)
            sqlite3_close(sqliteDB);
        }
        
        return movies
    }
}