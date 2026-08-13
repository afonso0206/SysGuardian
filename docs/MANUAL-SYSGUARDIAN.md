# Manual Oficial do SysGuardian

Manual de Instalação, Administração e Uso
Unidade ESMU — Universidade do Estado de Minas Gerais (UEMG)

Versão do sistema documentada: `7.0.0-alpha2`
Base documental: branch `develop`, commit `5e856ab`

> Este manual descreve o comportamento comprovado no código versionado. Quando
> uma informação operacional não puder ser comprovada nessa fonte, ela será
> identificada como **NÃO CONFIRMADO NO CÓDIGO**.

## 1. Apresentação

### 1.1 Finalidade

O SysGuardian é uma ferramenta de diagnóstico, auditoria e monitoramento da
saúde de servidores Linux. Ele coleta informações do sistema operacional e de
serviços instalados, atribui pontuações por categoria e gera relatórios para
análise técnica.

Na ESMU/UEMG, o sistema também monitora impressoras HP por SNMP e fornece um
relatório gerencial em PDF para conferência contratual com a Simpress.

### 1.2 Escopo

O manual cobre:

- arquitetura e instalação do coletor;
- configuração geral e de impressoras;
- execução manual e automática;
- diagnósticos e relatórios;
- dashboard e APIs PHP;
- monitoramento SNMP;
- relatório gerencial de impressoras;
- administração, atualização, troubleshooting e desinstalação.

### 1.3 Público-alvo

Profissionais de TI responsáveis por servidores Linux, pelo ambiente da ESMU
e pela conferência das impressoras contratadas.

### 1.4 Estado e versão documentada

O arquivo `VERSION`, o core e as bibliotecas informam a versão
`7.0.0-alpha2`. O badge `6.3.0` existente no `README.md` está desatualizado e
não deve ser usado como referência de versão.

## 2. Visão geral da arquitetura

### 2.1 Core

O orquestrador é `src/sysguardian`. Depois da instalação, ele fica em:

```text
/usr/share/sysguardian/sysguardian
```

O core carrega configuração, bibliotecas e módulos, executa os diagnósticos,
calcula as pontuações e gera os relatórios.

### 2.2 Módulos

Os módulos ficam em `/usr/share/sysguardian/modules/`. Eles disponibilizam
funções de coleta para sistema, CPU, memória, discos, rede, serviços,
segurança, backup, logs e impressoras.

Parte das verificações permanece diretamente no core, incluindo SMART, LVM,
Docker, Apache, PHP, MySQL/MariaDB, TRIM e ambiente gráfico.

### 2.3 Configurações

```text
/etc/sysguardian/sysguardian.conf
/etc/sysguardian/printers.conf
```

### 2.4 Relatórios

```text
/var/log/sysguardian/
```

O core gera relatórios TXT, HTML e JSON. Um PDF técnico também pode ser
gerado quando `wkhtmltopdf` está disponível.

### 2.5 Dashboard

O dashboard ativo está no diretório `dashboard/` do repositório. Ele é uma
SPA em HTML, CSS e JavaScript ES Modules, apoiada por endpoints PHP.

> **NÃO CONFIRMADO NO CÓDIGO:** o instalador não publica o dashboard em um
> DocumentRoot ou Alias. A URL, o VirtualHost, HTTPS, autenticação e o caminho
> de publicação precisam ser definidos pela administração do servidor web.

### 2.6 Systemd

O timer dispara um serviço `oneshot` que executa o SysGuardian como root duas
vezes por dia.

## 3. Requisitos

### 3.1 Requisitos obrigatórios do core

O código declara compatibilidade com:

- Ubuntu 22.04 LTS ou Ubuntu 24.04 LTS;
- kernel Linux 5.x ou 6.x;
- arquitetura x86_64, conforme o README;
- Bash;
- systemd para a execução automática;
- permissões de root para instalação e desinstalação.

O instalador não valida a distribuição, o kernel ou a arquitetura.

O core utiliza comandos do ambiente Linux, incluindo:

```text
awk grep sed cut tr xargs date hostname uname md5sum
find df lsblk findmnt systemctl systemd-analyze journalctl
ip ping getent
```

O instalador não verifica nem instala esses comandos.

> **Aviso:** a execução operacional prevista é como root. O serviço systemd
> declara `User=root`, e o README orienta o uso de `sudo`.

### 3.2 Dependências opcionais por funcionalidade

