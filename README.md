# SysGuardian

![Version](https://img.shields.io/badge/version-6.3.0-blue)
![Platform](https://img.shields.io/badge/platform-Ubuntu%2022.04%20%7C%2024.04-orange)
![License](https://img.shields.io/badge/license-MIT-green)

## Sobre

SysGuardian é uma ferramenta profissional de diagnóstico, auditoria e verificação de integridade para servidores Linux.

Foi desenvolvida para fornecer uma visão completa da saúde do sistema através de um único comando.

O objetivo do projeto é simplificar a administração de servidores Ubuntu, oferecendo diagnósticos rápidos, relatórios detalhados e verificações de segurança.

---

## Recursos

- Diagnóstico completo do sistema
- Informações do Kernel
- CPU
- Memória RAM
- Swap
- Discos
- SMART
- LVM
- Rede
- Firewall (UFW)
- Fail2Ban
- AppArmor
- Auditd
- Apache
- PHP
- MySQL
- Docker
- Backups
- Logs do Journal
- Relatórios TXT
- Relatórios HTML
- Relatórios PDF

---

## Compatibilidade

- Ubuntu 22.04 LTS
- Ubuntu 24.04 LTS

---

## Instalação

```bash
sudo ./install.sh
```

---

## Execução

```bash
sudo sysguardian
```

ou

```bash
sudo ./src/sysguardian
```

---

## Estrutura

```
SysGuardian/
├── src/
├── config/
├── modules/
├── lib/
├── docs/
├── templates/
├── tests/
├── install.sh
├── uninstall.sh
├── README.md
├── CHANGELOG.md
├── VERSION
└── LICENSE
```

---

## Roadmap

### v7.0

- Estrutura do projeto
- Instalador
- Configuração
- Organização do código

### v7.1

- Bibliotecas
- Modularização

### v7.2

- CLI

### v8.0

- Plugins

### v9.0

- Pacote .deb

---

## Licença

MIT License.
