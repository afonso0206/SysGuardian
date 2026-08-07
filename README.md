# SysGuardian

![Version](https://img.shields.io/badge/version-6.3.0-blue)
![Platform](https://img.shields.io/badge/platform-Ubuntu%2022.04%20%7C%2024.04-orange)
![License](https://img.shields.io/badge/license-MIT-green)

> ⚠️ **Status:** Em desenvolvimento ativo (Roadmap da versão 7.x).

---

# Sobre

O **SysGuardian** é uma ferramenta profissional de diagnóstico, auditoria e monitoramento da saúde de servidores Linux.

Seu objetivo é fornecer uma visão completa do ambiente através de um único comando, auxiliando administradores de sistemas na identificação de problemas, análise de desempenho, verificação de segurança e geração de relatórios técnicos.

O projeto foi desenvolvido priorizando:

- Simplicidade
- Confiabilidade
- Compatibilidade
- Organização
- Facilidade de manutenção

---

# Características

- Desenvolvido inteiramente em Bash
- Compatível com Ubuntu LTS
- Baixo consumo de recursos
- Não depende de banco de dados
- Fácil instalação
- Arquitetura modular (Roadmap 7.x)
- Código aberto
- Licença MIT

---

# Recursos

Atualmente o SysGuardian realiza verificações de:

- Sistema Operacional
- Kernel Linux
- Boot do sistema
- Tempo de inicialização
- CPU
- Memória RAM
- Swap
- Discos
- SMART
- LVM
- Rede
- Interfaces
- Gateway
- DNS
- Firewall (UFW)
- Fail2Ban
- AppArmor
- Auditd
- Apache
- PHP
- MySQL
- Docker
- Backups
- TRIM
- Logs do Journal
- Ambiente Gráfico (GNOME)

Também gera automaticamente:

- Relatório TXT
- Relatório HTML
- Relatório PDF
- Pontuação geral da saúde do servidor

---

# Compatibilidade

Sistemas suportados:

- Ubuntu 22.04 LTS
- Ubuntu 24.04 LTS

Arquiteturas:

- x86_64

---

# Instalação

Clone o projeto:

```bash
git clone https://github.com/afonso0206/SysGuardian.git
```

Entre no diretório:

```bash
cd SysGuardian
```

Execute:

```bash
sudo ./install.sh
```

---

# Utilização

Após instalado:

```bash
sudo sysguardian
```

Ou execute diretamente:

```bash
sudo ./src/sysguardian
```

---

# Dependências

O SysGuardian utiliza ferramentas presentes no Ubuntu.

Alguns recursos opcionais utilizam:

- smartmontools
- docker
- apache2
- mysql-server
- php
- lvm2

Caso algum componente não esteja instalado, o diagnóstico continuará normalmente, apenas informando que aquele recurso não pôde ser verificado.

---

# Estrutura do Projeto

```
SysGuardian/
├── src/
│   └── sysguardian
├── config/
│   └── sysguardian.conf
├── modules/
├── lib/
├── docs/
├── tests/
├── scripts/
├── packaging/
├── assets/
├── .github/
├── install.sh
├── uninstall.sh
├── README.md
├── CHANGELOG.md
├── VERSION
└── LICENSE
```

---

# Roadmap

## Versão 7.0

- Estrutura profissional
- Instalador
- Desinstalador
- Configuração centralizada
- Organização do código

---

## Versão 7.1

- Bibliotecas compartilhadas
- Modularização do código
- Melhorias internas

---

## Versão 7.2

- Interface de linha de comando

Exemplo:

```bash
sysguardian check
sysguardian report
sysguardian cpu
sysguardian apache
sysguardian php
```

---

## Versão 8.0

- Sistema de Plugins
- API interna
- Extensões

---

## Versão 9.0

- Pacote Debian (.deb)
- Bash Completion
- Página MAN
- GitHub Actions
- Releases automáticos

---

# Contribuindo

Contribuições são sempre bem-vindas.

Caso deseje colaborar:

1. Faça um Fork do projeto.
2. Crie uma branch para sua alteração.
3. Realize os testes.
4. Envie um Pull Request.

Problemas e sugestões podem ser registrados através das **Issues** do GitHub.

---

# Autor

**Afonso**

Administrador de Sistemas Linux e idealizador do projeto **SysGuardian**.

Projeto iniciado em **2026**.

---

# Licença

Este projeto está licenciado sob a **MIT License**.

Consulte o arquivo **LICENSE** para mais informações.