| Funcionalidade | Comando ou dependência | Comportamento na ausência |
|---|---|---|
| SMART | `smartctl` | SMART não é verificado |
| LVM | `vgs`, `lvs` | Métricas LVM ficam indisponíveis |
| Temperatura | `sensors` | Temperatura fica indisponível |
| Docker | `docker` | Registrado como não instalado |
| Apache | `apache2ctl` | Registrado como não instalado |
| PHP | `php` | Diagnóstico PHP não é realizado |
| MySQL/MariaDB | `mysql` ou `mariadb` | Banco registrado como não instalado |
| Firewall | `ufw`, `firewall-cmd` ou `iptables` | Verificação limitada |
| Segurança | Fail2ban, AppArmor, Auditd | Estado informado quando detectável |
| Backup | Borg, Restic, Duplicati, Timeshift ou rdiff-backup | Ferramentas apenas deixam de ser listadas |
| Impressoras | `snmpget`, `snmpwalk` | Dispositivos podem ser classificados como offline |
| PDF técnico | `wkhtmltopdf` | PDF técnico não é gerado |
| Dashboard | servidor web com PHP | Dashboard/API não funciona |
| PDF gerencial | PHP 8+ e TCPDF | Endpoint responde com erro controlado |

O código não informa os nomes dos pacotes Ubuntu que fornecem
`snmpget` e `snmpwalk`: **NÃO CONFIRMADO NO CÓDIGO**.

O PDF gerencial procura TCPDF exatamente em:

```text
/usr/share/php/tcpdf/tcpdf.php
```

O endpoint usa recursos de PHP 8, como `mixed`, union types, `match` e arrow
functions. O instalador não instala PHP ou TCPDF.

## 4. Estrutura de diretórios

### 4.1 Repositório

```text
SysGuardian/
├── config/
├── dashboard/
├── docs/
├── lib/
├── modules/
├── packaging/systemd/
├── src/sysguardian
├── tests/
├── install.sh
└── uninstall.sh
```

Os diretórios `dashboard.backup-20260806-102842/` e
`dashboard.before-migration/` são cópias históricas e não representam o
dashboard ativo.

### 4.2 Arquivos instalados

```text
/usr/local/bin/sysguardian
/usr/share/sysguardian/sysguardian
/usr/share/sysguardian/modules/
/usr/share/sysguardian/lib/
/usr/share/sysguardian/README.md
/usr/share/sysguardian/LICENSE
/usr/share/sysguardian/VERSION
```

### 4.3 Configuração instalada

```text
/etc/sysguardian/sysguardian.conf
/etc/sysguardian/printers.conf
```

### 4.4 Relatórios

```text
/var/log/sysguardian/
```

### 4.5 Unidades systemd

```text
/etc/systemd/system/sysguardian.service
/etc/systemd/system/sysguardian.timer
```

## 5. Instalação do coletor

### 5.1 Obtenção do código

O README documenta:

```bash
git clone https://github.com/afonso0206/SysGuardian.git
cd SysGuardian
```

Para documentar uma versão diferente de `develop` ou um checkout por tag,
consulte o processo de liberação da organização: **NÃO CONFIRMADO NO
CÓDIGO**.

### 5.2 Execução do instalador

```bash
sudo ./install.sh
```

> **Aviso:** o instalador exige root, escreve em `/usr/local/bin`,
> `/usr/share`, `/etc`, `/var/log` e `/etc/systemd/system`, além de habilitar e
> iniciar um timer.

### 5.3 Fluxo interno

O instalador:

1. valida os arquivos do projeto;
2. detecta instalação nova ou upgrade;
3. cria os diretórios de dados, configuração e relatórios;
4. faz backup de `sysguardian.conf`, se existente;
5. instala core, módulos, bibliotecas e metadados;
6. preserva configurações existentes;
7. cria o launcher;
8. instala as unidades systemd;
9. executa `systemctl daemon-reload`;
10. habilita e inicia `sysguardian.timer`;
11. aplica permissões;
12. valida a presença do comando.

O launcher é criado antes da ativação do timer para impedir uma corrida na
primeira execução.

### 5.4 Permissões aplicadas

```text
/usr/local/bin/sysguardian             755
/usr/share/sysguardian/**              755
/etc/sysguardian/sysguardian.conf      644
/etc/sysguardian/printers.conf         644
/etc/systemd/system/*.service          644
/etc/systemd/system/*.timer            644
```

### 5.5 Validação da instalação

O instalador valida que o comando está no PATH e que o timer está ativo. Uma
verificação administrativa não destrutiva compatível com o código é:

```bash
command -v sysguardian
systemctl is-active sysguardian.timer
systemctl status sysguardian.timer
```

## 6. Implantação do dashboard

### 6.1 Pré-requisitos web

O dashboard requer:

- servidor web;
- execução de PHP;
- navegador com JavaScript ES Modules;
- permissão de leitura dos JSONs em `/var/log/sysguardian` pelo PHP;
- TCPDF para o PDF gerencial.

### 6.2 Publicação

O instalador não copia `dashboard/` nem configura o servidor web.

> **NÃO CONFIRMADO NO CÓDIGO:** DocumentRoot, Alias, VirtualHost, URL oficial,
> proprietário dos arquivos e processo de publicação.

