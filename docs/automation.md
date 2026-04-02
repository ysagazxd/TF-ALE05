# Automação de Deploy

## Scripts Disponíveis

| Script | Descrição |
|--------|-----------|
| `build.sh` | Valida ambiente, constrói e valida imagens Docker |
| `deploy.sh` | Deploy com backup automático e rollback em caso de falha |
| `rollback.sh` | Restaura versão anterior a partir de backup |
| `backup.sh` | Backup de banco de dados e configurações |
| `cleanup.sh` | Remove recursos antigos (logs, imagens, volumes) |
| `health-monitor.sh` | Monitoramento manual com múltiplos modos |

## Fluxo de Deploy

```
build.sh → backup.sh → health check pré-deploy → deploy → health check pós-deploy
                                                              ↓ falha
                                                         rollback.sh
```

## Zero Downtime

O `deploy.sh` sobe os novos containers antes de parar os antigos, garantindo que o serviço permaneça disponível durante a atualização.

## Rollback Automático

Se o health check pós-deploy falhar após 3 tentativas (30s cada), o `rollback.sh` é chamado automaticamente com o diretório de backup criado no início do deploy.
