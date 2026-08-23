# Controle de Monitores

Script AutoHotkey v2 para controle de monitores em notebooks com tela externa. Permite ligar/desligar monitores via atalhos de teclado ou menu do system tray.

## Funcionalidades

- **Atalhos de teclado** para controle rápido
- **Menu system tray** organizado com opções completas
- **Iniciar com o Windows** (toggle via menu)
- **Controle DDC/CI** para monitores externos
- **Alternância inteligente** entre monitores

## Atalhos

| Atalho | Ação |
|--------|------|
| `Ctrl + Shift + 1` | Ativa/Desativa tela do notebook |
| `Ctrl + Shift + 2` | Liga/Desliga monitor externo (DDC/CI) |
| `Ctrl + Shift + 3` | Alternância inteligente (sincroniza ou alterna ambos) |

## Requisitos

- Windows 10/11
- [AutoHotkey v2.0](https://www.autohotkey.com/) (para executar o script)
- Monitor externo com suporte a DDC/CI (para controle via software)

## Instalação

### Opção 1: Executar o script

1. Instale o [AutoHotkey v2.0](https://www.autohotkey.com/)
2. Baixe o arquivo `src/ControleMonitor.ahk`
3. Clique duas vezes para executar

### Opção 2: Compilar para .exe

1. Instale o [AutoHotkey v2.0](https://www.autohotkey.com/)
2. Use o compilador do AutoHotkey para gerar um executável
3. O executável não depende da instalação do AutoHotkey

## Uso

### Menu System Tray

Após executar o script, um ícone aparecerá no system tray (próximo ao relógio). Clique com o botão direito para acessar:

- **Monitor interno (notebook)**: Ativar/Desativar tela
- **Monitor externo (HDMI / DDC/CI)**: Ligar/Desligar
- **Recarregar monitores**: Atualiza detecção de monitores
- **Iniciar com o Windows**: Ativa/desativa inicialização automática
- **Ajuda**: Exibe instruções de uso

### Iniciar com o Windows

Para configurar o script para iniciar automaticamente com o Windows:

1. Clique com o botão direito no ícone do system tray
2. Selecione "Iniciar com o Windows"
3. O item ficará marcado quando ativado

## Observações

- Alguns monitores não voltam a ligar via software em certos modos de economia de energia
- Se o monitor não ligar, pressione e segure o botão físico de ligar do monitor por alguns segundos até ele voltar
- O script usa a API DDC/CI do Windows para controlar monitores externos

## Estrutura do Projeto

```
controle-monitor/
├── src/
│   └── ControleMonitor.ahk    # Script principal
├── docs/
│   └── screenshots/           # Capturas de tela (opcional)
├── .gitignore
├── LICENSE
└── README.md
```

## Licença

Este projeto está licenciado sob a Licença MIT - veja o arquivo [LICENSE](LICENSE) para detalhes.
