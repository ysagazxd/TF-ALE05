import requests
from requests.adapters import HTTPAdapter
from urllib3.util.retry import Retry

class HttpCheck:
    def __init__(self, config):
        self.url = config['url']
        self.timeout = int(str(config.get('timeout', '10s')).replace('s', ''))
        self.expected_status = config.get('expected_status', 200)
        self.expected_body = config.get('expected_body', '')
        self.headers = config.get('headers', {})
        self.session = requests.Session()
        retry = Retry(total=1, backoff_factor=0.5, status_forcelist=[500, 502, 503])
        self.session.mount('http://', HTTPAdapter(max_retries=retry))

    def run(self):
        try:
            r = self.session.get(self.url, headers=self.headers, timeout=self.timeout)
            ok = r.status_code == self.expected_status
            if self.expected_body:
                ok = ok and self.expected_body in r.text
            return {'status': 'healthy' if ok else 'critical', 'http_status': r.status_code}
        except requests.exceptions.Timeout:
            return {'status': 'critical', 'error': 'timeout'}
        except requests.exceptions.ConnectionError as e:
            return {'status': 'critical', 'error': f'connection_error: {str(e)[:80]}'}
        except requests.exceptions.RequestException as e:
            return {'status': 'critical', 'error': str(e)[:80]}
