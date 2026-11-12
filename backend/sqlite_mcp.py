import sqlite3
from mcp.server.mcpserver import MCPServer

DB_PATH = r'D:\football-tactics-app\tactics_analytics.db'
mcp = MCPServer('tactics-db')

@mcp.tool()
def list_tables() -> list[str]:
    with sqlite3.connect(DB_PATH) as conn:
        return [r[0] for r in conn.execute("SELECT name FROM sqlite_master WHERE type='table';").fetchall()]

@mcp.tool()
def query_sql(sql: str) -> list[dict]:
    with sqlite3.connect(DB_PATH) as conn:
        conn.row_factory = sqlite3.Row
        return [dict(r) for r in conn.execute(sql).fetchall()]

@mcp.tool()
def execute_sql(sql: str) -> str:
    with sqlite3.connect(DB_PATH) as conn:
        cur = conn.execute(sql)
        conn.commit()
        return f'Rows affected: {cur.rowcount}'

if __name__ == '__main__':
    mcp.run()
