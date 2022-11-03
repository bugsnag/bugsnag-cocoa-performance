//
//  SQLiteDatastoreTests.mm
//  BugsnagPerformance
//
//  Created by Nick Dowell on 14/10/2022.
//

#import <XCTest/XCTest.h>

#import <sqlite3.h>
#import <vector>

#define CHECK_EQUALS(expr, eres) ({ \
    int result = (expr); \
    if (result != eres) { \
        NSLog(@"%s in " #expr, sqlite3_errstr(result)); \
    } \
})

class SQLiteStatement {
public:
    SQLiteStatement() {}
    
    SQLiteStatement(SQLiteStatement &) = delete;
    
    void operator=(sqlite3_stmt *statement) {
        statement_ = statement;
    }
    
    void exec() {
        CHECK_EQUALS(sqlite3_step(statement_), SQLITE_DONE);
        CHECK_EQUALS(sqlite3_clear_bindings(statement_), SQLITE_OK);
        CHECK_EQUALS(sqlite3_reset(statement_), SQLITE_OK);
    }
    
    void bindInt(int idx, int value) {
        CHECK_EQUALS(sqlite3_bind_int(statement_, idx, value), SQLITE_OK);
    }
    
    void bindBlob(int idx, NSData *data, bool transient = false) {
        auto destructor = transient ? SQLITE_TRANSIENT : SQLITE_STATIC;
        CHECK_EQUALS(sqlite3_bind_blob(statement_, idx, data.bytes, (int)data.length, destructor), SQLITE_OK);
    }
    
    bool step() {
        return sqlite3_step(statement_) == SQLITE_ROW;
    }
    
    int getInt(int idx) {
        return sqlite3_column_int(statement_, idx);
    }
    
    NSData *getBlob(int idx) {
        const void *blob = sqlite3_column_blob(statement_, idx);
        int length = sqlite3_column_bytes(statement_, idx);
        return blob && length ? [NSData dataWithBytes:blob length:(NSUInteger)length] : nil;
    }
    
    void reset() {
        CHECK_EQUALS(sqlite3_reset(statement_), SQLITE_OK);
    }
    
private:
    sqlite3_stmt *statement_{nullptr};
};

class SQLiteConnection {
public:
    SQLiteConnection() {}
    
    SQLiteConnection(SQLiteConnection &) = delete;
    
    ~SQLiteConnection() {
        if (db_) {
            std::for_each(std::begin(statements_), std::end(statements_), sqlite3_finalize);
            sqlite3_close(db_);
        }
    }
    
    void open(const char *path) {
        if (sqlite3_open(path, &db_) != SQLITE_OK) {
            sqlite3_close(db_);
            db_ = nullptr;
        }
    }
    
    int exec(const char *sql) {
        if (!db_) return SQLITE_MISUSE;
        return sqlite3_exec(db_, sql, NULL, NULL, NULL);
    }
    
    sqlite3_stmt * prepare(const char *sql) {
        if (!db_) return nullptr;
        sqlite3_stmt *statement = nullptr;
        sqlite3_prepare_v2(db_, sql, -1, &statement, NULL);
        if (statement) {
            statements_.push_back(statement);
        } else {
            NSLog(@"Error preparing statement: \"%s\"", sql);
        }
        return statement;
    }
    
    void finalize(sqlite3_stmt *statement) {
        std::remove(std::begin(statements_), std::end(statements_), statement);
        sqlite3_finalize(statement);
    }
    
private:
    sqlite3 *db_{nullptr};
    std::vector<sqlite3_stmt *> statements_;
};

class SQLiteDatastore {
public:
    void start(const char *path) {
        connection_.open(path);
        
        connection_.exec("PRAGMA journal_mode=WAL");
        
        connection_.exec("CREATE TABLE IF NOT EXISTS TraceRequests ("
                         " id INTEGER UNIQUE PRIMARY KEY AUTOINCREMENT,"
                         " data BLOB"
                         ")");
        
        insertTrace_ =
        connection_.prepare("INSERT INTO TraceRequests (data) "
                            "VALUES (?)");
        
        selectTrace_ =
        connection_.prepare("SELECT id, data FROM TraceRequests "
                            "ORDER BY id ASC "
                            "LIMIT 1");
        
        deleteTrace_ =
        connection_.prepare("DELETE FROM TraceRequests "
                            "WHERE id = ?");
    }
    
    void insertTraceRequest(NSData *data) {
        insertTrace_.bindBlob(1, data);
        insertTrace_.exec();
    }
    
    std::pair<int, NSData *> getOldestTraceRquest() {
        selectTrace_.step();
        std::pair<int, NSData *> result {
            selectTrace_.getInt(0),
            selectTrace_.getBlob(1)
        };
        selectTrace_.reset();
        return result;
    }
    
    void deleteTraceRequest(int id) {
        deleteTrace_.bindInt(1, id);
        deleteTrace_.exec();
    }
    
private:
    SQLiteConnection connection_;
    SQLiteStatement insertTrace_;
    SQLiteStatement selectTrace_;
    SQLiteStatement deleteTrace_;
};

@interface SQLiteDatastoreTests : XCTestCase

@end

@implementation SQLiteDatastoreTests

- (void)testTraceRequest {
    SQLiteDatastore store;
    store.start("/tmp/test.sqlite");
    store.insertTraceRequest([NSJSONSerialization dataWithJSONObject:@{@"hello": @"world!"} options:0 error:nil]);
    auto request = store.getOldestTraceRquest();
    XCTAssertNotNil(request.second);
    store.deleteTraceRequest(request.first);
}

@end