Não crie uma configuração de produção com base apenas neste manual sem que
esses itens sejam definidos pela administração da ESMU.

### 6.3 PHP

Os endpoints ativos são:

```text
dashboard/api/latest.php
dashboard/api/printers-report.php
```

O endpoint de PDF gerencial requer PHP 8+ e TCPDF no caminho fixo documentado.

### 6.4 Acesso aos relatórios

`latest.php` acessa diretamente:

```text
/var/log/sysguardian/*.json
```

O usuário do processo PHP precisa conseguir atravessar o diretório e ler os
arquivos. A configuração de permissões para isso é **NÃO CONFIRMADO NO
CÓDIGO**.

### 6.5 URL e segurança

URL, HTTPS, autenticação, autorização e restrição de rede são **NÃO
CONFIRMADO NO CÓDIGO**.

## 7. Configuração geral

### 7.1 Arquivo principal

```text
/etc/sysguardian/sysguardian.conf
```

O core exige pelo menos `DATA_DIR` e `REPORT_DIR`:

```bash
CONFIG_DIR="/etc/sysguardian"
DATA_DIR="/usr/share/sysguardian"
REPORT_DIR="/var/log/sysguardian"
```

### 7.2 Variáveis efetivamente usadas

- `DATA_DIR`: localiza core, módulos e bibliotecas;
- `REPORT_DIR`: define o destino dos relatórios;
- `CONFIG_DIR`: é usado pelo módulo de impressoras para localizar
  `printers.conf`.

### 7.3 Variáveis ainda não implementadas

As opções abaixo existem na configuração, mas não controlam o comportamento
atual:

```text
LOG_RETENTION_DAYS
CHECK_CPU CHECK_MEMORY CHECK_DISKS CHECK_LVM CHECK_SMART
CHECK_NETWORK CHECK_SECURITY CHECK_DOCKER CHECK_APACHE
CHECK_PHP CHECK_MYSQL CHECK_BACKUP CHECK_TRIM
GENERATE_TXT GENERATE_HTML GENERATE_PDF
MIN_SCORE_WARNING MIN_SCORE_CRITICAL
```

Não presuma que alterar essas variáveis habilitará ou desabilitará recursos.

## 8. Configuração de impressoras

### 8.1 Arquivo

```text
/etc/sysguardian/printers.conf
```

### 8.2 Parâmetros SNMP

O formato reconhecido é:

```ini
COMMUNITY=<COMMUNITY_SNMP>
VERSION=2c
TIMEOUT=2
RETRIES=1
PORT=161
```

O valor de community acima é apenas o exemplo versionado. Use a configuração
administrativa autorizada para o ambiente. Não publique communities privadas.

### 8.3 Inventário

```ini
HP_RECEPCAO=192.0.2.10
HP_FINANCEIRO=192.0.2.20
```

O lado esquerdo aceita letras, números e `_`. O lado direito é repassado ao
cliente SNMP como IP ou hostname.

### 8.4 Descoberta e logging

`DISCOVERY` e `LOG_LEVEL` existem no modelo de configuração, mas não são
consumidos. A descoberta automática não está implementada.

### 8.5 Segurança da community

O instalador aplica permissão `644` a `printers.conf`. Isso torna o conteúdo
legível para usuários locais. Proteção adicional da community é **NÃO
CONFIRMADO NO CÓDIGO**.

## 9. Execução manual

### 9.1 Comando instalado

```bash
sudo sysguardian
```

O launcher encaminha todos os argumentos para:

```text
/usr/share/sysguardian/sysguardian
```

### 9.2 Execução a partir do checkout

O README mostra:

```bash
sudo ./src/sysguardian
```

Mesmo nessa forma, o core exige `/etc/sysguardian/sysguardian.conf` e carrega
módulos a partir de `DATA_DIR`, normalmente `/usr/share/sysguardian`.

### 9.3 Subcomandos

Não há CLI com subcomandos. Formas como `sysguardian check` ou
`sysguardian cpu` aparecem somente no roadmap e não são implementadas.

### 9.4 Resultado da execução

Ao final, o programa informa:

- pontuação geral;
- classificação;
- caminhos dos relatórios gerados.

## 10. Execução automática

### 10.1 Serviço

```ini
[Service]
Type=oneshot
ExecStart=/usr/local/bin/sysguardian
User=root
```

O serviço declara dependência de `network-online.target`.

### 10.2 Timer

```ini
[Timer]
OnCalendar=*-*-* 07:00:00
OnCalendar=*-*-* 19:00:00
Persistent=true
AccuracySec=1min
RandomizedDelaySec=30s
Unit=sysguardian.service
```

O SysGuardian executa **todos os dias às 07:00 e às 19:00**, inclusive no
último dia do mês. `Persistent=true` permite recuperar uma execução perdida
durante indisponibilidade.

