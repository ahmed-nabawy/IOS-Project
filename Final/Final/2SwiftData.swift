//
// SwiftData.swift
//
// Copyright (c) 2015 Ryan Fowler
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.


import Foundation
import UIKit

private class SQLiteDB {
        
    static let instance = SQLiteDB()
    var sqliteDB: COpaquePointer = nil
    var dbPath = SQLiteDB.createPath()
    let queue = dispatch_queue_create("SwiftData.DatabaseQueue", DISPATCH_QUEUE_SERIAL)
    
    func open() -> Int? {
        let status = sqlite3_open(dbPath.cStringUsingEncoding(NSUTF8StringEncoding)!, &sqliteDB)
        if status != SQLITE_OK {
            print("SwiftData Error -> During: Opening Database")
            if let errMsg = String.fromCString(sqlite3_errmsg(SQLiteDB.instance.sqliteDB)) {
                    print("                -> Details: \(errMsg)")
                }
                return Int(status)
            }
            isConnected = true
            return nil
            
        }
    
        //create the database path
        class func createPath() -> String {
            
            let docsPath = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true)[0]
            let databaseStr = "SwiftData.sqlite"
            let dbPath = docsPath.stringByAppendingPathComponent(databaseStr)
            return dbPath
            
        }
        
        func executeChange(sqlStr: String, withArgs: [AnyObject]? = nil) -> Int? {
            
            var sql = sqlStr
            if let args = withArgs {
                let result = bind(args, toSQL: sql)
                if let error = result.error {
                    return error
                } else {
                    sql = result.string
                }
            }
            var pStmt: COpaquePointer = nil
            var status = sqlite3_prepare_v2(SQLiteDB.sharedInstance.sqliteDB, sql, -1, &pStmt, nil)
            if status != SQLITE_OK {
                print("SwiftData Error -> During: SQL Prepare")
                print("                -> Code: \(status) - " + SDError.errorMessageFromCode(Int(status)))
                if let errMsg = String.fromCString(sqlite3_errmsg(SQLiteDB.sharedInstance.sqliteDB)) {
                    print("                -> Details: \(errMsg)")
                }
                sqlite3_finalize(pStmt)
                return Int(status)
            }
            status = sqlite3_step(pStmt)
            if status != SQLITE_DONE && status != SQLITE_OK {
                print("SwiftData Error -> During: SQL Step")
                print("                -> Code: \(status) - " + SDError.errorMessageFromCode(Int(status)))
                if let errMsg = String.fromCString(sqlite3_errmsg(SQLiteDB.sharedInstance.sqliteDB)) {
                    print("                -> Details: \(errMsg)")
                }
                sqlite3_finalize(pStmt)
                return Int(status)
            }
            sqlite3_finalize(pStmt)
            return nil
            
        }
        
        //execute a SQLite query from a SQL String
        func executeQuery(sqlStr: String, withArgs: [AnyObject]? = nil) -> (result: [SDRow], error: Int?) {
            
            var resultSet = [SDRow]()
            var sql = sqlStr
            if let args = withArgs {
                let result = bind(args, toSQL: sql)
                if let err = result.error {
                    return (resultSet, err)
                } else {
                    sql = result.string
                }
            }
            var pStmt: COpaquePointer = nil
            var status = sqlite3_prepare_v2(SQLiteDB.sharedInstance.sqliteDB, sql, -1, &pStmt, nil)
            if status != SQLITE_OK {
                print("SwiftData Error -> During: SQL Prepare")
                print("                -> Code: \(status) - " + SDError.errorMessageFromCode(Int(status)))
                if let errMsg = String.fromCString(sqlite3_errmsg(SQLiteDB.sharedInstance.sqliteDB)) {
                    print("                -> Details: \(errMsg)")
                }
                sqlite3_finalize(pStmt)
                return (resultSet, Int(status))
            }
            var columnCount: Int32 = 0
            var next = true
            while next {
                status = sqlite3_step(pStmt)
                if status == SQLITE_ROW {
                    columnCount = sqlite3_column_count(pStmt)
                    var row = SDRow()
                    for var i: Int32 = 0; i < columnCount; ++i {
                        let columnName = String.fromCString(sqlite3_column_name(pStmt, i))!
                        if let columnType = String.fromCString(sqlite3_column_decltype(pStmt, i))?.uppercaseString {
                            if let columnValue: AnyObject = getColumnValue(pStmt, index: i, type: columnType) {
                                row[columnName] = SDColumn(obj: columnValue)
                            }
                        } else {
                            var columnType = ""
                            switch sqlite3_column_type(pStmt, i) {
                            case SQLITE_INTEGER:
                                columnType = "INTEGER"
                            case SQLITE_FLOAT:
                                columnType = "FLOAT"
                            case SQLITE_TEXT:
                                columnType = "TEXT"
                            case SQLITE3_TEXT:
                                columnType = "TEXT"
                            case SQLITE_BLOB:
                                columnType = "BLOB"
                            case SQLITE_NULL:
                                columnType = "NULL"
                            default:
                                columnType = "NULL"
                            }
                            if let columnValue: AnyObject = getColumnValue(pStmt, index: i, type: columnType) {
                                row[columnName] = SDColumn(obj: columnValue)
                            }
                        }
                    }
                    resultSet.append(row)
                } else if status == SQLITE_DONE {
                    next = false
                } else {
                    print("SwiftData Error -> During: SQL Step")
                    print("                -> Code: \(status) - " + SDError.errorMessageFromCode(Int(status)))
                    if let errMsg = String.fromCString(sqlite3_errmsg(SQLiteDB.sharedInstance.sqliteDB)) {
                        print("                -> Details: \(errMsg)")
                    }
                    sqlite3_finalize(pStmt)
                    return (resultSet, Int(status))
                }
            }
            sqlite3_finalize(pStmt)
            return (resultSet, nil)
            
        }
        
    }
    
    
    // MARK: - SDRow
    
    public struct SDRow {

        var values = [String: SDColumn]()
        public subscript(key: String) -> SDColumn? {
            get {
                return values[key]
            }
            set(newValue) {
                values[key] = newValue
            }
        }
        
    }
    
    
    // MARK: - SDColumn
    
    public struct SDColumn {
        
        var value: AnyObject
        init(obj: AnyObject) {
            value = obj
        }
        
        //return value by type

        /**
        Return the column value as a String

        - returns:  An Optional String corresponding to the apprioriate column value. Will be nil if: the column name does not exist, the value cannot be cast as a String, or the value is NULL
        */
        public func asString() -> String? {
            return value as? String
        }

        /**
        Return the column value as an Int

        - returns:  An Optional Int corresponding to the apprioriate column value. Will be nil if: the column name does not exist, the value cannot be cast as a Int, or the value is NULL
        */
        public func asInt() -> Int? {
            return value as? Int
        }

        /**
        Return the column value as a Double

        - returns:  An Optional Double corresponding to the apprioriate column value. Will be nil if: the column name does not exist, the value cannot be cast as a Double, or the value is NULL
        */
        public func asDouble() -> Double? {
            return value as? Double
        }

        /**
        Return the column value as a Bool

        - returns:  An Optional Bool corresponding to the apprioriate column value. Will be nil if: the column name does not exist, the value cannot be cast as a Bool, or the value is NULL
        */
        public func asBool() -> Bool? {
            return value as? Bool
        }

        /**
        Return the column value as NSData

        - returns:  An Optional NSData object corresponding to the apprioriate column value. Will be nil if: the column name does not exist, the value cannot be cast as NSData, or the value is NULL
        */
        public func asData() -> NSData? {
            return value as? NSData
        }

        /**
        Return the column value as an NSDate

        - returns:  An Optional NSDate corresponding to the apprioriate column value. Will be nil if: the column name does not exist, the value cannot be cast as an NSDate, or the value is NULL
        */
        public func asDate() -> NSDate? {
            return value as? NSDate
        }

        /**
        Return the column value as an AnyObject

        - returns:  An Optional AnyObject corresponding to the apprioriate column value. Will be nil if: the column name does not exist, the value cannot be cast as an AnyObject, or the value is NULL
        */
        public func asAnyObject() -> AnyObject? {
            return value
        }
        
        /**
        Return the column value path as a UIImage

        - returns:  An Optional UIImage corresponding to the path of the apprioriate column value. Will be nil if: the column name does not exist, the value of the specified path cannot be cast as a UIImage, or the value is NULL
        */
        public func asUIImage() -> UIImage? {
            
            if let path = value as? String{
                let docsPath = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true)[0]
                let imageDirPath = docsPath.stringByAppendingPathComponent("SwiftDataImages")
                let fullPath = imageDirPath.stringByAppendingPathComponent(path)
                if !NSFileManager.defaultManager().fileExistsAtPath(fullPath) {
                    print("SwiftData Error -> Invalid image ID provided")
                    return nil
                }
                if let imageAsData = NSData(contentsOfFile: fullPath) {
                    return UIImage(data: imageAsData)
                }
            }
            return nil
            
        }

    }
    
    
    // MARK: - Error Handling
    
    private struct SDError {
        
    }
    
}


