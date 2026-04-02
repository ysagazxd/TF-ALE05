const API = '/api';

function setStatus(cardId, dotId, status) {
    const card = document.getElementById(cardId);
    const dot = document.getElementById(dotId);
    if (!card || !dot) return;
    card.className = `service-card ${status}`;
    dot.className = `status-indicator ${status}`;
}

function updateService(name, data) {
    const key = name.toLowerCase();
    const uptime = document.getElementById(`${key}-uptime`);
    const response = document.getElementById(`${key}-response`);
    const connections = document.getElementById(`${key}-connections`);

    if (uptime) uptime.textContent = data.uptime !== undefined ? `${data.uptime.toFixed(1)}%` : '--';
    if (response) response.textContent = data.response_time !== undefined ? `${data.response_time}ms` : '--';
    if (connections) connections.textContent = data.connections || '--';

    const status = data.status === 'healthy' ? 'healthy' : data.status === 'warning' ? 'warning' : 'critical';
    setStatus(`card-${key}`, `dot-${key}`, status);
}

function sanitize(str) {
    const d = document.createElement('div');
    d.textContent = String(str ?? '--');
    return d.innerHTML;
}

function renderAlerts(alerts) {
    const list = document.getElementById('alerts-list');
    if (!alerts || alerts.length === 0) {
        list.innerHTML = '<p class="no-alerts">Nenhum alerta recente.</p>';
        return;
    }
    list.innerHTML = alerts.slice(0, 10).map(a => {
        const sev = ['warning', 'critical', 'info'].includes(a.severity) ? a.severity : 'info';
        return `<div class="alert-item ${sev}">
            <span>${sanitize(a.service)}</span>
            <span>${sanitize(a.message)}</span>
            <span class="alert-time">${sanitize(new Date(a.timestamp).toLocaleTimeString('pt-BR'))}</span>
        </div>`;
    }).join('');
}

function updateCharts(history) {
    if (!history) return;
    const services = ['frontend', 'backend', 'database', 'redis'];

    // Response Time — linha temporal com os 4 serviços
    const base = history[services.find(s => history[s]?.length)] || [];
    const labels = base.map(d =>
        new Date(d.timestamp).toLocaleTimeString('pt-BR', { hour: '2-digit', minute: '2-digit' })
    );
    responseTimeChart.data.labels = labels;
    services.forEach((svc, i) => {
        responseTimeChart.data.datasets[i].data = (history[svc] || []).map(d => d.response_time ?? null);
    });
    responseTimeChart.update();

    // Uptime — média real de todos os checks do histórico por serviço
    uptimeChart.data.datasets[0].data = services.map(svc => {
        const h = history[svc];
        if (!h || !h.length) return 0;
        const healthy = h.filter(d => d.status === 'healthy').length;
        return parseFloat(((healthy / h.length) * 100).toFixed(2));
    });
    uptimeChart.update();
}

async function fetchAndUpdate() {
    try {
        const [statusRes, alertsRes, historyRes] = await Promise.all([
            fetch(`${API}/health/status`),
            fetch(`${API}/alerts`),
            fetch(`${API}/metrics/history`)
        ]);

        const status = await statusRes.json();
        const alerts = await alertsRes.json();
        const history = await historyRes.json();

        ['frontend', 'backend', 'database', 'redis'].forEach(svc => {
            if (status[svc]) updateService(svc, status[svc]);
        });

        const allHealthy = Object.values(status).every(s => s.status === 'healthy');
        const hasCritical = Object.values(status).some(s => s.status === 'critical');
        const overallStatus = hasCritical ? 'critical' : allHealthy ? 'healthy' : 'warning';
        document.getElementById('overall-status').className = `status-card ${overallStatus}`;
        document.getElementById('overall-dot').className = `status-indicator ${overallStatus}`;
        document.getElementById('overall-text').textContent = hasCritical ? 'Crítico' : allHealthy ? 'Saudável' : 'Atenção';

        renderAlerts(alerts);
        updateCharts(history);
        document.getElementById('last-update').textContent = new Date().toLocaleTimeString('pt-BR');
    } catch (e) {
        console.error('Erro ao buscar dados:', e);
    }
}

fetchAndUpdate();
setInterval(fetchAndUpdate, 15000);
