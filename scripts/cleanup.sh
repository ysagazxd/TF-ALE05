#!/bin/bash
# cleanup.sh - Limpeza automática de recursos antigos
set -e

LOG="logs/cleanup_$(date +%Y%m%d_%H%M%S).log"
mkdir -p logs

log() { echo "[$(date '+%H:%M:%S')] $1" | tee -a "$LOG"; }

log "=== Iniciando limpeza de recursos ==="

# 1. Remover logs com mais de 30 dias
log "Removendo logs antigos (>30 dias)..."
find logs/ -name "*.log" -mtime +30 -delete 2>/dev/null
log "Logs antigos removidos"

# 2. Remover backups com mais de 7 dias
log "Removendo backups antigos (>7 dias)..."
find backups/ -name "*.tar.gz" -mtime +7 -delete 2>/dev/null
log "Backups antigos removidos"

# 3. Limpar imagens Docker não utilizadas
log "Removendo imagens Docker não utilizadas..."
docker image prune -f 2>&1 | tee -a "$LOG"

# 4. Limpar volumes Docker órfãos
log "Removendo volumes Docker órfãos..."
docker volume prune -f 2>&1 | tee -a "$LOG"

# 5. Limpar containers parados
log "Removendo containers parados..."
docker container prune -f 2>&1 | tee -a "$LOG"

# 6. Relatório de uso de disco
log "--- Uso de disco após limpeza ---"
df -h . | tee -a "$LOG"
docker system df 2>&1 | tee -a "$LOG"

log "=== Limpeza concluída! Log: $LOG ==="