// MARK: - Threading

extension SwiftData {
    
    private static func putOnThread(task: ()->Void) {
        if SQLiteDB.sharedInstance.inTransaction || SQLiteDB.sharedInstance.savepointsOpen > 0 || SQLiteDB.sharedInstance.openWithFlags {
            task()
        } else {
            dispatch_sync(SQLiteDB.sharedInstance.queue) {
                task()
            }
        }
    }
    
}


// MARK: - Escaping And Binding Functions

extension SwiftData.SQLiteDB {

    func bind(objects: [AnyObject], toSQL sql: String) -> (string: String, error: Int?) {

        var newSql = ""
        var bindIndex = 0
        var i = false
        for char in sql.characters {
            if char == "?" {
                if bindIndex > objects.count - 1 {
                    print("SwiftData Error -> During: Object Binding")
                    print("                -> Code: 201 - Not enough objects to bind provided")
                    return ("", 201)
                }
                var obj = ""
                if i {
                    if let str = objects[bindIndex] as? String {
                        obj = escapeIdentifier(str)
                    } else {
                        print("SwiftData Error -> During: Object Binding")
                        print("                -> Code: 203 - Object to bind as identifier must be a String at array location: \(bindIndex)")
                        return ("", 203)
                    }
                    newSql = newSql.substringToIndex(newSql.endIndex.predecessor())
                } else {
                    obj = escapeValue(objects[bindIndex])
                }
                newSql += obj
                ++bindIndex
            } else {
                newSql.append(char)
            }
            if char == "i" {
                i = true
            } else if i {
                i = false
            }
        }
        if bindIndex != objects.count {
            print("SwiftData Error -> During: Object Binding")
            print("                -> Code: 202 - Too many objects to bind provided")
            return ("", 202)
        }
        return (newSql, nil)
        
    }
    
