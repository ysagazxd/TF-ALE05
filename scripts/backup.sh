#!/bin/bash
# backup.sh - Backup automático de dados e configurações
set -e

BACKUP_DIR="${1:-backups/$(date +%Y%m%d_%H%M%S)}"
LOG="logs/backup_$(date +%Y%m%d_%H%M%S).log"
mkdir -p logs "$BACKUP_DIR"

log() { echo "[$(date '+%H:%M:%S')] $1" | tee -a "$LOG"; }

log "=== Iniciando backup em $BACKUP_DIR ==="

# 1. Backup das configurações
log "Copiando configurações..."
cp -r config/ "$BACKUP_DIR/config"
cp docker-compose.yml "$BACKUP_DIR/docker-compose.yml"

# 2. Backup do banco de dados
log "Fazendo dump do banco de dados..."
if docker compose ps db | grep -q "Up"; then
    if docker compose exec -T db mysqldump -u appuser -papppass monitoring \
        > "$BACKUP_DIR/db_backup.sql" 2>&1; then
        log "Dump do banco OK"
    else
        log "AVISO: Falha no dump do banco"
    fi
else
    log "AVISO: Container do banco não está rodando, pulando dump"
fi

# 3. Backup dos logs recentes
log "Copiando logs recentes..."
if [ -d logs ]; then
    cp -r logs/ "$BACKUP_DIR/logs_snapshot" 2>/dev/null || true
fi

# 4. Compactar backup
log "Compactando backup..."
if tar -czf "${BACKUP_DIR}.tar.gz" -C "$(dirname "$BACKUP_DIR")" "$(basename "$BACKUP_DIR")"; then
    rm -rf "$BACKUP_DIR"
    log "Backup compactado: ${BACKUP_DIR}.tar.gz"
else
    log "AVISO: Falha ao compactar, backup mantido em $BACKUP_DIR"
fi

# 5. Remover backups com mais de 7 dias
log "Limpando backups antigos (>7 dias)..."
if find backups/ -name "*.tar.gz" -mtime +7 -delete 2>/dev/null; then
    log "Limpeza OK"
fi

log "=== Backup concluído! ==="
