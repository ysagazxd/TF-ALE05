from collections import defaultdict, deque
from datetime import datetime, timezone

class MetricsModel:
    def __init__(self):
        self._latest = {}
        self._history = defaultdict(lambda: deque(maxlen=24))
        self._start = {s: datetime.now(timezone.utc) for s in ['frontend', 'backend', 'database', 'redis']}

    def save(self, service, data):
        key = self._normalize(service)
        data['timestamp'] = datetime.now(timezone.utc).isoformat()
        # salva o status bruto no histórico antes de calcular uptime
        self._history[key].append({
            'response_time': data.get('response_time', 0),
            'status': data.get('status', 'unknown'),
            'timestamp': data['timestamp']
        })
        data['uptime'] = self._calc_uptime(key)
        # atualiza o uptime no registro do histórico recém inserido
        self._history[key][-1]['uptime'] = data['uptime']
        self._latest[key] = data

    def _normalize(self, name):
        mapping = {'web-frontend': 'frontend', 'api-backend': 'backend',
                   'database': 'database', 'redis-cache': 'redis'}
        return mapping.get(name, name)

    def _calc_uptime(self, service):
        history = list(self._history[service])
        if not history:
            return 100.0
        healthy = sum(1 for h in history if h.get('status') == 'healthy')
        return round((healthy / len(history)) * 100, 2)

    def get_latest(self):
        return self._latest

    def get_all(self):
        return {k: list(v) for k, v in self._history.items()}

    def get_history(self):
        return {k: list(v) for k, v in self._history.items()}
