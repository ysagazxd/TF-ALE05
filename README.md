# TF05 - Sistema de Monitoramento e Automação

## Aluno
- **Nome:** Bruno Rocha Rozadas de Jesus
- **RA:** 6324038
- **Curso:** Análise e Desenvolvimento de Sistemas - UniFAAT

## Funcionalidades
- Healthchecks inteligentes (HTTP, TCP, Database)
- Dashboard de monitoramento em tempo real
- Sistema de alertas (webhook configurável)
- Automação completa de deploy com zero downtime
- Rollback automático em caso de falha
- Scripts de manutenção (backup, cleanup, relatórios)

## Estrutura
```
TF05_2026/
├── api/
│   ├── healthchecks/
│   │   ├── __init__.py
│   │   ├── custom_check.py
│   │   ├── db_check.py
│   │   └── http_check.py
│   ├── models/
│   │   ├── __init__.py
│   │   ├── alerts.py
│   │   └── metrics.py
│   ├── app.py
│   ├── Dockerfile
│   └── requirements.txt
├── backups/
├── config/
│   ├── alerts.yml
│   ├── healthchecks.yml
│   └── thresholds.yml
├── dashboard/
│   ├── css/
│   │   └── dashboard.css
│   ├── js/
│   │   ├── charts.js
│   │   └── dashboard.js
│   ├── Dockerfile
│   ├── index.html
│   └── nginx.conf
├── database/
│   ├── migrations/
│   │   └── 001_add_indexes.sql
│   └── init.sql
├── docs/
│   ├── automation.md
│   ├── healthchecks.md
│   └── maintenance.md
├── logs/
├── scripts/
│   ├── backup.sh
│   ├── build.sh
│   ├── cleanup.sh
│   ├── deploy.sh
│   ├── health-monitor.sh
│   └── rollback.sh
├── .gitignore
├── docker-compose.yml
├── LICENSE
└── README.md
```

## Como Executar

### Pré-requisitos
- Docker e Docker Compose
- Bash (Linux/macOS ou WSL no Windows)

### Execução Completa
```bash
git clone https://github.com/ysagazxd/TF-ALE05
cd TF05_2026

# Build automatizado
./scripts/build.sh

# Deploy automatizado
./scripts/deploy.sh

# Acessar dashboard
open http://localhost:3000
```

## Scripts Disponíveis
- `./scripts/build.sh` — Build com validação de ambiente e imagens
- `./scripts/deploy.sh` — Deploy com zero downtime e rollback automático
- `./scripts/rollback.sh [backup_dir]` — Rollback para versão anterior
- `./scripts/backup.sh [dir]` — Backup de dados e configurações
- `./scripts/cleanup.sh` — Limpeza de logs, imagens e volumes antigos
- `./scripts/health-monitor.sh` — Monitoramento manual

## Endpoints
- **Dashboard:** http://localhost:3000
- **API Health:** http://localhost:5000/health
- **Health Status:** http://localhost:5000/health/status
- **Métricas:** http://localhost:5000/metrics
- **Histórico:** http://localhost:5000/metrics/history
- **Alertas:** http://localhost:5000/alerts

## Configuração
- **Healthchecks:** `config/healthchecks.yml`
- **Alertas:** `config/alerts.yml`
- **Thresholds:** `config/thresholds.yml`

## Monitoramento
```bash
# Status em tempo real
./scripts/health-monitor.sh --watch

# Relatório de saúde
./scripts/health-monitor.sh --report

# Verificação rápida de todos os serviços
./scripts/health-monitor.sh --check-all
```

## Healthchecks Implementados

| Serviço | Tipo | Intervalo |
|---------|------|-----------|
| web-frontend | HTTP | 30s |
| api-backend | HTTP + Auth | 15s |
| database | Database (MySQL) | 60s |
| redis-cache | TCP + PING | 30s |

## Thresholds de Alerta

| Métrica | Warning | Critical |
|---------|---------|----------|
| Response Time | 1000ms | 5000ms |
| Uptime | 95% | 90% |
| Error Rate | 5% | 10% |

---
> **Disciplina:** Implementação de Software — UniFAAT 2026.1