    //return escaped String value of AnyObject
    func escapeValue(obj: AnyObject?) -> String {
        
        if let obj: AnyObject = obj {
            if obj is String {
                return "'\(escapeStringValue(obj as!String))'"
            }
            if obj is Double || obj is Int {
                return "\(obj)"
            }
            if obj is Bool {
                if obj as! Bool {
                    return "1"
                } else {
                    return "0"
                }
            }
            if obj is NSData {
                let str = "\(obj)"
                var newStr = ""
                for char in str.characters {
                    if char != "<" && char != ">" && char != " " {
                        newStr.append(char)
                    }
                }
                return "X'\(newStr)'"
            }
            if obj is NSDate {
                let dateFormatter = NSDateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                return "\(escapeValue(dateFormatter.stringFromDate(obj as!NSDate)))"
            }
            if obj is UIImage {
                if let imageID = SD.saveUIImage(obj as!UIImage) {
                    return "'\(escapeStringValue(imageID))'"
                }
                print("SwiftData Warning -> Cannot save image, NULL will be inserted into the database")
                return "NULL"
            }
            print("SwiftData Warning -> Object \"\(obj)\" is not a supported type and will be inserted into the database as NULL")
            return "NULL"
        } else {
            return "NULL"
        }
        
    }
    
    //return escaped String identifier
    func escapeIdentifier(obj: String) -> String {
        return "\"\(escapeStringIdentifier(obj))\""
    }

    
    //escape string
    func escapeStringValue(str: String) -> String {
        var escapedStr = ""
        for char in str.characters {
            if char == "'" {
                escapedStr += "'"
            }
            escapedStr.append(char)
        }
        return escapedStr
    }
    
    //escape string
    func escapeStringIdentifier(str: String) -> String {
        var escapedStr = ""
        for char in str.characters {
            if char == "\"" {
                escapedStr += "\""
            }
            escapedStr.append(char)
        }
        return escapedStr
    }
    
}


// MARK: - SQL Creation Functions

extension SwiftData {
    
