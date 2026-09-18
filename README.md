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
| `Ctrl + Alt + 1` | Ativa/Desativa tela do notebook |
| `Ctrl + Alt + 2` | Liga/Desliga monitor externo (DDC/CI) |
| `Ctrl + Alt + 3` | Alternância inteligente (sincroniza ou alterna ambos) |

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

### Linux - Interface Grafica (System Tray)

1. Instale as dependencias:
   ```bash
   # Debian/Ubuntu
   sudo apt install python3-gi gir1.2-ayatanaappindicator3-0.1

   # Arch Linux
   sudo pacman - python-gobject libayatana-appindicator

   # Fedora
   sudo dnf install python3-gobject ayatana-appindicator3-gtk3
   ```

2. Execute o script:
   ```bash
   python3 src/tray-icon.py
   ```

3. Um icone de monitor aparecera na bandeja do sistema (proximo ao relogio). Clique com o botao direito para acessar o menu.

### Linux - Linha de Comando

Execute o script bash:
```bash
~/.local/bin/controle-monitor.sh
```

O script ficara em segundo plano e respondera aos atalhos de teclado.

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
│   ├── controle-monitor.sh    # Script principal (Linux - CLI)
│   ├── tray-icon.py           # Interface grafica (Linux - System Tray)
│   ├── monitor-icon.svg       # Icone do monitor (vetorial)
│   └── monitor-icon.png       # Icone do monitor (raster)
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
- **Bash**: Shell script para automação (CLI)
- **Python 3**: Interface grafica com system tray
- **AyatanaAppIndicator3**: Indicador de bandeja do sistema
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

### Windows (Script AutoHotkey)

- **GPT-5.5**: Modelo de linguagem para desenvolvimento do script principal
  - Provedor: OpenAI
  - Uso: Desenvolvimento completo do script `ControleMonitor.ahk`, incluindo:
    - Controle DDC/CI para monitores externos
    - Atalhos de teclado
    - Menu system tray
    - Alternância inteligente entre monitores
    - Inicialização com o Windows

### Linux (Script Bash)

- **opencode**: Interface de linha de comando para assistência de desenvolvimento
  - Modelo: `opencode/mimo-v2.5-free`
  - Uso: Criação do script `controle-monitor.sh` com funcionalidades equivalentes

### Organização e Documentação

- **opencode**: Interface de linha de comando para assistência de desenvolvimento
  - Modelo: `opencode/mimo-v2.5-free`
  - Uso: Organização do código, criação de documentação, estruturação do projeto

### Modelos de IA Utilizados

| Modelo | Provedor | Uso |
|--------|----------|-----|
| GPT-5.5 | OpenAI | Desenvolvimento do script Windows (AutoHotkey) |
| Mimo v2.5 Free | opencode | Desenvolvimento do script Linux, documentação, organização |

### Escopo da Assistência

**GPT-5.5 (Windows):**
- Desenvolvimento completo do script AutoHotkey v2.0
- Implementação de DDC/CI via API do Windows
- Sistema de atalhos de teclado
- Menu system tray com opções completas
- Alternância inteligente entre monitores
- Suporte a inicialização com o Windows

**Mimo v2.5 Free (Linux e Documentação):**
- Criação do script Bash equivalente para Linux
- Documentação completa (README)
- Configuração do repositório Git
- Estruturação de pastas
- Solução de problemas para ambos os sistemas