### 10.3 Validação do agendamento

```bash
systemctl status sysguardian.timer
systemctl list-timers sysguardian.timer
systemd-analyze calendar '*-*-* 07:00:00'
systemd-analyze calendar '*-*-* 19:00:00'
```

Para verificar a unidade sem ativá-la:

```bash
systemd-analyze verify \
  packaging/systemd/sysguardian.service \
  packaging/systemd/sysguardian.timer
```

## 11. Diagnósticos

### 11.1 Sistema e boot

Coleta sistema operacional, kernel, uptime, reinicialização pendente, tempo
de boot, serviços lentos e cadeia crítica do boot.

### 11.2 CPU

Coleta modelo, núcleos, carga e temperatura quando disponível. O core sinaliza
temperatura elevada a partir de 75 °C e crítica a partir de 85 °C.

### 11.3 Memória

Coleta RAM, memória disponível, uso, swap e eventos OOM. O uso de RAM recebe
alerta a partir de 85% e erro a partir de 95%.

### 11.4 Armazenamento e LVM

Identifica discos, tipo, partições, uso, inodes, VGs, LVs e thin pools. Uso de
partição recebe alerta a partir de 85% e erro a partir de 95%.

### 11.5 SMART

Quando `smartctl` existe, consulta integridade, temperatura, desgaste, erros,
setores realocados e dados específicos de NVMe ou SATA.

### 11.6 Rede

Coleta interfaces, endereços, gateway, DNS, velocidade, estado, MAC, erros e
drops. Testa gateway, internet e resolução DNS.

### 11.7 Segurança e serviços

Verifica SSH, firewall, Fail2ban, AppArmor, Auditd, portas, atualizações,
arquivos SUID, permissões graváveis e usuários do grupo sudo.

### 11.8 Backup

Procura diretório de backup, arquivos recentes, tarefas cron, timers e
ferramentas conhecidas. A identificação do diretório segue heurísticas do
módulo e não constitui validação do conteúdo restaurável.

### 11.9 Journal

Resume uso em disco e eventos de erro das últimas 24 horas, incluindo serviços
com maior volume de erros.

### 11.10 Ambiente gráfico

Detecta GNOME ou display managers conhecidos e informa consumo do Xorg quando
aplicável.

### 11.11 Docker

Verifica daemon, containers, healthchecks, reinícios, imagens e volumes
desvinculados e uso de espaço.

### 11.12 Apache

Verifica serviço, sintaxe, MPM, portas, VirtualHosts, SSL e validade de
certificados quando o Apache está presente.

### 11.13 PHP

Registra versão CLI, `php.ini`, timezone, limites, OPcache e extensões.

### 11.14 MySQL/MariaDB

Verifica serviço, versão e métricas. Falhas de autenticação são tratadas como
indisponibilidade das métricas internas.

### 11.15 TRIM

Verifica `fstrim.timer`, última execução conhecida e suporte dos dispositivos.

### 11.16 Impressoras

Verifica disponibilidade, latência, identificação, contadores e consumíveis
por SNMP, conforme detalhado no capítulo seguinte.

## 12. Módulo de impressoras

### 12.1 Fluxo de coleta

```text
/etc/sysguardian/printers.conf
  → collect_printers()
  → arrays PRINTER_*
  → check_printers()
  → score e entries
  → printers.summary e printers.devices[]
  → dashboard e PDF gerencial
```

### 12.2 Consultas principais

O módulo usa `snmpget -On` para OIDs escalares e `snmpwalk -On` para
subárvores específicas. Não faz walk da raiz SNMP.

Uma validação baseada na consulta escalar real do módulo pode ser feita com
valores autorizados do ambiente:

```bash
snmpget -On -v 2c -c '<COMMUNITY>' -t 2 -r 1 '<IP>:161' \
  .1.3.6.1.2.1.1.1.0 \
  .1.3.6.1.2.1.25.3.2.1.3.1 \
  .1.3.6.1.2.1.43.5.1.1.17.1 \
  .1.3.6.1.2.1.1.6.0 \
  .1.3.6.1.2.1.1.3.0
```

> Não coloque communities reais em chamados, documentação pública ou
> histórico de shell compartilhado.

### 12.3 Status

O dispositivo é offline quando não há resposta real nem nas consultas
principais nem na tabela de interfaces. Respostas `No Such Object` e
`No Such Instance` são descartadas.

### 12.4 Modelo, serial, descrição e localização

Fontes principais:

| Campo | OID |
|---|---|
| Descrição | `.1.3.6.1.2.1.1.1.0` |
| Modelo | `.1.3.6.1.2.1.25.3.2.1.3.1` |
| Serial | `.1.3.6.1.2.1.43.5.1.1.17.1` |
| Localização | `.1.3.6.1.2.1.1.6.0` |
| Uptime | `.1.3.6.1.2.1.1.3.0` |

