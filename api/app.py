from flask import Flask, jsonify
from flask_cors import CORS
from apscheduler.schedulers.background import BackgroundScheduler
from models.metrics import MetricsModel
from models.alerts import AlertsModel
from healthchecks.http_check import HttpCheck
from healthchecks.db_check import DbCheck
from healthchecks.custom_check import TcpCheck
import yaml, os, time, threading

app = Flask(__name__)
CORS(app)

metrics = MetricsModel()
alerts_model = AlertsModel()

def load_config():
    config_path = os.getenv('CONFIG_PATH', '/config/healthchecks.yml')
    with open(config_path) as f:
        return yaml.safe_load(f)

def load_thresholds():
    path = os.getenv('CONFIG_PATH', '/config/healthchecks.yml').replace('healthchecks.yml', 'thresholds.yml')
    try:
        with open(path) as f:
            return yaml.safe_load(f).get('thresholds', {})
    except Exception:
        return {}

def run_checks():
    try:
        cfg = load_config()
        checks = cfg.get('healthchecks', {})
        thr = load_thresholds()

        warn_rt   = int(thr.get('response_time', {}).get('warning',  '1000ms').replace('ms', ''))
        crit_rt   = int(thr.get('response_time', {}).get('critical', '5000ms').replace('ms', ''))
        warn_up   = float(thr.get('uptime', {}).get('warning',  '95%').replace('%', ''))
        crit_up   = float(thr.get('uptime', {}).get('critical', '90%').replace('%', ''))

        for name, conf in checks.items():
            t = conf.get('type')
            start = time.time()
            try:
                if t == 'http':
                    result = HttpCheck(conf).run()
                elif t == 'database':
                    result = DbCheck(conf).run()
                elif t == 'tcp':
                    result = TcpCheck(conf).run()
                else:
                    result = {'status': 'unknown'}
            except Exception as e:
                result = {'status': 'critical', 'error': str(e)}

            elapsed = int((time.time() - start) * 1000)
            result['response_time'] = elapsed

            # threshold: response time
            if elapsed >= crit_rt:
                result['status'] = 'critical'
                alerts_model.add(name, f'Response time crítico: {elapsed}ms', 'critical')
            elif elapsed >= warn_rt:
                if result['status'] == 'healthy':
                    result['status'] = 'warning'
                alerts_model.add(name, f'Response time alto: {elapsed}ms', 'warning')

            if result['status'] != 'healthy':
                alerts_model.add(name, f'Serviço {result["status"]}', result['status'])

            metrics.save(name, result)

            # threshold: uptime (verifica após salvar para ter o valor calculado)
            uptime = metrics.get_latest().get(metrics._normalize(name), {}).get('uptime', 100.0)
            if uptime <= crit_up:
                alerts_model.add(name, f'Uptime crítico: {uptime:.1f}%', 'critical')
            elif uptime <= warn_up:
                alerts_model.add(name, f'Uptime baixo: {uptime:.1f}%', 'warning')

            # se voltou a ser healthy e uptime ok, resolve alertas
            if result['status'] == 'healthy' and uptime > warn_up:
                alerts_model.resolve(name)
    except Exception as e:
        print(f'Erro no ciclo de checks: {e}')

def start_scheduler():
    # aguarda Flask estar pronto antes de iniciar os checks
    time.sleep(3)
    run_checks()
    scheduler = BackgroundScheduler()
    scheduler.add_job(run_checks, 'interval', seconds=15)
    scheduler.start()

@app.route('/health')
def health():
    return jsonify({'status': 'ok'})

@app.route('/health/status')
def health_status():
    return jsonify(metrics.get_latest())

@app.route('/metrics')
def get_metrics():
    return jsonify(metrics.get_all())

@app.route('/metrics/history')
def get_history():
    return jsonify(metrics.get_history())

@app.route('/alerts')
def get_alerts():
    return jsonify(alerts_model.get_recent())

if __name__ == '__main__':
    t = threading.Thread(target=start_scheduler, daemon=True)
    t.start()
    host = os.getenv('FLASK_HOST', '0.0.0.0')
    app.run(host=host, port=5000, threaded=True)
