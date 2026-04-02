import mysql.connector, os

class DbCheck:
    def __init__(self, config):
        self.host = os.getenv('DB_HOST', 'db')
        self.port = int(os.getenv('DB_PORT', 3306))
        self.user = os.getenv('DB_USER', 'appuser')
        self.password = os.getenv('DB_PASS', 'apppass')
        self.database = os.getenv('DB_NAME', 'monitoring')
        self.query = config.get('query', 'SELECT 1')
        self.timeout = int(str(config.get('timeout', '30s')).replace('s', ''))

    def run(self):
        conn = None
        try:
            conn = mysql.connector.connect(
                host=self.host, port=self.port, user=self.user,
                password=self.password, database=self.database,
                connection_timeout=self.timeout
            )
            cursor = conn.cursor()
            cursor.execute(self.query)
            cursor.fetchall()
            cursor.execute("SHOW STATUS LIKE 'Threads_connected'")
            row = cursor.fetchone()
            connections = int(row[1]) if row else 0
            return {'status': 'healthy', 'connections': f'{connections}/100'}
        except mysql.connector.Error as e:
            return {'status': 'critical', 'error': str(e)}
        finally:
            if conn and conn.is_connected():
                conn.close()
