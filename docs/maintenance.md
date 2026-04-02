# Manutenção

## Limpeza Automática (`cleanup.sh`)

- Logs com mais de 30 dias são removidos automaticamente
- Backups com mais de 7 dias são removidos
- Imagens, volumes e containers Docker não utilizados são purgados

## Backup (`backup.sh`)

Executa backup de:
1. Configurações (`config/`)
2. Dump completo do MySQL
3. Snapshot dos logs recentes

Backups são compactados em `.tar.gz` e armazenados em `backups/`.

## Monitoramento de Recursos

```bash
# Status em tempo real
./scripts/health-monitor.sh --watch

# Relatório completo
./scripts/health-monitor.sh --report

# Verificação rápida
./scripts/health-monitor.sh --check-all
```

## Otimização do Banco

O schema inclui índices em `service`, `checked_at`, `severity` e `status` para garantir performance nas consultas de histórico e alertas.
