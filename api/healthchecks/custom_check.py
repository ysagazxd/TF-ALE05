import socket, redis as redis_lib, os

class TcpCheck:
    def __init__(self, config):
        self.host = config.get('host', 'localhost')
        self.port = int(config.get('port', 80))
        self.timeout = int(str(config.get('timeout', '5s')).replace('s', ''))

    def run(self):
        try:
            sock = socket.create_connection((self.host, self.port), timeout=self.timeout)
            sock.close()
            # Se for Redis, testa PING para métricas extras
            if self.port == 6379:
                return self._redis_check()
            return {'status': 'healthy'}
        except Exception as e:
            return {'status': 'critical', 'error': str(e)}

    def _redis_check(self):
        try:
            r = redis_lib.Redis(host=self.host, port=self.port,
                                socket_timeout=self.timeout, decode_responses=True)
            r.ping()
            info = r.info()
            return {
                'status': 'healthy',
                'used_memory': info.get('used_memory_human', '--'),
                'connected_clients': info.get('connected_clients', 0)
            }
        except Exception as e:
            return {'status': 'critical', 'error': str(e)}