O firmware é extraído de `sysDescr` somente quando o texto começa com um
formato reconhecível, como `modelo; Vversão`. Caso contrário, fica
indisponível.

### 12.5 MAC

O módulo consulta `.1.3.6.1.2.1.2.2.1`, procura `ifType=6`, exige MAC não
vazio e prefere `ifOperStatus=1`. Não assume um `ifIndex` fixo.

### 12.6 Total de páginas

Subárvore:

```text
.1.3.6.1.2.1.43.10.2.1
```

Colunas principais:

- `prtMarkerCounterUnit`: `.1.3.6.1.2.1.43.10.2.1.3`;
- `prtMarkerLifeCount`: `.1.3.6.1.2.1.43.10.2.1.4`.

Somente unidade `impressions(7)` é aceita. O valor é usado apenas quando há
exatamente um candidato válido.

### 12.7 Papel

Subárvore:

```text
.1.3.6.1.2.1.43.8.2.1
```

Colunas utilizadas:

- unidade: coluna 8;
- capacidade máxima: coluna 9;
- nível atual: coluna 10.

Uma bandeja é mensurável somente com unidade `sheets(8)`, capacidade positiva
e nível não negativo. O percentual agregado é:

```text
soma(currentLevel) × 100 / soma(maxCapacity)
```

Todas as bandejas encontradas precisam ser mensuráveis. Valores especiais
negativos não são convertidos em zero.

### 12.8 Drum ou imaging unit

Subárvore:

```text
.1.3.6.1.2.1.43.11.1.1
```

O drum é identificado pelo tipo `opc/photoconductor(9)`. Para unidade
`percent(19)`, usa o percentual válido. Para unidade `impressions(7)`, calcula:

```text
level × 100 / maxCapacity
```

Exige exatamente um candidato válido.

### 12.9 Toners

O módulo considera apenas supplies do tipo `toner(3)` ou
`tonerCartridge(21)`. A cor é resolvida correlacionando o supply com a tabela de
colorants:

```text
.1.3.6.1.2.1.43.12
```

Somente `black`, `cyan`, `magenta` e `yellow` são aceitos. Cada cor precisa ter
exatamente um candidato. C/M/Y permanecem indisponíveis em impressoras
monocromáticas.

### 12.10 Indisponibilidade

Na coleta interna, toner, papel e drum usam `-1` como sentinela. Na
serialização, sentinelas, `N/A`, vazios e percentuais inválidos tornam-se
JSON null.

Limitação conhecida: uma impressora offline recebe uptime interno `"0"`, que
é serializado como string, e não como null.

### 12.11 Score e alertas

- impressora offline: redução de 20 pontos;
- toner preto entre 0% e 10%: redução de 10 pontos.

Toners coloridos baixos não reduzem atualmente o score do core.

## 13. Relatórios

### 13.1 TXT

```text
/var/log/sysguardian/report_YYYYMMDD_HHMMSS.txt
```

Contém hostname, data, score, classificação e todos os eventos coletados.

### 13.2 HTML

```text
/var/log/sysguardian/report_YYYYMMDD_HHMMSS.html
```

Contém resumo, scores por categoria e eventos com formatação visual.

### 13.3 PDF técnico do diagnóstico

```text
/var/log/sysguardian/report_YYYYMMDD_HHMMSS.pdf
```

Esse PDF é uma conversão do relatório HTML feita pelo core com
`wkhtmltopdf`. Ele cobre o diagnóstico geral do servidor.

Se `wkhtmltopdf` não existir, TXT, HTML e JSON continuam sendo gerados, mas o
PDF técnico não é criado.

### 13.4 JSON

```text
/var/log/sysguardian/report_YYYYMMDD_HHMMSS.json
```

Estrutura de alto nível:

```json
{
  "metadata": {},
  "category_scores": {},
  "entries": [],
  "printers": {
    "summary": {},
    "devices": []
  }
}
```

### 13.5 Relatório Gerencial de Impressoras em PDF

Esse é um documento diferente do PDF técnico. Ele é gerado sob demanda pelo
dashboard, usando TCPDF, e se destina à conferência contratual das impressoras
da ESMU/UEMG.

O documento não é gravado automaticamente em `/var/log/sysguardian`; é
retornado ao navegador com `Content-Disposition: inline`.

### 13.6 Retenção

Embora `LOG_RETENTION_DAYS=30` exista, não há limpeza automática implementada.
O administrador precisa acompanhar o consumo de disco. Uma política oficial
de remoção manual é **NÃO CONFIRMADO NO CÓDIGO**.

### 13.7 Log de diagnóstico

O caminho `diagnostic_YYYYMMDD_HHMMSS.log` é declarado pelo core, mas o
arquivo não é escrito atualmente.

## 14. Dashboard

### 14.1 Visão geral

