#!/bin/bash
# deploy.sh - Deploy com zero downtime e rollback automático em caso de falha
set -e

BACKUP_DIR="backups/$(date +%Y%m%d_%H%M%S)"
LOG="logs/deploy_$(date +%Y%m%d_%H%M%S).log"
mkdir -p logs

log() { echo "[$(date '+%H:%M:%S')] $1" | tee -a "$LOG"; }

log "=== Iniciando deploy ==="

# 1. Backup antes do deploy
log "Criando backup em $BACKUP_DIR..."
./scripts/backup.sh "$BACKUP_DIR" 2>&1 | tee -a "$LOG"

# 2. Health check pré-deploy
log "Verificando saúde atual dos serviços..."
if ! ./scripts/health-monitor.sh --check-all 2>&1 | tee -a "$LOG"; then
    log "AVISO: Serviços com problemas antes do deploy, continuando..."
fi

# 3. Build das novas imagens
log "Construindo novas imagens..."
docker compose build 2>&1 | tee -a "$LOG"

# 4. Deploy
log "Subindo novos containers..."
docker compose up -d --no-deps db redis 2>&1 | tee -a "$LOG"
sleep 5

docker compose up -d --no-deps api 2>&1 | tee -a "$LOG"
log "Aguardando API inicializar (30s)..."
sleep 30

# 5. Verificar saúde após deploy
log "Verificando saúde pós-deploy..."
RETRIES=3
for i in $(seq 1 $RETRIES); do
    if curl -sf http://localhost:5000/health &>/dev/null; then
        log "API saudável após deploy!"
        break
    fi
    log "Tentativa $i/$RETRIES falhou, aguardando..."
    sleep 10
    if [ "$i" -eq "$RETRIES" ]; then
        log "ERRO: API não respondeu após deploy. Executando rollback..."
        ./scripts/rollback.sh "$BACKUP_DIR" 2>&1 | tee -a "$LOG"
        exit 1
    fi
done

# 6. Subir dashboard
docker compose up -d --no-deps dashboard 2>&1 | tee -a "$LOG"

log "=== Deploy concluído com sucesso! Log: $LOG ==="
