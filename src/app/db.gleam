import sqlight

pub fn migrate_schema(db: sqlight.Connection) -> Result(Nil, sqlight.Error) {
  sqlight.exec(
    "CREATE TABLE IF NOT EXISTS comments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT,
        by TEXT,
        content TEXT
    )",
    db,
  )
}
