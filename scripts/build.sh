#!/bin/bash
# build.sh - Build automatizado com validação de ambiente e imagens
set -e

LOG="logs/build_$(date +%Y%m%d_%H%M%S).log"
mkdir -p logs

log() { echo "[$(date '+%H:%M:%S')] $1" | tee -a "$LOG"; }

log "=== Iniciando build automatizado ==="

# 1. Validar dependências
log "Validando dependências..."
for cmd in docker curl; do
    command -v "$cmd" &>/dev/null || { log "ERRO: $cmd não encontrado"; exit 1; }
done
log "Dependências OK"

# 2. Validar arquivos de configuração
log "Validando configurações..."
for f in config/healthchecks.yml config/alerts.yml config/thresholds.yml; do
    [ -f "$f" ] || { log "ERRO: $f não encontrado"; exit 1; }
done
log "Configurações OK"

# 3. Build das imagens
log "Construindo imagens Docker..."
docker compose build --no-cache 2>&1 | tee -a "$LOG"
log "Imagens construídas"

# 4. Validar imagens geradas
log "Validando imagens..."
for img in tf05_2026_2026-api tf05_2026_2026-dashboard tf05-api tf05-dashboard; do
    if docker image inspect "$img" &>/dev/null; then
        log "  ✓ $img"
    else
        log "  ✗ $img não encontrada"
    fi
done

log "=== Build concluído com sucesso! Log: $LOG ==="