Apresenta score geral, scores por categoria, radar, distribuição de alertas e
eventos relevantes.

### 14.2 Alertas

Exibe entradas com nível `WARN` ou `ERROR`.

### 14.3 Linha do tempo

A rota `#history` apresenta os `entries` do relatório atual. Ela não consulta
uma série histórica de arquivos.

### 14.4 Impressoras

A rota `#printers` consome `printers.devices[]` quando disponível. Relatórios
antigos continuam compatíveis por meio do parser legado baseado em `entries`.

Campos indisponíveis aparecem como `N/D`. MAC, datas e total de páginas são
formatados apenas para apresentação.

### 14.5 Configurações visuais

Tema e intervalo de atualização são mantidos em `localStorage` do navegador.

### 14.6 Atualização de dados

Existe botão de atualização manual. A atualização automática pode ser
configurada para:

```text
OFF, 30, 60, 120 ou 300 segundos
```

A API tem timeout de dez segundos e usa `cache: no-store`.

## 15. Relatório gerencial de impressoras

### 15.1 Conteúdo

O PDF inclui:

- SysGuardian, UEMG e Unidade ESMU;
- host, auditoria, geração e competência;
- total, online, offline e alertas;
- tabela para conferência contratual;
- ficha individual de cada impressora;
- toner preto e C/M/Y quando reais;
- papel e drum quando mensuráveis;
- campos indisponíveis como `N/D`;
- rodapé com data e página;
- responsável, assinatura e data.

### 15.2 Geração no dashboard

1. acesse a rota de Impressoras;
2. confira se o dashboard carregou o relatório esperado;
3. selecione **Relatório PDF**;
4. o documento será aberto em nova aba;
5. use o visualizador do navegador para conferir, imprimir ou salvar.

A URL pública do dashboard é **NÃO CONFIRMADO NO CÓDIGO**.

### 15.3 Seleção da fonte

O dashboard e o PDF compartilham o seletor de relatório. Ele escolhe o maior
timestamp nominal não futuro em um nome válido
`report_YYYYMMDD_HHMMSS.json`. Se nenhum arquivo nominal não futuro existir,
usa `filemtime` como fallback seguro entre os JSONs legíveis.

### 15.4 Procedimento mensal oficial

O SysGuardian continua executando diariamente às **07:00** e **19:00**.

No **último dia de cada mês, após a execução das 07:00**, a TI da Unidade
deve:

1. acessar o Dashboard;
2. conferir os dados das impressoras;
3. gerar o Relatório Gerencial de Impressoras;
4. preencher e assinar o campo de responsável;
5. enviar o relatório para:

```text
impressoras@uemg.br
```

A finalidade é permitir a conferência e auditoria do contrato com a Simpress
pela Gestão de Contratos da GTIC/UEMG.

Esse procedimento é administrativo e não altera o timer. A execução das
19:00 continua normalmente no último dia do mês. Não existe envio automático
de e-mail.

## 16. Administração

### 16.1 Localização dos arquivos

```bash
ls -la /usr/share/sysguardian
ls -la /etc/sysguardian
ls -la /var/log/sysguardian
```

### 16.2 Verificação dos relatórios

Os nomes contêm data e hora. Para verificar a presença dos JSONs:

```bash
find /var/log/sysguardian -maxdepth 1 -type f \
  -name 'report_*.json' -print
```

### 16.3 Verificação do timer

```bash
systemctl is-active sysguardian.timer
systemctl status sysguardian.timer
systemctl list-timers sysguardian.timer
```

### 16.4 Verificação do serviço

```bash
systemctl status sysguardian.service
journalctl -u sysguardian.service --no-pager
```

### 16.5 Espaço em disco

Como a retenção não é aplicada automaticamente, acompanhe o filesystem que
contém `/var/log/sysguardian`. Limites e procedimento de exclusão oficial são
**NÃO CONFIRMADO NO CÓDIGO**.

## 17. Atualização

### 17.1 Upgrade pelo instalador

Executar novamente:

```bash
sudo ./install.sh
```

faz o instalador reconhecer a instalação existente como `upgrade`.

### 17.2 Comportamento do upgrade

- sobrescreve core, módulos, bibliotecas e unidades systemd;
- recria o launcher;
- recarrega e mantém o timer ativo;
- faz backup de `sysguardian.conf`;
- preserva `sysguardian.conf` e `printers.conf` existentes;
- não faz backup automático de `printers.conf`;
- não atualiza nem publica o dashboard.

### 17.3 Obtenção da nova versão

Branch oficial, `git fetch`, `git pull`, tags, releases, rollback e janela de
manutenção são **NÃO CONFIRMADO NO CÓDIGO**. Não execute uma atualização de
produção sem procedimento aprovado para obter e validar a versão correta.

## 18. Troubleshooting

### 18.1 Configuração principal ausente

Sintoma:

