# Changelog

Todas as alterações relevantes do projeto **SysGuardian** serão documentadas neste arquivo.

O projeto segue as recomendações de **Keep a Changelog** e **Semantic Versioning**.

---

## [7.0.0-alpha2] - 2026-08-03

### Added

- Estrutura profissional do projeto
- Biblioteca compartilhada `lib/core.sh`
- Instalador profissional (`install.sh`)
- Desinstalador profissional (`uninstall.sh`)
- Organização modular para futuras versões
- Documentação inicial do projeto

### Changed

- Refatoração completa do instalador
- Integração do instalador com `lib/core.sh`
- Organização da estrutura de diretórios
- Melhorias na documentação (`README.md`)

### Tested

- Ubuntu 22.04 LTS
- Ubuntu 24.04 LTS
- Verificação com `bash -n`
- Verificação com `shellcheck`
- Testes de instalação
- Testes de atualização (upgrade)
- Testes de desinstalação

---

## [6.3.0] - 2026-07-31

### Initial Release

- Primeira versão pública do SysGuardian.
