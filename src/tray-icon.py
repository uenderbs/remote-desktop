#!/usr/bin/env python3

import gi
gi.require_version('Gtk', '3.0')
from gi.repository import Gtk, GLib
import subprocess
import os
import threading
from Xlib import X, display

class MonitorControl:
    def __init__(self):
        self.script_path = os.path.expanduser("~/.local/bin/controle-monitor")
        self.notebook_output = "eDP-1"
        self.external_output = "HDMI-1-0"
        
        # Keycodes for 1, 2, 3
        self.keycodes = {
            '1': 10,  # KEY_1
            '2': 11,  # KEY_2
            '3': 12,  # KEY_3
        }
        
        # Modifiers: Control(1) + Alt(3) = 4 + 8 = 12
        self.ctrl_alt_mask = 12  # ControlMask | Mod1Mask
        
        # Create status icon
        self.status_icon = Gtk.StatusIcon()
        self.status_icon.set_from_icon_name("display-display-symbolic")
        self.status_icon.set_tooltip_text("Controle de Monitores")
        self.status_icon.connect("popup-menu", self.on_popup_menu)
        self.status_icon.connect("activate", self.on_activate)
        
        # Create menu
        self.create_menu()
        
        # Grab keyboard shortcuts
        self.grab_shortcuts()
        
        # Verifica e configura monitores no boot (5s após iniciar)
        GLib.timeout_add(5000, self.ensure_monitors_extended)
    
    def create_menu(self):
        self.menu = Gtk.Menu()
        
        # Notebook submenu
        notebook_menu = Gtk.Menu()
        notebook_item = Gtk.MenuItem(label="Monitor interno (notebook)")
        notebook_item.set_submenu(notebook_menu)
        
        nb_on = Gtk.MenuItem(label="Ativar tela do notebook")
        nb_on.connect("button-release-event", lambda w, e: self.notebook_on())
        notebook_menu.append(nb_on)
        
        nb_off = Gtk.MenuItem(label="Desativar tela do notebook")
        nb_off.connect("button-release-event", lambda w, e: self.notebook_off())
        notebook_menu.append(nb_off)
        
        self.menu.append(notebook_item)
        self.menu.append(Gtk.SeparatorMenuItem())
        
        # External submenu
        external_menu = Gtk.Menu()
        external_item = Gtk.MenuItem(label="Monitor externo (HDMI)")
        external_item.set_submenu(external_menu)
        
        ext_on = Gtk.MenuItem(label="Ligar monitor externo")
        ext_on.connect("button-release-event", lambda w, e: self.external_on())
        external_menu.append(ext_on)
        
        ext_off = Gtk.MenuItem(label="Desligar monitor externo")
        ext_off.connect("button-release-event", lambda w, e: self.external_off())
        external_menu.append(ext_off)
        
        self.menu.append(external_item)
        self.menu.append(Gtk.SeparatorMenuItem())
        
        # Toggle both
        toggle_both = Gtk.MenuItem(label="Alternância inteligente (Ctrl+Alt+3)")
        toggle_both.connect("button-release-event", lambda w, e: self.toggle_both_smart())
        self.menu.append(toggle_both)
        
        # Restaurar configuração padrão
        restore_item = Gtk.MenuItem(label="Restaurar configuração padrão")
        restore_item.connect("button-release-event", lambda w, e: self.ensure_monitors_extended())
        self.menu.append(restore_item)
        
        self.menu.append(Gtk.SeparatorMenuItem())
        
        # Startup toggle
        self.startup_item = Gtk.MenuItem(label="Iniciar com o sistema")
        self.startup_item.connect("button-release-event", lambda w, e: self.toggle_startup())
        self.menu.append(self.startup_item)
        
        self.menu.append(Gtk.SeparatorMenuItem())
        
        # Help
        help_item = Gtk.MenuItem(label="Ajuda")
        help_item.connect("button-release-event", lambda w, e: self.show_help())
        self.menu.append(help_item)
        
        self.menu.append(Gtk.SeparatorMenuItem())
        
        # Quit
        quit_item = Gtk.MenuItem(label="Sair")
        quit_item.connect("button-release-event", lambda w, e: self.quit())
        self.menu.append(quit_item)
        
        self.menu.show_all()
        self.update_startup_status()
    
    def grab_shortcuts(self):
        """Grab keyboard shortcuts using Xlib"""
        def shortcut_listener():
            try:
                d = display.Display()
                root = d.screen().root
                
                # Set event mask for key presses
                root.change_attributes(event_mask=X.KeyPressMask)
                
                # Grab keys: Ctrl+Alt+1, Ctrl+Alt+2, Ctrl+Alt+3
                for key, keycode in self.keycodes.items():
                    root.grab_key(
                        keycode,
                        self.ctrl_alt_mask,
                        True,
                        X.GrabModeAsync,
                        X.GrabModeAsync
                    )
                
                # Flush the display
                d.sync()
                
                # Event loop
                while True:
                    event = d.next_event()
                    if event.type == X.KeyPress:
                        keycode = event.detail
                        if keycode == self.keycodes['1']:
                            GLib.idle_add(self.notebook_toggle)
                        elif keycode == self.keycodes['2']:
                            GLib.idle_add(self.external_toggle)
                        elif keycode == self.keycodes['3']:
                            GLib.idle_add(self.toggle_both_smart)
            except Exception as e:
                print(f"Erro no listener de atalhos: {e}")
        
        # Start listener in a separate thread
        thread = threading.Thread(target=shortcut_listener, daemon=True)
        thread.start()
    
    def run_command(self, cmd):
        try:
            result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
            return result.stdout.strip()
        except Exception as e:
            return str(e)
    
    def get_monitors(self):
        output = self.run_command("xrandr --listmonitors")
        monitors = []
        for line in output.split('\n'):
            if 'HDMI' in line or 'eDP' in line:
                monitors.append(line)
        return monitors
    
    def is_monitor_active(self, output):
        monitors = self.get_monitors()
        return output in ' '.join(monitors)
    
    def get_monitor_position(self, output):
        """Retorna a posição (x, y) de um monitor via xrandr --query"""
        output_cmd = self.run_command("xrandr --query")
        for line in output_cmd.split('\n'):
            if output in line and 'connected' in line:
                # Parse: "eDP-1 connected 1920x1080+0+0"
                import re
                match = re.search(r'(\d+)x(\d+)\+(\d+)\+(\d+)', line)
                if match:
                    return (int(match.group(3)), int(match.group(4)))
        return None
    
    def is_mirror_mode(self):
        """Verifica se monitores estão em modo espelho (mesma posição)"""
        nb_pos = self.get_monitor_position(self.notebook_output)
        ext_pos = self.get_monitor_position(self.external_output)
        return nb_pos is not None and ext_pos is not None and nb_pos == ext_pos
    
    def is_external_connected(self):
        """Verifica se monitor externo está fisicamente conectado"""
        output = self.run_command("xrandr --query")
        for line in output.split('\n'):
            if self.external_output in line and 'connected' in line:
                return True
        return False
    
    def ensure_monitors_extended(self):
        """Garante que ambos monitores estejam ligados e estendidos (executa no boot)"""
        nb_on = self.is_monitor_active(self.notebook_output)
        ext_on = self.is_monitor_active(self.external_output)
        ext_connected = self.is_external_connected()
        
        action_taken = False
        message = ""
        
        if not ext_connected:
            # Monitor externo não conectado - garante apenas notebook ligado
            if not nb_on:
                self.run_command(f"xrandr --output {self.notebook_output} --auto")
                action_taken = True
                message = "Monitor externo não detectado. Apenas monitor do notebook foi ativado."
            else:
                message = "Monitor externo não detectado. Monitor do notebook já está ativo."
            action_taken = True
        
        elif not nb_on and not ext_on:
            # Ambos desligados - liga ambos em modo estendido
            self.run_command(f"xrandr --output {self.notebook_output} --auto --output {self.external_output} --auto --right-of {self.notebook_output}")
            action_taken = True
            message = "Ambos monitores estavam desligados. Configuração estendida aplicada."
        
        elif not nb_on:
            # Notebook desligado - liga e estende
            self.run_command(f"xrandr --output {self.notebook_output} --auto --output {self.external_output} --auto --right-of {self.notebook_output}")
            action_taken = True
            message = "Monitor do notebook estava desligado. Ligado e configurado em modo estendido."
        
        elif not ext_on:
            # Externo desligado - liga e estende
            self.run_command(f"xrandr --output {self.external_output} --auto --right-of {self.notebook_output}")
            action_taken = True
            message = "Monitor externo estava desligado. Ligado e configurado em modo estendido."
        
        else:
            # Ambos ligados - verifica se está em modo mirror/clonado
            if self.is_mirror_mode():
                self.run_command(f"xrandr --output {self.notebook_output} --auto --output {self.external_output} --auto --right-of {self.notebook_output}")
                action_taken = True
                message = "Monitores estavam em modo espelho. Reconfigurado para modo estendido."
        
        if action_taken and message:
            # Usa GLib.idle_add para garantir execução na thread principal
            GLib.idle_add(self.show_dialog_auto_close, "Configuração de Monitores", message)
        
        # Retorna False para não repetir o timeout
        return False
    
    def show_dialog_auto_close(self, title, message, timeout=5000):
        """Dialog com auto-close após timeout (ms)"""
        dialog = Gtk.MessageDialog(
            transient_for=None,
            modal=True,
            message_type=Gtk.MessageType.INFO,
            buttons=Gtk.ButtonsType.OK,
            text=title
        )
        dialog.format_secondary_text(message)
        
        # Auto-close após timeout
        def close_dialog():
            dialog.response(Gtk.ResponseType.OK)
            return False  # não repetir
        
        GLib.timeout_add(timeout, close_dialog)
        dialog.run()
        dialog.destroy()
    
    def show_dialog(self, title, message):
        dialog = Gtk.MessageDialog(
            transient_for=None,
            modal=True,
            message_type=Gtk.MessageType.INFO,
            buttons=Gtk.ButtonsType.OK,
            text=title
        )
        dialog.format_secondary_text(message)
        dialog.run()
        dialog.destroy()
    
    def notebook_on(self):
        if self.is_monitor_active(self.notebook_output):
            self.show_dialog("Aviso", "Monitor interno já está ativo")
            return
        
        if self.is_monitor_active(self.external_output):
            cmd = f"xrandr --output {self.notebook_output} --auto --output {self.external_output} --auto --right-of {self.notebook_output}"
        else:
            cmd = f"xrandr --output {self.notebook_output} --auto"
        
        self.run_command(cmd)
        self.show_dialog("Sucesso", "Monitor interno ativado")
    
    def notebook_off(self):
        if not self.is_monitor_active(self.notebook_output):
            self.show_dialog("Aviso", "Monitor interno já está desativado")
            return
        
        self.run_command(f"xrandr --output {self.notebook_output} --off")
        self.show_dialog("Sucesso", "Monitor interno desativado")
    
    def notebook_toggle(self):
        if self.is_monitor_active(self.notebook_output):
            self.run_command(f"xrandr --output {self.notebook_output} --off")
        else:
            if self.is_monitor_active(self.external_output):
                cmd = f"xrandr --output {self.notebook_output} --auto --output {self.external_output} --auto --right-of {self.notebook_output}"
            else:
                cmd = f"xrandr --output {self.notebook_output} --auto"
            self.run_command(cmd)
    
    def external_on(self):
        if self.is_monitor_active(self.external_output):
            self.show_dialog("Aviso", "Monitor externo já está ativo")
            return
        
        if self.is_monitor_active(self.notebook_output):
            cmd = f"xrandr --output {self.external_output} --auto --right-of {self.notebook_output}"
        else:
            cmd = f"xrandr --output {self.external_output} --auto"
        
        self.run_command(cmd)
        self.show_dialog("Sucesso", "Monitor externo ativado")
    
    def external_off(self):
        if not self.is_monitor_active(self.external_output):
            self.show_dialog("Aviso", "Monitor externo já está desativado")
            return
        
        self.run_command(f"xrandr --output {self.external_output} --off")
        self.show_dialog("Sucesso", "Monitor externo desativado")
    
    def external_toggle(self):
        if self.is_monitor_active(self.external_output):
            self.run_command(f"xrandr --output {self.external_output} --off")
        else:
            if self.is_monitor_active(self.notebook_output):
                cmd = f"xrandr --output {self.external_output} --auto --right-of {self.notebook_output}"
            else:
                cmd = f"xrandr --output {self.external_output} --auto"
            self.run_command(cmd)
    
    def toggle_both_smart(self):
        ext_on = self.is_monitor_active(self.external_output)
        nb_on = self.is_monitor_active(self.notebook_output)
        
        if ext_on != nb_on:
            # Sincroniza
            if ext_on and not nb_on:
                self.run_command(f"xrandr --output {self.notebook_output} --auto --output {self.external_output} --auto --right-of {self.notebook_output}")
            else:
                self.run_command(f"xrandr --output {self.notebook_output} --off")
        else:
            # Alterna ambos
            if ext_on and nb_on:
                self.run_command(f"xrandr --output {self.notebook_output} --off")
                self.run_command(f"xrandr --output {self.external_output} --off")
            else:
                self.run_command(f"xrandr --output {self.notebook_output} --auto --output {self.external_output} --auto --right-of {self.notebook_output}")
    
    def toggle_startup(self):
        autostart_dir = os.path.expanduser("~/.config/autostart")
        desktop_file = os.path.join(autostart_dir, "controle-monitor.desktop")
        
        if os.path.exists(desktop_file):
            os.remove(desktop_file)
            self.show_dialog("Informação", "Inicialização automática desativada")
        else:
            os.makedirs(autostart_dir, exist_ok=True)
            content = f"""[Desktop Entry]
Type=Application
Name=Controle de Monitores
Comment=Controle de monitores notebook/externo
Exec={self.script_path}-tray
Icon=display-display-symbolic
Terminal=false
Categories=Utility;
"""
            with open(desktop_file, 'w') as f:
                f.write(content)
            self.show_dialog("Informação", "Inicialização automática ativada")
        
        self.update_startup_status()
    
    def update_startup_status(self):
        autostart_dir = os.path.expanduser("~/.config/autostart")
        desktop_file = os.path.join(autostart_dir, "controle-monitor.desktop")
        
        if os.path.exists(desktop_file):
            self.startup_item.set_label("✓ Iniciar com o sistema")
        else:
            self.startup_item.set_label("Iniciar com o sistema")
    
    def show_help(self):
        help_text = """INSTRUÇÕES – CONTROLE DE MONITORES

Atalhos:
• Ctrl + Alt + 1  → Ativa/Desativa a tela do notebook
• Ctrl + Alt + 2  → Liga/Desliga o monitor externo
• Ctrl + Alt + 3  → Alternância inteligente

Menu (ícone ao lado do relógio):
• Monitor interno (notebook): Ativar / Desativar tela
• Monitor externo: Ligar / Desligar
• Alternância inteligente: Sincroniza ou alterna ambos

Observações importantes:
• Alguns monitores não voltam a ligar via software em certos modos de economia de energia.
• Se o monitor não ligar, pressione e segure o botão físico de ligar do monitor."""
        
        self.show_dialog("Ajuda – Controle de Monitores", help_text)
    
    def show_dialog(self, title, message):
        dialog = Gtk.MessageDialog(
            transient_for=None,
            modal=True,
            message_type=Gtk.MessageType.INFO,
            buttons=Gtk.ButtonsType.OK,
            text=title
        )
        dialog.format_secondary_text(message)
        dialog.run()
        dialog.destroy()
    
    def on_popup_menu(self, icon, button, activate_time):
        self.menu.popup_at_pointer(None)
    
    def on_activate(self, icon):
        monitors = self.get_monitors()
        info = "Monitores ativos:\n\n"
        for m in monitors:
            info += f"• {m}\n"
        self.show_dialog("Status dos Monitores", info)
    
    def quit(self):
        Gtk.main_quit()

def main():
    app = MonitorControl()
    Gtk.main()

if __name__ == "__main__":
    main()