```text
ERRO: Arquivo de configuração não encontrado.
```

Verifique:

```bash
ls -l /etc/sysguardian/sysguardian.conf
```

### 18.2 Falta de permissão nos relatórios

Sintoma:

```text
Sem permissão de escrita em /var/log/sysguardian
```

Confirme o usuário de execução e as permissões do diretório. A política
oficial de proprietário/grupo é **NÃO CONFIRMADO NO CÓDIGO**.

### 18.3 Timer inativo

```bash
systemctl status sysguardian.timer
systemctl list-timers sysguardian.timer
journalctl -u sysguardian.timer --no-pager
```

O instalador considera falha quando o timer não fica ativo.

### 18.4 Falha no serviço

```bash
systemctl status sysguardian.service
journalctl -u sysguardian.service --no-pager
```

Confirme também:

```bash
ls -l /usr/local/bin/sysguardian
ls -l /usr/share/sysguardian/sysguardian
```

### 18.5 Impressora offline

Verifique:

- IP ou hostname em `printers.conf`;
- community, versão, porta, timeout e retries;
- conectividade entre servidor e impressora;
- SNMP habilitado no equipamento;
- disponibilidade de `snmpget` e `snmpwalk`;
- resposta da consulta escalar documentada no capítulo 12.

O módulo suprime o erro detalhado do cliente SNMP. Ausência do comando e
ausência de resposta podem resultar no mesmo status offline.

### 18.6 Dados SNMP como N/D

`N/D` pode significar:

- OID não implementado pelo equipamento;
- resposta vazia;
- `No Such Object` ou `No Such Instance`;
- valor especial negativo;
- mais de um candidato sem critério seguro;
- bandeja não mensurável;
- formato de firmware não reconhecido.

Não substitua N/D por zero sem confirmar que zero é uma leitura real.

### 18.7 API sem relatório

`latest.php` responde HTTP 404 quando não encontra JSON legível. Verifique a
existência de `report_*.json` e a permissão de leitura do processo PHP.

### 18.8 Dashboard sem dados

Use as ferramentas de desenvolvedor do navegador para verificar:

- erro HTTP em `api/latest.php`;
- JSON inválido;
- timeout de dez segundos;
- erro de JavaScript ES Module;
- caminho relativo incorreto por publicação web inadequada.

A interface registra erros no console, mas não possui toast operacional
implementado.

### 18.9 PDF gerencial com erro

O endpoint responde com mensagem controlada quando:

- TCPDF está ausente ou ilegível;
- não há relatório;
- o JSON é inválido;
- `metadata`, `printers` ou `printers.devices` estão ausentes.

Confirme o caminho:

```bash
ls -l /usr/share/php/tcpdf/tcpdf.php
```

### 18.10 PDF técnico ausente

O core registra que o PDF não foi gerado quando `wkhtmltopdf` não existe.
TXT, HTML e JSON continuam disponíveis.

### 18.11 MySQL sem métricas

O core distingue erros de autenticação e informa que são necessários
privilégios adequados. A configuração oficial de credenciais MySQL é **NÃO
CONFIRMADO NO CÓDIGO**.

## 19. Desinstalação

### 19.1 Execução

```bash
sudo ./uninstall.sh
```

> **Aviso:** o desinstalador para e desabilita o timer e pode remover
> configurações e todos os relatórios. Leia cada confirmação antes de
> responder.

### 19.2 Fluxo

O desinstalador:

1. exige root;
2. verifica a instalação;
3. executa `systemctl disable --now sysguardian.timer`;
4. remove service e timer;
5. executa `systemctl daemon-reload`;
6. remove o launcher;
7. remove core, módulos e bibliotecas;
8. pergunta sobre configurações;
9. pergunta sobre relatórios;
10. valida a remoção do comando.

### 19.3 Preservação de configuração

Se o operador recusar a remoção, `/etc/sysguardian` é preservado. Se aceitar,
o script remove explicitamente apenas `sysguardian.conf`; `printers.conf`
permanece, e o diretório tende a continuar por não estar vazio.

### 19.4 Preservação de relatórios

Se o operador recusar, `/var/log/sysguardian` é preservado. Se aceitar, o
diretório inteiro é removido recursivamente.

### 19.5 Dashboard

O desinstalador não remove o dashboard, pois sua publicação não é gerenciada
pelos scripts do projeto.

## 20. Validação e testes

### 20.1 Sintaxe Bash

```bash
bash -n src/sysguardian
bash -n modules/printers.sh
bash -n install.sh
bash -n uninstall.sh
```

Quando `shellcheck` estiver disponível:

```bash
shellcheck modules/printers.sh
```

### 20.2 Sintaxe PHP

```bash
php -l dashboard/api/latest.php
php -l dashboard/api/report-source.php
php -l dashboard/api/printers-report.php
```

### 20.3 Systemd

