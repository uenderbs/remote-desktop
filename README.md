# Controle de Monitores

Script para controle de monitores em notebooks com tela externa. Permite ligar/desligar monitores via atalhos de teclado ou menu do system tray.

## Funcionalidades

- **Atalhos de teclado** para controle rápido
- **Menu system tray** organizado com opções completas
- **Iniciar com o sistema operacional** (toggle via menu)
- **Controle DDC/CI** para monitores externos
- **Alternância inteligente** entre monitores
- **Compatível com Windows e Linux**

## Atalhos

| Atalho | Ação |
|--------|------|
| `Ctrl + Shift + 1` | Ativa/Desativa tela do notebook |
| `Ctrl + Shift + 2` | Liga/Desliga monitor externo (DDC/CI) |
| `Ctrl + Shift + 3` | Alternância inteligente (sincroniza ou alterna ambos) |

## Requisitos

### Windows

- Windows 10/11
- [AutoHotkey v2.0](https://www.autohotkey.com/) (para executar o script)
- Monitor externo com suporte a DDC/CI (para controle via software)

### Linux

- Distribuição Linux com X11 ou Wayland
- `xrandr` (geralmente pré-instalado)
- `ddcutil` (para controle DDC/CI em monitores externos)
- Dependências:
  ```bash
  # Debian/Ubuntu
  sudo apt install x11-xserver-utils ddcutil

  # Arch Linux
  sudo pacman -S xorg-xrandr ddcutil

  # Fedora
  sudo dnf install xorg-x11-server-Xrandr ddcutil
  ```

## Instalação

### Windows

#### Opção 1: Executar o script

1. Instale o [AutoHotkey v2.0](https://www.autohotkey.com/)
2. Baixe o arquivo `src/ControleMonitor.ahk`
3. Clique duas vezes para executar

#### Opção 2: Compilar para .exe

1. Instale o [AutoHotkey v2.0](https://www.autohotkey.com/)
2. Use o compilador do AutoHotkey para gerar um executável
3. O executável não depende da instalação do AutoHotkey

### Linux

#### Instalação manual

1. Copie o script para um local permanente:
   ```bash
   mkdir -p ~/.local/bin
   cp src/controle-monitor.sh ~/.local/bin/
   chmod +x ~/.local/bin/controle-monitor.sh
   ```

2. Para iniciar automaticamente com o sistema, adicione ao seu `~/.xinitrc` ou configure no gerenciador de inicialização do seu desktop environment.

#### Configuração DDC/CI no Linux

Para controlar monitores externos via DDC/CI no Linux:

1. Adicione seu usuário ao grupo `i2c`:
   ```bash
   sudo usermod -aG i2c $USER
   ```

2. Carregue o módulo `i2c-dev`:
   ```bash
   sudo modprobe i2c-dev
   ```

3. Para carregar automaticamente na inicialização:
   ```bash
   echo "i2c-dev" | sudo tee /etc/modules-load.d/i2c.conf
   ```

4. Reinicie o sistema

## Uso

### Windows - Menu System Tray

Após executar o script, um ícone aparecerá no system tray (próximo ao relógio). Clique com o botão direito para acessar:

- **Monitor interno (notebook)**: Ativar/Desativar tela
- **Monitor externo (HDMI / DDC/CI)**: Ligar/Desligar
- **Recarregar monitores**: Atualiza detecção de monitores
- **Iniciar com o Windows**: Ativa/desativa inicialização automática
- **Ajuda**: Exibe instruções de uso

### Windows - Iniciar com o Windows

Para configurar o script para iniciar automaticamente com o Windows:

1. Clique com o botão direito no ícone do system tray
2. Selecione "Iniciar com o Windows"
3. O item ficará marcado quando ativado

### Linux

Execute o script:
```bash
~/.local/bin/controle-monitor.sh
```

O script ficará em segundo plano e responderá aos atalhos de teclado.

## Comandos Linux

O script Linux suporta os seguintes comandos via terminal:

```bash
# Listar monitores disponíveis
xrandr --listmonitors

# Ativar monitor interno
xrandr --output eDP-1 --auto

# Desativar monitor interno
xrandr --output eDP-1 --off

# Ativar monitor externo
xrandr --output HDMI-1 --auto

# Desativar monitor externo
xrandr --output HDMI-1 --off

# Configurar disposition (estendido)
xrandr --output eDP-1 --auto --output HDMI-1 --auto --right-of eDP-1

# Configurar disposition (espelho)
xrandr --output eDP-1 --auto --output HDMI-1 --same-as eDP-1
```

## Solução de Problemas

### Windows

- **Monitor não liga via DDC/CI**: Alguns monitores não voltam a ligar via software em certos modos de economia de energia. Pressione e segure o botão físico de ligar do monitor por alguns segundos até ele voltar.
- **Script não inicia com o Windows**: Verifique se a opção está marcada no menu do system tray.

### Linux

- **xrandr não funciona**: Verifique se o X11 está rodando com `echo $XDG_SESSION_TYPE`
- **ddcutil não detecta monitor**: Verifique se o módulo `i2c-dev` está carregado com `lsmod | grep i2c`
- **Permissão negada para DDC/CI**: Execute `sudo ddcutil detect` para testar
- **Monitor externo não é listado**: Execute `xrandr --listmonitors` para ver todos os monitores detectados

## Estrutura do Projeto

```
controle-monitor/
├── src/
│   ├── ControleMonitor.ahk    # Script principal (Windows)
│   └── controle-monitor.sh    # Script principal (Linux)
├── docs/
│   └── screenshots/           # Capturas de tela (opcional)
├── .gitignore
├── LICENSE
└── README.md
```

## Tecnologias Utilizadas

### Windows
- **AutoHotkey v2.0**: Linguagem de script para automação no Windows
- **API DDC/CI**: Protocolo de comunicação com monitores
- **API Windows Display**: `DisplaySwitch.exe` para controle de tela

### Linux
- **Bash**: Shell script para automação
- **xrandr**: Ferramenta de configuração de display
- **ddcutil**: Ferramenta para comunicação DDC/CI no Linux

## Contribuição

1. Fork o projeto
2. Crie uma branch para sua feature (`git checkout -b feature/nova-feature`)
3. Commit suas mudanças (`git commit -m 'Adiciona nova feature'`)
4. Push para a branch (`git push origin feature/nova-feature`)
5. Abra um Pull Request

## Licença

Este projeto está licenciado sob a Licença MIT - veja o arquivo [LICENSE](LICENSE) para detalhes.

## Declaração de Uso de Inteligência Artificial

Este projeto foi desenvolvido com assistência de inteligência artificial. As seguintes ferramentas e modelos foram utilizados:

### Ferramentas de IA

- **opencode**: Interface de linha de comando para assistência de desenvolvimento
  - Modelo: `opencode/mimo-v2.5-free`
  - Uso: Organização do código, criação de documentação, estruturação do projeto

### Modelos de IA Utilizados

- **Mimo v2.5 Free**: Modelo de linguagem para geração e revisão de código
  - Versão: mimo-v2.5-free
  - Provedor: opencode
  - Uso: Análise de código, sugestões de melhoria, criação de README

### Escopo da Assistência

A IA foi utilizada para:
- Revisão e organização do código existente
- Criação da documentação completa (README)
- Configuração do repositório Git
- Sugestões de estrutura de pastas
- Implementação de compatibilidade Linux

O código fonte original foi desenvolvido por um humano, com assistência da IA para melhorias e documentação.
