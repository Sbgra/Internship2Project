import sqlite3
from database import init_db

print("Running init_db()...")
init_db()
print("init_db() completed.")

conn = sqlite3.connect('articles.db')
cur = conn.cursor()

print("Articles columns:")
cur.execute("PRAGMA table_info(articles)")
for row in cur.fetchall():
    print(row)

print("Users columns:")
cur.execute("PRAGMA table_info(users)")
for row in cur.fetchall():
    print(row)

conn.close()
