const responseTimeChart = new Chart(document.getElementById('responseTimeChart'), {
    type: 'line',
    data: {
        labels: [],
        datasets: [
            { label: 'Frontend', data: [], borderColor: '#38bdf8', tension: 0.4, fill: false, pointRadius: 3 },
            { label: 'Backend',  data: [], borderColor: '#a78bfa', tension: 0.4, fill: false, pointRadius: 3 },
            { label: 'Database', data: [], borderColor: '#34d399', tension: 0.4, fill: false, pointRadius: 3 },
            { label: 'Redis',    data: [], borderColor: '#fb923c', tension: 0.4, fill: false, pointRadius: 3 }
        ]
    },
    options: {
        responsive: true,
        plugins: { legend: { labels: { color: '#94a3b8' } } },
        scales: {
            x: { ticks: { color: '#64748b', maxTicksLimit: 8 }, grid: { color: '#1e293b' } },
            y: { ticks: { color: '#64748b' }, grid: { color: '#1e293b' },
                 title: { display: true, text: 'ms', color: '#64748b' } }
        }
    }
});

const uptimeChart = new Chart(document.getElementById('uptimeChart'), {
    type: 'bar',
    data: {
        labels: ['Frontend', 'Backend', 'Database', 'Redis'],
        datasets: [{
            label: 'Uptime %',
            data: [0, 0, 0, 0],
            backgroundColor: ['#38bdf8cc', '#a78bfacc', '#34d399cc', '#fb923ccc'],
            borderColor:     ['#38bdf8',   '#a78bfa',   '#34d399',   '#fb923c'],
            borderWidth: 2,
            borderRadius: 6
        }]
    },
    options: {
        responsive: true,
        plugins: {
            legend: { display: false },
            tooltip: {
                callbacks: {
                    label: ctx => {
                        const svc = ['Frontend','Backend','Database','Redis'][ctx.dataIndex];
                        return `${svc}: ${ctx.parsed.y.toFixed(2)}%`;
                    }
                }
            }
        },
        scales: {
            x: { ticks: { color: '#94a3b8' }, grid: { color: '#1e293b' } },
            y: {
                min: 0, max: 100,
                ticks: { color: '#64748b', callback: v => `${v}%` },
                grid: { color: '#1e293b' }
            }
        },
        animation: { duration: 400 }
    }
});
