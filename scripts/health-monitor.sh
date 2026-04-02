#!/bin/bash
# health-monitor.sh - Monitoramento manual de saúde dos serviços
# Uso: ./scripts/health-monitor.sh [--check-all | --watch | --report | --test-alerts | --pre-deploy]

API="http://localhost:5000"
LOG="logs/health_$(date +%Y%m%d_%H%M%S).log"
mkdir -p logs

log()   { echo "[$(date '+%H:%M:%S')] $1" | tee -a "$LOG"; }
green() { echo -e "\033[32m$1\033[0m"; }
red()   { echo -e "\033[31m$1\033[0m"; }
yellow(){ echo -e "\033[33m$1\033[0m"; }

check_service() {
    local name=$1 url=$2
    local start=$(date +%s%3N)
    if curl -sf "$url" &>/dev/null; then
        local elapsed=$(( $(date +%s%3N) - start ))
        green "  ✓ $name (${elapsed}ms)"
        return 0
    else
        red "  ✗ $name - FALHOU"
        return 1
    fi
}

check_all() {
    log "=== Verificando todos os serviços ==="
    local failed=0
    check_service "Dashboard"    "http://localhost:3000"  || failed=$((failed+1))
    check_service "API"          "$API/health"            || failed=$((failed+1))
    check_service "API Status"   "$API/health/status"     || failed=$((failed+1))
    check_service "DB (via API)" "$API/metrics"           || failed=$((failed+1))
    if [ $failed -eq 0 ]; then
        green "Todos os serviços saudáveis!"
        return 0
    else
        red "$failed serviço(s) com falha!"
        return 1
    fi
}

watch_mode() {
    echo "Monitoramento em tempo real (Ctrl+C para sair)..."
    while true; do
        clear
        echo "=== Health Monitor - $(date '+%d/%m/%Y %H:%M:%S') ==="
        STATUS=$(curl -sf "$API/health/status" 2>/dev/null || echo '{}')
        echo "$STATUS" | python3 -c "
import json,sys
data=json.load(sys.stdin)
for svc,info in data.items():
    s=info.get('status','unknown')
    rt=info.get('response_time','--')
    up=info.get('uptime','--')
    icon='✓' if s=='healthy' else '✗'
    print(f'  {icon} {svc:<15} status={s:<10} rt={rt}ms  uptime={up}%')
" 2>/dev/null || echo "  API não disponível"
        sleep 10
    done
}

generate_report() {
    log "=== Relatório de Saúde - $(date '+%d/%m/%Y %H:%M:%S') ==="
    STATUS=$(curl -sf "$API/health/status" 2>/dev/null || echo '{}')
    ALERTS=$(curl -sf "$API/alerts" 2>/dev/null || echo '[]')
    echo "$STATUS" >> "$LOG"
    echo "Alertas recentes:" >> "$LOG"
    echo "$ALERTS" >> "$LOG"
    log "Relatório salvo em $LOG"
    cat "$LOG"
}

test_alerts() {
    log "Testando sistema de alertas..."
    if curl -sf -X POST "$API/alerts/test" &>/dev/null; then
        green "Alerta de teste enviado!"
    else
        yellow "Endpoint de teste não disponível (normal em produção)"
    fi
}

case "${1:-}" in
    --check-all)   check_all ;;
    --watch)       watch_mode ;;
    --report)      generate_report ;;
    --test-alerts) test_alerts ;;
    --pre-deploy)  check_all ;;
    *)
        echo "Uso: $0 [--check-all | --watch | --report | --test-alerts | --pre-deploy]"
        check_all
        ;;
esac