```bash
systemd-analyze verify \
  packaging/systemd/sysguardian.service \
  packaging/systemd/sysguardian.timer
```

### 20.4 Teste existente

```bash
./tests/test_printers.sh
```

Esse teste valida sintaxe, carregamento do módulo e inventário vazio. Não faz
consulta SNMP real.

### 20.5 Cobertura inexistente

Não há testes automatizados versionados para:

- parsing SNMP real;
- serialização JSON;
- dashboard;
- APIs PHP;
- PDF gerencial;
- instalador e upgrade;
- systemd;
- desinstalador.

## 21. Limitações conhecidas

1. O instalador não publica o dashboard.
2. Dependências não são instaladas automaticamente.
3. `CHECK_*` não habilita ou desabilita diagnósticos.
4. `GENERATE_*` não controla formatos.
5. `LOG_RETENTION_DAYS` não é aplicado.
6. `MIN_SCORE_WARNING` e `MIN_SCORE_CRITICAL` não são usados.
7. `diagnostic_*.log` é declarado, mas não escrito.
8. `DISCOVERY` e `LOG_LEVEL` das impressoras não são usados.
9. Uptime de impressora offline é serializado como `"0"`.
10. Alertas de toner colorido não reduzem o score.
11. A página Histórico não agrega vários relatórios.
12. O desinstalador não remove explicitamente `printers.conf`.
13. O upgrade não atualiza o dashboard.
14. O README e `docs/PR006-Technical.md` estão desatualizados.
15. A cobertura automatizada é limitada.
16. URL, HTTPS e autenticação do dashboard são **NÃO CONFIRMADO NO
    CÓDIGO**.
17. Não existe envio automático do relatório mensal.

## 22. Referência técnica

### 22.1 Estrutura de `printers.summary`

```json
{
  "printers": {
    "summary": {
      "total": 8,
      "online": 8,
      "offline": 0,
      "warnings": 0,
      "generated_at": "2026-08-10T12:22:35-03:00"
    }
  }
}
```

Os valores acima são apenas um exemplo de tipos e estrutura.

### 22.2 Estrutura de `printers.devices[]`

```json
{
  "name": "HP_EXEMPLO",
  "ip": "192.0.2.10",
  "status": "online",
  "response_ms": 250,
  "model": "Modelo informado por SNMP",
  "firmware": null,
  "serial": "SERIAL-EXEMPLO",
  "mac": "00 11 22 33 44 55",
  "location": null,
  "description": "Descrição informada por SNMP",
  "uptime": "1 day, 02:03:04.00",
  "total_pages": 12345,
  "toner": {
    "black": 80,
    "cyan": null,
    "magenta": null,
    "yellow": null
  },
  "paper": {
    "percent": null
  },
  "drum": {
    "percent": null
  },
  "errors": [],
  "last_collection": "2026-08-10T12:22:35-03:00"
}
```

Os valores são ilustrativos; o sistema não deve inventar valores ausentes.

### 22.3 Principais OIDs SNMP

| Finalidade | OID ou subárvore |
|---|---|
| Descrição | `.1.3.6.1.2.1.1.1.0` |
| Uptime | `.1.3.6.1.2.1.1.3.0` |
| Localização | `.1.3.6.1.2.1.1.6.0` |
| Modelo | `.1.3.6.1.2.1.25.3.2.1.3.1` |
| Serial | `.1.3.6.1.2.1.43.5.1.1.17.1` |
| Interfaces/MAC | `.1.3.6.1.2.1.2.2.1` |
| Contadores | `.1.3.6.1.2.1.43.10.2.1` |
| Bandejas | `.1.3.6.1.2.1.43.8.2.1` |
| Consumíveis | `.1.3.6.1.2.1.43.11.1.1` |
| Colorants | `.1.3.6.1.2.1.43.12` |

### 22.4 Categorias de score

```text
Hardware CPU Memory Disks SMART Network System Security Backup
Docker Apache PHP MySQL LVM TRIM Logs Printers
```

Classificação:

```text
90–100  EXCELENTE
75–89   BOM
60–74   REGULAR
40–59   RUIM
0–39    CRÍTICO
```

### 22.5 Respostas HTTP relevantes

| Endpoint | Situação | Resposta |
|---|---|---|
| `api/latest.php` | Relatório encontrado | JSON UTF-8 |
| `api/latest.php` | Nenhum JSON legível | HTTP 404 |
| `api/printers-report.php` | Sucesso | PDF inline |
| `api/printers-report.php` | Nenhum relatório | HTTP 404 |
| `api/printers-report.php` | TCPDF ou JSON inválido | HTTP 500 controlado |

### 22.6 Unidades systemd

```text
sysguardian.service
sysguardian.timer
```

Horários oficiais:

```text
Todos os dias às 07:00
Todos os dias às 19:00
```
