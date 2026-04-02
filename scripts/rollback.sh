#!/bin/bash
# rollback.sh - Rollback para versão anterior usando backup
set -e

BACKUP_DIR="${1:-}"
LOG="logs/rollback_$(date +%Y%m%d_%H%M%S).log"
mkdir -p logs

log() { echo "[$(date '+%H:%M:%S')] $1" | tee -a "$LOG"; }

log "=== Iniciando rollback ==="

# Usar backup mais recente se não especificado
if [ -z "$BACKUP_DIR" ]; then
    # Procura pasta descompactada ou extrai o tar.gz mais recente
    BACKUP_DIR=$(find backups -maxdepth 1 -type d -name '20*' | sort -r | head -1)
    if [ -z "$BACKUP_DIR" ]; then
        LATEST_TAR=$(find backups -maxdepth 1 -name '20*.tar.gz' | sort -r | head -1)
        if [ -n "$LATEST_TAR" ]; then
            tar -xzf "$LATEST_TAR" -C backups/
            BACKUP_DIR=$(find backups -maxdepth 1 -type d -name '20*' | sort -r | head -1)
        fi
    fi
    [ -z "$BACKUP_DIR" ] && { log "ERRO: Nenhum backup encontrado"; exit 1; }
fi

# Extrair tar.gz se o diretório não existir mas o arquivo sim
if [ ! -d "$BACKUP_DIR" ] && [ -f "${BACKUP_DIR}.tar.gz" ]; then
    log "Extraindo backup compactado..."
    tar -xzf "${BACKUP_DIR}.tar.gz" -C backups/
fi

log "Usando backup: $BACKUP_DIR"
[ -d "$BACKUP_DIR" ] || { log "ERRO: Diretório de backup não existe: $BACKUP_DIR"; exit 1; }

# 1. Parar serviços atuais
log "Parando serviços..."
docker compose down 2>&1 | tee -a "$LOG"

# 2. Restaurar docker-compose.yml se houver backup
[ -f "$BACKUP_DIR/docker-compose.yml" ] && cp "$BACKUP_DIR/docker-compose.yml" docker-compose.yml
log "Configuração restaurada"

# 3. Restaurar banco de dados
if [ -f "$BACKUP_DIR/db_backup.sql" ]; then
    log "Restaurando banco de dados..."
    docker compose up -d db
    sleep 15
    docker compose exec -T db mysql -u appuser -papppass monitoring < "$BACKUP_DIR/db_backup.sql"
    log "Banco restaurado"
fi

# 4. Subir serviços com imagens anteriores
log "Subindo serviços com versão anterior..."
docker compose up -d 2>&1 | tee -a "$LOG"
sleep 20

# 5. Verificar saúde
if curl -sf http://localhost:5000/health &>/dev/null; then
    log "Rollback concluído com sucesso!"
else
    log "AVISO: Serviço pode não estar totalmente saudável após rollback"
fi

log "=== Rollback finalizado. Log: $LOG ==="
