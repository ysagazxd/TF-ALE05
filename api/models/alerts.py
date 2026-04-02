from collections import deque
from datetime import datetime, timezone, timedelta
import logging, requests, os

logger = logging.getLogger(__name__)

COOLDOWN_SECONDS = 60  # mesmo alerta só reenvia após 60s

class AlertsModel:
    def __init__(self):
        self._alerts = deque(maxlen=100)
        self._last_alert = {}  # {(service, severity): datetime}

    def add(self, service, message, severity='warning'):
        key = (service, severity)
        now = datetime.now(timezone.utc)
        last = self._last_alert.get(key)
        if last and (now - last).total_seconds() < COOLDOWN_SECONDS:
            return  # cooldown ativo, ignora duplicata
        self._last_alert[key] = now
        alert = {
            'service': service,
            'message': message,
            'severity': severity,
            'timestamp': now.isoformat()
        }
        self._alerts.appendleft(alert)
        self._send_webhook(alert)

    def _send_webhook(self, alert):
        url = os.getenv('WEBHOOK_URL', '')
        if not url:
            return
        try:
            requests.post(url, json={
                'text': f"[{alert['severity'].upper()}] {alert['service']}: {alert['message']}"
            }, timeout=3)
        except requests.exceptions.RequestException as e:
            logger.warning('Falha ao enviar webhook: %s', e)

    def resolve(self, service):
        """Remove alertas não resolvidos de um serviço que voltou a healthy."""
        self._alerts = deque(
            (a for a in self._alerts if a['service'] != service),
            maxlen=100
        )
        # limpa cooldown para permitir novo alerta se cair de novo
        self._last_alert = {k: v for k, v in self._last_alert.items() if k[0] != service}

    def get_recent(self, limit=20):
        return list(self._alerts)[:limit]