    /**
    Column Data Types
    
    - parameter  StringVal:   A column with type String, corresponds to SQLite type "TEXT"
    - parameter  IntVal:      A column with type Int, corresponds to SQLite type "INTEGER"
    - parameter  DoubleVal:   A column with type Double, corresponds to SQLite type "DOUBLE"
    - parameter  BoolVal:     A column with type Bool, corresponds to SQLite type "BOOLEAN"
    - parameter  DataVal:     A column with type NSdata, corresponds to SQLite type "BLOB"
    - parameter  DateVal:     A column with type NSDate, corresponds to SQLite type "DATE"
    - parameter  UIImageVal:  A column with type String (the path value of saved UIImage), corresponds to SQLite type "TEXT"
    */
    public enum DataType {
        
        case StringVal
        case IntVal
        case DoubleVal
        case BoolVal
        case DataVal
        case DateVal
        case UIImageVal
        
        private func toSQL() -> String {
            
            switch self {
            case .StringVal, .UIImageVal:
                return "TEXT"
            case .IntVal:
                return "INTEGER"
            case .DoubleVal:
                return "DOUBLE"
            case .BoolVal:
                return "BOOLEAN"
            case .DataVal:
                return "BLOB"
            case .DateVal:
                return "DATE"
            }
        }
        
    }
    
    /**
    Flags for custom connection to the SQLite database
    
    - parameter  ReadOnly:         Opens the SQLite database with the flag "SQLITE_OPEN_READONLY"
    - parameter  ReadWrite:        Opens the SQLite database with the flag "SQLITE_OPEN_READWRITE"
    - parameter  ReadWriteCreate:  Opens the SQLite database with the flag "SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE"
    */
    public enum Flags {
        
        case ReadOnly
        case ReadWrite
        case ReadWriteCreate
    
        private func toSQL() -> Int32 {
            
            switch self {
            case .ReadOnly:
                return SQLITE_OPEN_READONLY
            case .ReadWrite:
                return SQLITE_OPEN_READWRITE
            case .ReadWriteCreate:
                return SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE
            }
            
        }
        
    }

}


extension SwiftData.SQLiteDB {
    
    //create a table
    func createSQLTable(table: String, withColumnsAndTypes values: [String: SwiftData.DataType]) -> Int? {

        var sqlStr = "CREATE TABLE \(table) (ID INTEGER PRIMARY KEY AUTOINCREMENT, "
        var firstRun = true
        for value in values {
            if firstRun {
                sqlStr += "\(escapeIdentifier(value.0)) \(value.1.toSQL())"
                firstRun = false
            } else {
                sqlStr += ", \(escapeIdentifier(value.0)) \(value.1.toSQL())"
            }
        }
        sqlStr += ")"
        return executeChange(sqlStr)
        
    }
    
    //delete a table
    func deleteSQLTable(table: String) -> Int? {
        let sqlStr = "DROP TABLE \(table)"
        return executeChange(sqlStr)
    }
    
    //get existing table names
    func existingTables() -> (result: [String], error: Int?) {
        let sqlStr = "SELECT name FROM sqlite_master WHERE type = 'table'"
        var tableArr = [String]()
        let results = executeQuery(sqlStr)
        if let err = results.error {
            return (tableArr, err)
        }
        for row in results.result {
            if let table = row["name"]?.asString() {
                tableArr.append(table)
            } else {
                print("SwiftData Error -> During: Finding Existing Tables")
                print("                -> Code: 403 - Error extracting table names from sqlite_master")
                return (tableArr, 403)
            }
        }
        return (tableArr, nil)
    }
    
    //create an index
    func createIndex(name: String, columns: [String], table: String, unique: Bool) -> Int? {
        
        if columns.count < 1 {
            print("SwiftData Error -> During: Creating Index")
            print("                -> Code: 401 - At least one column name must be provided")
            return 401
        }
        var sqlStr = ""
        if unique {
            sqlStr = "CREATE UNIQUE INDEX \(name) ON \(table) ("
        } else {
            sqlStr = "CREATE INDEX \(name) ON \(table) ("
        }
        var firstRun = true
        for column in columns {
            if firstRun {
                sqlStr += column
                firstRun = false
            } else {
                sqlStr += ", \(column)"
            }
        }
        sqlStr += ")"
        return executeChange(sqlStr)
        
    }
    
    //remove an index
    func removeIndex(name: String) -> Int? {
        let sqlStr = "DROP INDEX \(name)"
        return executeChange(sqlStr)
    }
    
