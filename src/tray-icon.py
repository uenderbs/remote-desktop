#!/usr/bin/env python3

import gi
gi.require_version('Gtk', '3.0')
gi.require_version('AyatanaAppIndicator3', '0.1')
from gi.repository import Gtk, GLib, AyatanaAppIndicator3
import subprocess
import os
import threading

class MonitorTray:
    def __init__(self):
        self.script_path = os.path.expanduser("~/.local/bin/controle-monitor")
        self.notebook_output = "eDP-1"
        self.external_output = "HDMI-1-0"
        
        # Create AppIndicator
        icon_path = os.path.join(os.path.dirname(os.path.abspath(__file__)), "monitor-icon.png")
        self.indicator = AyatanaAppIndicator3.Indicator.new(
            "controle-monitor",
            icon_path,
            AyatanaAppIndicator3.IndicatorCategory.APPLICATION_STATUS
        )
        self.indicator.set_status(AyatanaAppIndicator3.IndicatorStatus.ACTIVE)
        
        # Create menu
        self.create_menu()
        self.indicator.set_menu(self.menu)
        
        # Ensure monitors configured on startup
        GLib.timeout_add(5000, self.ensure_monitors_extended)
    
    def create_menu(self):
        self.menu = Gtk.Menu()
        
        # Notebook submenu
        notebook_menu = Gtk.Menu()
        notebook_item = Gtk.MenuItem(label="Monitor interno (notebook)")
        notebook_item.set_submenu(notebook_menu)
        
        nb_on = Gtk.MenuItem(label="Ativar tela do notebook")
        nb_on.connect("activate", lambda w: self.notebook_on())
        notebook_menu.append(nb_on)
        
        nb_off = Gtk.MenuItem(label="Desativar tela do notebook")
        nb_off.connect("activate", lambda w: self.notebook_off())
        notebook_menu.append(nb_off)
        
        self.menu.append(notebook_item)
        self.menu.append(Gtk.SeparatorMenuItem())
        
        # External submenu
        external_menu = Gtk.Menu()
        external_item = Gtk.MenuItem(label="Monitor externo (HDMI)")
        external_item.set_submenu(external_menu)
        
        ext_on = Gtk.MenuItem(label="Ligar monitor externo")
        ext_on.connect("activate", lambda w: self.external_on())
        external_menu.append(ext_on)
        
        ext_off = Gtk.MenuItem(label="Desligar monitor externo")
        ext_off.connect("activate", lambda w: self.external_off())
        external_menu.append(ext_off)
        
        self.menu.append(external_item)
        self.menu.append(Gtk.SeparatorMenuItem())
        
        # Toggle both
        toggle_both = Gtk.MenuItem(label="Alternancia inteligente (Ctrl+Shift+3)")
        toggle_both.connect("activate", lambda w: self.toggle_both_smart())
        self.menu.append(toggle_both)
        
        self.menu.append(Gtk.SeparatorMenuItem())
        
        # Restore config
        restore_item = Gtk.MenuItem(label="Restaurar configuracao padrao")
        restore_item.connect("activate", lambda w: self.ensure_monitors_extended())
        self.menu.append(restore_item)
        
        self.menu.append(Gtk.SeparatorMenuItem())
        
        # Startup toggle
        self.startup_item = Gtk.MenuItem(label="Iniciar com o sistema")
        self.startup_item.connect("activate", lambda w: self.toggle_startup())
        self.menu.append(self.startup_item)
        
        self.menu.append(Gtk.SeparatorMenuItem())
        
        # Help
        help_item = Gtk.MenuItem(label="Ajuda")
        help_item.connect("activate", lambda w: self.show_help())
        self.menu.append(help_item)
        
        self.menu.append(Gtk.SeparatorMenuItem())
        
        # Quit
        quit_item = Gtk.MenuItem(label="Sair")
        quit_item.connect("activate", lambda w: self.quit())
        self.menu.append(quit_item)
        
        self.menu.show_all()
        self.update_startup_status()
    
    def run_command(self, cmd):
        try:
            result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
            return result.stdout.strip()
        except Exception as e:
            return str(e)
    
    def run_command_async(self, cmd, callback=None):
        def worker():
            try:
                result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
                if callback:
                    GLib.idle_add(callback, result.stdout.strip())
            except Exception as e:
                if callback:
                    GLib.idle_add(callback, str(e))
        threading.Thread(target=worker, daemon=True).start()
    
    def get_monitors(self):
        output = self.run_command("xrandr --listmonitors")
        monitors = []
        for line in output.split('\n'):
            if 'HDMI' in line or 'eDP' in line:
                monitors.append(line.strip())
        return monitors
    
    def is_monitor_active(self, output):
        monitors = self.get_monitors()
        return output in ' '.join(monitors)
    
    def get_monitor_position(self, output):
        output_cmd = self.run_command("xrandr --query")
        for line in output_cmd.split('\n'):
            if output in line and 'connected' in line:
                import re
                match = re.search(r'(\d+)x(\d+)\+(\d+)\+(\d+)', line)
                if match:
                    return (int(match.group(3)), int(match.group(4)))
        return None
    
    def is_mirror_mode(self):
        nb_pos = self.get_monitor_position(self.notebook_output)
        ext_pos = self.get_monitor_position(self.external_output)
        return nb_pos is not None and ext_pos is not None and nb_pos == ext_pos
    
    def is_external_connected(self):
        output = self.run_command("xrandr --query")
        for line in output.split('\n'):
            if self.external_output in line and 'connected' in line:
                return True
        return False
    
    def ensure_monitors_extended(self):
        nb_on = self.is_monitor_active(self.notebook_output)
        ext_on = self.is_monitor_active(self.external_output)
        ext_connected = self.is_external_connected()
        
        action_taken = False
        message = ""
        
        if not ext_connected:
            if not nb_on:
                self.run_command(f"xrandr --output {self.notebook_output} --auto")
                action_taken = True
                message = "Monitor externo nao detectado. Monitor do notebook ativado."
            else:
                message = "Monitor externo nao detectado. Monitor do notebook ja ativo."
            action_taken = True
        
        elif not nb_on and not ext_on:
            self.run_command(f"xrandr --output {self.notebook_output} --auto --output {self.external_output} --auto --right-of {self.notebook_output}")
            action_taken = True
            message = "Ambos monitores estavam desligados. Configuracao estendida aplicada."
        
        elif not nb_on:
            self.run_command(f"xrandr --output {self.notebook_output} --auto --output {self.external_output} --auto --right-of {self.notebook_output}")
            action_taken = True
            message = "Monitor do notebook estava desligado. Ligado e configurado em modo estendido."
        
        elif not ext_on:
            self.run_command(f"xrandr --output {self.external_output} --auto --right-of {self.notebook_output}")
            action_taken = True
            message = "Monitor externo estava desligado. Ligado e configurado em modo estendido."
        
        else:
            if self.is_mirror_mode():
                self.run_command(f"xrandr --output {self.notebook_output} --auto --output {self.external_output} --auto --right-of {self.notebook_output}")
                action_taken = True
                message = "Monitores estavam em modo espelho. Reconfigurado para modo estendido."
        
        if action_taken and message:
            GLib.idle_add(self.show_notification, "Configuracao de Monitores", message)
        
        return False
    
    def show_notification(self, title, message):
        try:
            subprocess.run(['notify-send', '-t', '5000', title, message], check=False)
        except:
            pass
    
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
            self.show_dialog("Aviso", "Monitor interno ja esta ativo")
            return
        
        if self.is_monitor_active(self.external_output):
            cmd = f"xrandr --output {self.notebook_output} --auto --output {self.external_output} --auto --right-of {self.notebook_output}"
        else:
            cmd = f"xrandr --output {self.notebook_output} --auto"
        
        def on_done(result):
            self.show_notification("Sucesso", "Monitor interno ativado")
        self.run_command_async(cmd, on_done)
    
    def notebook_off(self):
        if not self.is_monitor_active(self.notebook_output):
            self.show_dialog("Aviso", "Monitor interno ja esta desativado")
            return
        
        def on_done(result):
            self.show_notification("Sucesso", "Monitor interno desativado")
        self.run_command_async(f"xrandr --output {self.notebook_output} --off", on_done)
    
    def external_on(self):
        if self.is_monitor_active(self.external_output):
            self.show_dialog("Aviso", "Monitor externo ja esta ativo")
            return
        
        if self.is_monitor_active(self.notebook_output):
            cmd = f"xrandr --output {self.external_output} --auto --right-of {self.notebook_output}"
        else:
            cmd = f"xrandr --output {self.external_output} --auto"
        
        def on_done(result):
            self.show_notification("Sucesso", "Monitor externo ativado")
        self.run_command_async(cmd, on_done)
    
    def external_off(self):
        if not self.is_monitor_active(self.external_output):
            self.show_dialog("Aviso", "Monitor externo ja esta desativado")
            return
        
        def on_done(result):
            self.show_notification("Sucesso", "Monitor externo desativado")
        self.run_command_async(f"xrandr --output {self.external_output} --off", on_done)
    
    def toggle_both_smart(self):
        ext_on = self.is_monitor_active(self.external_output)
        nb_on = self.is_monitor_active(self.notebook_output)
        
        if ext_on != nb_on:
            if ext_on and not nb_on:
                self.run_command_async(f"xrandr --output {self.notebook_output} --auto --output {self.external_output} --auto --right-of {self.notebook_output}")
            else:
                self.run_command_async(f"xrandr --output {self.notebook_output} --off")
        else:
            if ext_on and nb_on:
                self.run_command_async(f"xrandr --output {self.notebook_output} --off && xrandr --output {self.external_output} --off")
            else:
                self.run_command_async(f"xrandr --output {self.notebook_output} --auto --output {self.external_output} --auto --right-of {self.notebook_output}")
    
    def toggle_startup(self):
        autostart_dir = os.path.expanduser("~/.config/autostart")
        desktop_file = os.path.join(autostart_dir, "controle-monitor.desktop")
        
        if os.path.exists(desktop_file):
            os.remove(desktop_file)
            self.show_notification("Informacao", "Inicializacao automatica desativada")
        else:
            os.makedirs(autostart_dir, exist_ok=True)
            content = f"""[Desktop Entry]
Type=Application
Name=Controle de Monitores
Comment=Controle de monitores notebook/externo
Exec={os.path.expanduser("~/.local/bin/controle-monitor-tray")}
Icon={os.path.join(os.path.dirname(os.path.abspath(__file__)), "monitor-icon.png")}
Terminal=false
Categories=Utility;
"""
            with open(desktop_file, 'w') as f:
                f.write(content)
            self.show_notification("Informacao", "Inicializacao automatica ativada")
        
        self.update_startup_status()
    
    def update_startup_status(self):
        autostart_dir = os.path.expanduser("~/.config/autostart")
        desktop_file = os.path.join(autostart_dir, "controle-monitor.desktop")
        
        if os.path.exists(desktop_file):
            self.startup_item.set_label("* Iniciar com o sistema")
        else:
            self.startup_item.set_label("Iniciar com o sistema")
    
    def show_help(self):
        help_text = """INSTRUCOES - CONTROLE DE MONITORES

Atalhos globais (funcionam sempre):
- Ctrl + Shift + 1  -> Ativa/Desativa tela do notebook
- Ctrl + Shift + 2  -> Liga/Desliga monitor externo
- Ctrl + Shift + 3  -> Alternancia inteligente

Menu (icone na bandeja):
- Monitor interno: Ativar / Desativar tela
- Monitor externo: Ligar / Desligar
- Alternancia inteligente: Sincroniza ou alterna ambos
- Restaurar configuracao padrao: Forca modo estendido

Observacoes:
- Alguns monitores nao ligam via software em modo economia.
- Se nao ligar, segure botao fisico do monitor."""
        
        self.show_dialog("Ajuda - Controle de Monitores", help_text)
    
    def quit(self):
        Gtk.main_quit()

def main():
    app = MonitorTray()
    Gtk.main()

if __name__ == "__main__":
    main()
