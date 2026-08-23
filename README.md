# Chrome Remote Desktop — Dual Session for Linux Mint/Cinnamon

Solução para Chrome Remote Desktop (CRD) no Linux Mint com Cinnamon que permite alternar entre **sessão virtual** (Xvfb) e **sessão local** (tela física) via linha de comando.

---

## Sumário

- [Funcionalidades](#funcionalidades)
- [Pré-requisitos](#pré-requisitos)
- [Instalação](#instalação)
- [Uso](#uso)
- [Exemplos](#exemplos)
- [Estrutura do Repositório](#estrutura-do-repositório)
- [Código dos Arquivos](#código-dos-arquivos)
- [Detalhes Técnicos](#detalhes-técnicos)
- [Solução de Problemas](#solução-de-problemas)
- [Desinstalação](#desinstalação)

---

## Funcionalidades

| Recurso | Descrição |
|---------|-----------|
| Modo Virtual | Sessão Cinnamon isolada via Xvfb (display `:20`) |
| Modo Local | Conecta à sessão existente na tela física (display `:0`) |
| Alternância | Troca entre modos com um comando, sem reiniciar manualmente |
| Menu interativo | Sem argumentos, exibe menu numerado |
| Aplicações simultâneas | Mesmo app pode rodar nos dois displays ao mesmo tempo |

---

## Pré-requisitos

### Sistema

| Componente | Versão mínima testada |
|------------|----------------------|
| Linux Mint | 22.x (Wilma/Zena) |
| Ubuntu | 24.04 LTS |
| Cinnamon DE | 6.x |
| Python | 3.x |

### Pacotes

```bash
sudo apt install -y xvfb dbus-x11 python3
```

### Software necessário

- [Google Chrome](https://www.google.com/chrome/)
- [Chrome Remote Desktop](https://remotedesktop.google.com/headless)

### Host registrado

O host CRD deve estar registrado antes da instalação. Acesse:

```
https://remotedesktop.google.com/headless
```

Copie o código e execute:

```bash
/opt/google/chrome-remote-desktop/start-host \
    --code="SEU_CODIGO" \
    --redirect-url="https://remotedesktop.google.com/_/oauthredirect" \
    --name=$(hostname)
```

Anote o caminho do config gerado em:
`~/.config/chrome-remote-desktop/host#XXXXXXXX.json`

---

## Instalação

### Instalador automático

```bash
git clone https://github.com/SEU_USUARIO/remote-desktop.git
cd remote-desktop
sudo ./install.sh
```

O instalador:
1. Detecta automaticamente usuário, UID e config path
2. Aplica o patch no wrapper CRD
3. Instala scripts e serviço systemd
4. Configura sudoers para `crd-mode` sem senha
5. Inicia o serviço

### Instalação manual

```bash
# 1. Aplicar patch
sudo python3 patches/apply-patch.py

# 2. Instalar wrapper
sudo cp scripts/start-crd-clean.sh /opt/google/chrome-remote-desktop/start-active.sh
sudo chmod +x /opt/google/chrome-remote-desktop/start-active.sh

# 3. Instalar comando crd-mode
sudo cp scripts/crd-mode.sh /usr/local/bin/crd-mode
sudo chmod +x /usr/local/bin/crd-mode

# 4. Instalar script de sessão
cp scripts/.chrome-remote-desktop-session ~/
chmod +x ~/.chrome-remote-desktop-session

# 5. Criar serviço systemd (substitua <SEU_USER>)
sudo cp systemd/chrome-remote-desktop.service \
    /etc/systemd/system/chrome-remote-desktop-<SEU_USER>.service
sudo sed -i 's/<YOUR_USERNAME>/<SEU_USER>/g' \
    /etc/systemd/system/chrome-remote-desktop-<SEU_USER>.service

# 6. Iniciar
sudo systemctl daemon-reload
sudo systemctl enable chrome-remote-desktop-<SEU_USER>
sudo systemctl start chrome-remote-desktop-<SEU_USER>
```

---

## Uso

### Comando crd-mode

```
crd-mode            Menu interativo (1, 2, 3)
crd-mode -l         Modo local (display :0)
crd-mode -v         Modo virtual (Xvfb)
crd-mode -t         Alternar local ↔ virtual
crd-mode -s         Status do serviço e modo
crd-mode -h         Ajuda
```

### Menu interativo

```
$ crd-mode

=== CRD ===
Modo atual: VIRTUAL (Xvfb)

1 - Virtual (Xvfb)
2 - Local (display :0)
3 - Status

Escolha:
```

### Status

```
$ crd-mode -s

=== CRD ===
Serviço: active
Modo: LOCAL (display :0)
```

### Gerenciamento do serviço

```bash
sudo systemctl status chrome-remote-desktop-<SEU_USER>
sudo systemctl restart chrome-remote-desktop-<SEU_USER>
sudo systemctl stop chrome-remote-desktop-<SEU_USER>
journalctl -u chrome-remote-desktop-<SEU_USER> -f
```

---

## Exemplos

### Abrir o mesmo programa nos dois displays

Cada display é um servidor X independente. Para rodar o mesmo app em ambos simultaneamente, use `--user-data-dir` separado:

```bash
# Terminal local (tela física — display :0)
DISPLAY=:0 chromium-browser --user-data-dir=/tmp/chrome-local &

# Terminal via CRD (sessão virtual — display :20)
DISPLAY=:20 chromium-browser --user-data-dir=/tmp/chrome-virtual &
```

### Abrir terminal no display remoto

```bash
# Via SSH + CRD virtual
DISPLAY=:20 xterm &

# Via CRD local (conectado à tela física)
DISPLAY=:0 xterm &
```

### Verificar em qual display um app está rodando

```bash
# Listar janelas no display :0 (local)
DISPLAY=:0 xdotool getactivewindow getwindowname

# Listar janelas no display :20 (virtual)
DISPLAY=:20 xdotool getactivewindow getwindowname

# Ver todos os displays ativos
ls /tmp/.X11-unix/
```

### Copiar arquivo entre displays

```bash
# Do virtual para o local
DISPLAY=:20 xclip -selection clipboard -o | DISPLAY=:0 xclip -selection clipboard

# Ou via filesystem
cp /tmp/arquivo.txt ~/Desktop/
```

---

## Estrutura do Repositório

```
remote-desktop/
├── README.md                                    # Este arquivo
├── install.sh                                   # Instalador automatizado
├── patches/
│   ├── apply-patch.py                           # Script de patch do wrapper CRD
│   └── existing-display-support.patch            # Diff do patch
├── scripts/
│   ├── .chrome-remote-desktop-session            # Script de sessão (cinnamon-session)
│   ├── crd-mode.sh                              # Comando crd-mode
│   ├── start-crd-clean.sh                       # Wrapper: sessão virtual (template)
│   └── start-crd-local.sh                       # Wrapper: sessão local (referência)
└── systemd/
    └── chrome-remote-desktop.service             # Template do serviço systemd
```

### Arquivos instalados no sistema

| Arquivo | Destino | Descrição |
|---------|---------|-----------|
| `start-crd-clean.sh` | `/opt/google/chrome-remote-desktop/start-active.sh` | Wrapper do CRD |
| `crd-mode.sh` | `/usr/local/bin/crd-mode` | Comando de alternância |
| `.chrome-remote-desktop-session` | `~/.chrome-remote-desktop-session` | Script de sessão |
| `chrome-remote-desktop.service` | `/etc/systemd/system/chrome-remote-desktop-<user>.service` | Serviço systemd |
| `apply-patch.py` | Executado in-place | Patch no wrapper CRD |

### Arquivos dinâmicos

| Caminho | Descrição |
|---------|-----------|
| `~/.config/crd-session-mode` | Flag de modo (não existe = virtual, `0` = local) |
| `/opt/google/chrome-remote-desktop/chrome-remote-desktop.bak` | Backup do wrapper original |

---

## Código dos Arquivos

### start-active.sh

Wrapper principal do CRD. Limpa variáveis de ambiente do systemd/PAM e executa o wrapper CRD.

```bash
#!/bin/bash
unset DISPLAY GDK_BACKEND WAYLAND_DISPLAY XDG_SESSION_DESKTOP DESKTOP_SESSION XDG_CURRENT_DESKTOP SESSION_MANAGER XDG_SESSION_ID DBUS_SESSION_BUS_ADDRESS

export HOME=<YOUR_USER_HOME>
export USER=<YOUR_USERNAME>
export LOGNAME=<YOUR_USERNAME>
export SHELL=/bin/bash
export PATH=/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin
export XDG_RUNTIME_DIR=/run/user/<YOUR_UID>
export CHROME_REMOTE_DESKTOP_USE_XVFB=1

exec /opt/google/chrome-remote-desktop/chrome-remote-desktop \
    --config=<YOUR_CONFIG_PATH> \
    --start \
    --child-process
```

### .chrome-remote-desktop-session

Script de sessão executado pelo CRD. Inicia o Cinnamon.

```bash
#!/bin/bash
export XDG_SESSION_TYPE=x11
export GDK_BACKEND=x11
export XDG_SESSION_DESKTOP=Cinnamon
export DESKTOP_SESSION=cinnamon
export XDG_CURRENT_DESKTOP=X-Cinnamon
exec cinnamon-session
```

### crd-mode

Comando para alternar entre modos.

```bash
#!/bin/bash
SERVICE="chrome-remote-desktop-<YOUR_USERNAME>"
FLAG="$HOME/.config/crd-session-mode"

current() {
  [ -f "$FLAG" ] && echo "LOCAL (display :0)" || echo "VIRTUAL (Xvfb)"
}

status() {
  echo "=== CRD ==="
  echo "Serviço: $(systemctl is-active "$SERVICE" 2>&1)"
  echo "Modo: $(current)"
}

usage() {
  echo "Uso: crd-mode [opção]"
  echo ""
  echo "Opções:"
  echo "  -l, -local     Conectar à sessão local (display :0)"
  echo "  -v, -virtual   Iniciar sessão virtual (Xvfb)"
  echo "  -t, -toggle    Alternar entre local ↔ virtual"
  echo "  -s, -status    Ver status do serviço e modo atual"
  echo "  -h, -help      Esta ajuda"
  echo ""
  echo "Sem argumentos: menu interativo"
  echo ""
  echo "Modo atual: $(current)"
}

case "${1:-}" in
  -v|-virtual)
    rm -f "$FLAG"
    sudo systemctl restart "$SERVICE"
    echo "Virtual session (Xvfb) ativo."
    ;;
  -l|-local)
    echo "0" > "$FLAG"
    sudo systemctl restart "$SERVICE"
    echo "Local session (display :0) ativo."
    ;;
  -s|-status)
    status
    ;;
  -t|-toggle)
    if [ -f "$FLAG" ]; then
      rm -f "$FLAG"
      sudo systemctl restart "$SERVICE"
      echo "Alternado para Virtual (Xvfb)."
    else
      echo "0" > "$FLAG"
      sudo systemctl restart "$SERVICE"
      echo "Alternado para Local (display :0)."
    fi
    ;;
  -h|-help)
    usage
    ;;
  *)
    echo "=== CRD ==="
    echo "Modo atual: $(current)"
    echo ""
    echo "1 - Virtual (Xvfb)"
    echo "2 - Local (display :0)"
    echo "3 - Status"
    echo ""
    read -p "Escolha: " opt
    case "$opt" in
      1) rm -f "$FLAG"; sudo systemctl restart "$SERVICE"; echo "Virtual session (Xvfb) ativo." ;;
      2) echo "0" > "$FLAG"; sudo systemctl restart "$SERVICE"; echo "Local session (display :0) ativo." ;;
      3) status ;;
      *) echo "Opção inválida."; exit 1 ;;
    esac
    ;;
esac
```

### apply-patch.py

Script que modifica o wrapper CRD para suportar sessão existente.

```python
#!/usr/bin/env python3
import sys, os, shutil, py_compile

CRD_SCRIPT = "/opt/google/chrome-remote-desktop/chrome-remote-desktop"
BACKUP = CRD_SCRIPT + ".bak"

ORIGINAL = '''  def launch_session(self, *args, **kwargs):
    logging.info("Launching X server and X session.")
    super(XDesktop, self).launch_session(*args, **kwargs)'''

PATCHED = '''  def launch_session(self, *args, **kwargs):
    crd_session_mode = os.path.expanduser("~/.config/crd-session-mode")
    if os.path.exists(crd_session_mode):
      with open(crd_session_mode) as f:
        display_num = int(f.read().strip())
      logging.info("Using existing display :%d" % display_num)
      self.child_env["DISPLAY"] = ":%d" % display_num
      self.child_env["XAUTHORITY"] = os.path.expanduser("~/.Xauthority")
      self.server_inhibitor.record_started(MINIMUM_PROCESS_LIFETIME,
                                           args[1] if len(args) > 1 else 0)
      self.session_inhibitor.record_started(MINIMUM_PROCESS_LIFETIME,
                                            args[1] if len(args) > 1 else 0)
    else:
      logging.info("Launching X server and X session.")
      super(XDesktop, self).launch_session(*args, **kwargs)'''

def apply_patch():
    with open(CRD_SCRIPT) as f:
        content = f.read()
    if PATCHED in content:
        print("Already patched.")
        return
    shutil.copy2(CRD_SCRIPT, BACKUP)
    content = content.replace(ORIGINAL, PATCHED, 1)
    with open(CRD_SCRIPT, "w") as f:
        f.write(content)
    py_compile.compile(CRD_SCRIPT, doraise=True)
    print("Patch applied.")

def revert_patch():
    if os.path.exists(BACKUP):
        shutil.copy2(BACKUP, CRD_SCRIPT)
        print("Reverted from backup.")
        return
    with open(CRD_SCRIPT) as f:
        content = f.read()
    content = content.replace(PATCHED, ORIGINAL, 1)
    with open(CRD_SCRIPT, "w") as f:
        f.write(content)
    print("Reverted.")

if __name__ == "__main__":
    revert_patch() if "--revert" in sys.argv else apply_patch()
```

---

## Detalhes Técnicos

### Como funciona

```
crd-mode -v (virtual)
  → Remove ~/.config/crd-session-mode
  → Reinicia serviço systemd
  → start-active.sh executa CRD wrapper
  → CRD wrapper: flag não existe → inicia Xvfb no :20
  → CRD roda .chrome-remote-desktop-session → cinnamon-session

crd-mode -l (local)
  → Cria ~/.config/crd-session-mode com "0"
  → Reinicia serviço systemd
  → start-active.sh executa CRD wrapper
  → CRD wrapper: flag existe → conecta ao display :0
  → CRD roda .chrome-remote-desktop-session → cinnamon-session
```

### Displays

| Display | Tipo | Acesso |
|---------|------|--------|
| `:0` | X11 local (tela física) | Modo local |
| `:20` | Xvfb (virtual) | Modo virtual |

### O que o patch faz

Modifica o método `XDesktop.launch_session()` no wrapper Python do CRD:

1. Verifica se `~/.config/crd-session-mode` existe
2. Se existe → lê o número do display e conecta a ele
3. Se não existe → inicia Xvfb normalmente (comportamento padrão)

### Por que limpar variáveis de ambiente

O systemd via PAM injeta variáveis como `DISPLAY=:0`, `XDG_SESSION_ID`, `DBUS_SESSION_BUS_ADDRESS` que conflitam com a sessão virtual do CRD. O wrapper `start-active.sh` remove essas variáveis antes de executar o CRD.

### Por que `--replace` não funciona

O `cinnamon-session` no Linux Mint 22.x **não suporta** a flag `--replace`. Usar essa flag causa erro e restart em loop.

---

## Solução de Problemas

### CRD não inicia

```bash
# Verificar logs
sudo journalctl -u chrome-remote-desktop-<SEU_USER> -n 50

# Verificar se o patch está aplicado
grep "crd_session_mode" /opt/google/chrome-remote-desktop/chrome-remote-desktop

# Reaplicar patch
sudo python3 patches/apply-patch.py
sudo systemctl restart chrome-remote-desktop-<SEU_USER>
```

### Modo local não conecta à tela

```bash
# Verificar se a flag existe
cat ~/.config/crd-session-mode
# Deve mostrar: 0

# Verificar se o display :0 está ativo
DISPLAY=:0 xdpyinfo | head -5
```

### Modo virtual não inicia Xvfb

```bash
# Verificar se Xvfb está instalado
which Xvfb

# Verificar processos
pgrep -a Xvfb

# Testar manualmente
Xvfb :20 -screen 0 1920x1080x24 &
DISPLAY=:20 xterm
```

### crd-mode pede senha

O instalador configura sudoers automaticamente. Se ainda pede senha:

```bash
# Criar sudoers manualmente
echo "$USER ALL=(ALL) NOPASSWD: /usr/bin/systemctl restart chrome-remote-desktop-$USER, /usr/bin/systemctl start chrome-remote-desktop-$USER, /usr/bin/systemctl stop chrome-remote-desktop-$USER, /usr/bin/systemctl status chrome-remote-desktop-$USER" | sudo tee /etc/sudoers.d/crd-mode
sudo chmod 440 /etc/sudoers.d/crd-mode
```

### Host não conecta ao Google

```bash
# Verificar config
ls -la ~/.config/chrome-remote-desktop/host#*.json
cat ~/.config/chrome-remote-desktop/host#*.json | python3 -m json.tool
```

---

## Desinstalação

```python
# Reverter patch
sudo python3 patches/apply-patch.py --revert

# Remover arquivos
sudo rm /opt/google/chrome-remote-desktop/start-active.sh
sudo rm /usr/local/bin/crd-mode
rm ~/.chrome-remote-desktop-session
rm ~/.config/crd-session-mode
sudo rm /etc/sudoers.d/crd-mode

# Remover serviço
sudo systemctl stop chrome-remote-desktop-<SEU_USER>
sudo systemctl disable chrome-remote-desktop-<SEU_USER>
sudo rm /etc/systemd/system/chrome-remote-desktop-<SEU_USER>.service
sudo systemctl daemon-reload
```

---

## Licença

MIT — Livre para uso e modificação.

---

## Declaração de Uso de IA

Este repositório foi desenvolvido com assistência de inteligência artificial:

- **Modelo**: [opencode/mimo-v2-pro](https://opencode.ai)
- **Ferramenta**: [opencode](https://opencode.ai) — CLI interativo para engenharia de software

### Componentes gerados com IA

| Componente | Descrição |
|------------|-----------|
| Patch do wrapper CRD | Modificação do `XDesktop.launch_session()` para suporte a display existente |
| install.sh | Instalador automatizado com detecção de usuário e placeholders |
| crd-mode | Comando de alternância entre modos virtual/local |
| start-active.sh | Wrapper do CRD com limpeza de variáveis de ambiente |
| .chrome-remote-desktop-session | Script de sessão para Cinnamon |
| Serviço systemd | Template configurável para o serviço |
| Documentação | Este README e exemplos de uso |

### Processo de desenvolvimento

1. Diagnóstico de problemas do CRD no Linux Mint com Cinnamon
2. Identificação de incompatibilidade do `--replace` com `cinnamon-session`
3. Análise do wrapper Python do CRD (`chrome-remote-desktop`)
4. Desenvolvimento do patch para suporte a sessão existente
5. Criação dos wrappers para modo virtual e local
6. Implementação do comando `crd-mode` com menu interativo
7. Automação com install.sh e sudoers
8. Testes e iterações até solução estável
9. Documentação completa

### Tecnologias utilizadas

- **Shell scripting** (Bash) — wrappers, instalador, crd-mode
- **Python** — patch do wrapper CRD
- **systemd** — gerenciamento do serviço
- **Xvfb** — servidor X virtual
- **Cinnamon** — ambiente de desktop
- **Chrome Remote Desktop** — acesso remoto