    //obtain list of existing indexes
    func existingIndexes() -> (result: [String], error: Int?) {
        
        let sqlStr = "SELECT name FROM sqlite_master WHERE type = 'index'"
        var indexArr = [String]()
        let results = executeQuery(sqlStr)
        if let err = results.error {
            return (indexArr, err)
        }
        for res in results.result {
            if let index = res["name"]?.asString() {
                indexArr.append(index)
            } else {
                print("SwiftData Error -> During: Finding Existing Indexes")
                print("                -> Code: 402 - Error extracting index names from sqlite_master")
                print("Error finding existing indexes -> Error extracting index names from sqlite_master")
                return (indexArr, 402)
            }
        }
        return (indexArr, nil)
        
    }
    
    //obtain list of existing indexes for a specific table
    func existingIndexesForTable(table: String) -> (result: [String], error: Int?) {
        
        let sqlStr = "SELECT name FROM sqlite_master WHERE type = 'index' AND tbl_name = '\(table)'"
        var indexArr = [String]()
        let results = executeQuery(sqlStr)
        if let err = results.error {
            return (indexArr, err)
        }
        for res in results.result {
            if let index = res["name"]?.asString() {
                indexArr.append(index)
            } else {
                print("SwiftData Error -> During: Finding Existing Indexes for a Table")
                print("                -> Code: 402 - Error extracting index names from sqlite_master")
                return (indexArr, 402)
            }
        }
        return (indexArr, nil)
        
    }
    
}


// MARK: - SDError Functions

extension SwiftData.SDError {
    
    //get the error message from the error code
    private static func errorMessageFromCode(errorCode: Int) -> String {
        
        switch errorCode {
            
        //no error
            
        case -1:
            return "No error"
            
        //SQLite error codes and descriptions as per: http://www.sqlite.org/c3ref/c_abort.html
        case 0:
            return "Successful result"
        case 1:
            return "SQL error or missing database"
        case 2:
            return "Internal logic error in SQLite"
        case 3:
            return "Access permission denied"
        case 4:
            return "Callback routine requested an abort"
        case 5:
            return "The database file is locked"
        case 6:
            return "A table in the database is locked"
        case 7:
            return "A malloc() failed"
        case 8:
            return "Attempt to write a readonly database"
        case 9:
            return "Operation terminated by sqlite3_interrupt()"
        case 10:
            return "Some kind of disk I/O error occurred"
        case 11:
            return "The database disk image is malformed"
        case 12:
            return "Unknown opcode in sqlite3_file_control()"
        case 13:
            return "Insertion failed because database is full"
        case 14:
            return "Unable to open the database file"
        case 15:
            return "Database lock protocol error"
        case 16:
            return "Database is empty"
        case 17:
            return "The database schema changed"
        case 18:
            return "String or BLOB exceeds size limit"
        case 19:
            return "Abort due to constraint violation"
        case 20:
            return "Data type mismatch"
        case 21:
            return "Library used incorrectly"
        case 22:
            return "Uses OS features not supported on host"
        case 23:
            return "Authorization denied"
        case 24:
            return "Auxiliary database format error"
        case 25:
            return "2nd parameter to sqlite3_bind out of range"
        case 26:
            return "File opened that is not a database file"
        case 27:
            return "Notifications from sqlite3_log()"
        case 28:
            return "Warnings from sqlite3_log()"
        case 100:
            return "sqlite3_step() has another row ready"
        case 101:
            return "sqlite3_step() has finished executing"
            
        //custom SwiftData errors

        //->binding errors
            
        case 201:
            return "Not enough objects to bind provided"
        case 202:
            return "Too many objects to bind provided"
        case 203:
            return "Object to bind as identifier must be a String"

        //->custom connection errors

        case 301:
            return "A custom connection is already open"
        case 302:
            return "Cannot open a custom connection inside a transaction"
        case 303:
            return "Cannot open a custom connection inside a savepoint"
        case 304:
            return "A custom connection is not currently open"
        case 305:
            return "Cannot close a custom connection inside a transaction"
        case 306:
            return "Cannot close a custom connection inside a savepoint"

        //->index and table errors
        
        case 401:
            return "At least one column name must be provided"
        case 402:
            return "Error extracting index names from sqlite_master"
        case 403:
            return "Error extracting table names from sqlite_master"

        //->transaction and savepoint errors
        
        case 501:
            return "Cannot begin a transaction within a savepoint"
        case 502:
            return "Cannot begin a transaction within another transaction"

        //unknown error
            
        default:
            //what the fuck happened?!?
            return "Unknown error"
        }
        
    }
    
}

extension String
{
    func stringByAppendingPathComponent(path: String) -> String
    {
        let nsSt = self as NSString
        return nsSt.stringByAppendingPathComponent(path)
    }
}
public typealias SD = SwiftData