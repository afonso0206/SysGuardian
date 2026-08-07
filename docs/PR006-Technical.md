# PR-006 — Integração de Impressoras

## Escopo

A PR-006 adiciona a categoria `Printers` ao diagnóstico do SysGuardian. A
coleta é feita por SNMP no módulo `modules/printers.sh`; o Core transforma os
resultados em eventos e score; o Dashboard apresenta esses eventos na rota
`#printers`.

## Fluxo de dados

```text
${CONFIG_DIR}/printers.conf
  → collect_printers
  → arrays PRINTER_*
  → check_printers
  → REPORT_DATA e CATEGORY_SCORES[Printers]
  → report_*.json (entries e category_scores)
  → Dashboard / rota #printers
```

O módulo não escreve relatórios e não calcula o score geral. Essas são
responsabilidades do Core, conforme o padrão dos módulos existentes.

## Módulo

`collect_printers` é a API de coleta da PR-006. Ela lê o inventário e os
parâmetros SNMP, executa `snmpbulkwalk` para cada equipamento e preenche os
arrays globais `PRINTER_*` com disponibilidade, identificação, contadores,
toner e erro de coleta.

O módulo possui guarda de carregamento (`SYSGUARDIAN_PRINTERS_LOADED`) e
proteção contra execução direta. A coleta requer `snmpbulkwalk` quando há
impressoras configuradas.

## Core

O Core carrega `modules/printers.sh`, inicializa a categoria `Printers` com
100 pontos e executa `check_printers` após a verificação de rede.

Para cada equipamento, o check registra eventos por meio de `log_entry`:

- impressora online: evento `OK`;
- impressora offline: evento `ERROR` e redução de 20 pontos;
- toner preto entre 0% e 10%: evento `WARN` e redução de 10 pontos.

Assim, a categoria integra o cálculo geral e é serializada no JSON existente
sem criar um formato paralelo.

## Dashboard

O Dashboard preserva o contrato já consumido pela SPA: `category_scores` e
`entries`. Como consequência, `Printers` aparece automaticamente nos cards e
no radar. A rota `#printers` usa `PrintersComponent` para filtrar e renderizar
somente os eventos cuja categoria é `Printers`.

`Router`, `SidebarComponent` e `SysGuardianAPI` permanecem genéricos; a nova
rota é registrada em `main.js` e declarada em `dashboard/index.html`, como as
demais views.

## Teste

`tests/test_printers.sh` executa uma validação sem rede: verifica a sintaxe do
módulo, seu carregamento e a coleta com inventário ausente. O teste assegura
que o módulo não exige SNMP quando não há impressoras configuradas.
