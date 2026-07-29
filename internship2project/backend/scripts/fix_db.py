import os
import sqlite3
import sys

# Add backend to path so we can import core.database
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from core.database import init_db

print("Running init_db()...")
init_db()
print("init_db() completed.")

db_path = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), 'data', 'articles.db')
if not os.path.exists(db_path):
    print("No database file found at", db_path)
    sys.exit(0)

conn = sqlite3.connect(db_path)
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
