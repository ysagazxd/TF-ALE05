# Healthchecks

## Tipos Implementados

### HTTP Check (`http_check.py`)
Verifica endpoints HTTP/HTTPS. Valida status code e corpo da resposta.

### Database Check (`db_check.py`)
Conecta ao MySQL e executa query de validação. Retorna número de conexões ativas.

### TCP Check (`custom_check.py`)
Verifica conectividade TCP. Para Redis, executa PING e coleta métricas de memória.

## Configuração (`config/healthchecks.yml`)

Cada serviço define: `type`, `interval`, `timeout`, `retries` e parâmetros específicos do tipo.

## Thresholds (`config/thresholds.yml`)

| Métrica | Warning | Critical |
|---------|---------|----------|
| Response Time | 1000ms | 5000ms |
| Uptime | 95% | 90% |
| Error Rate | 5% | 10% |

## Histórico

Métricas são armazenadas em memória (últimas 24 amostras por serviço) e expostas via `GET /metrics/history`.
