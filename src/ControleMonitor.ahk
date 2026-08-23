#Requires AutoHotkey v2.0
#SingleInstance Force

; =========================================================
; CONFIGURAÇÕES
; =========================================================
OnError(ShowErr)
OnExit(Cleanup)

TraySetIcon("shell32.dll", 16)
A_IconTip := "Controle de Monitores (Notebook + Externo)"

global gMonitors := []
global gNotebookIsExternalOnly := false  ; estado lógico do notebook (external-only)

; =========================================================
; HOTKEYS (ATALHOS)
; a) Ctrl+Shift+1 = ativa/desativa monitor do notebook
; b) Ctrl+Shift+2 = liga/desliga monitor externo (DDC/CI)
; c) Ctrl+Shift+3 = smart: sincroniza e depois alterna ambos
; =========================================================
^+1::ToggleNotebook()
^+2::ToggleExternal()
^+3::ToggleBothSmart()

; =========================================================
; INICIALIZAÇÃO
; =========================================================
RefreshMonitors()
BuildMenu()
SetTimer(() => 0, 1000000) ; mantém o script vivo

; =========================================================
; MENU DO SYSTEM TRAY (ORGANIZADO)
; - Monitor interno: somente ativar/desativar tela do notebook
; - Monitor externo: liga/desliga (DDC/CI)
; - Ajuda: abre janela com instruções
; - Iniciar com o Windows: ativar/desativar
; =========================================================
BuildMenu() {
    A_TrayMenu.Delete()

    nb := Menu()
    nb.Add("Ativar tela do notebook", (*) => NotebookOn())
    nb.Add("Desativar tela do notebook", (*) => NotebookOff())
    A_TrayMenu.Add("💻 Monitor interno (notebook)", nb)

    A_TrayMenu.Add()

    ext := Menu()
    if (GetExternalHandles().Length = 0) {
        ext.Add("⚠️ Monitor externo não detectado (DDC/CI)", (*) => 0)
    } else {
        ext.Add("Ligar monitor externo", (*) => ExternalSetAll(0x01))
        ext.Add("Desligar monitor externo", (*) => ExternalSetAll(0x05))
    }
    A_TrayMenu.Add("🖥️ Monitor externo (HDMI / DDC/CI)", ext)

    A_TrayMenu.Add()
    A_TrayMenu.Add("🔄 Recarregar monitores", (*) => (RefreshMonitors(), BuildMenu()))

    A_TrayMenu.Add()
    A_TrayMenu.Add("❓ Ajuda", (*) => ShowHelp())

    ; --- NOVO: iniciar com o Windows (toggle + check) ---
    A_TrayMenu.Add("🪟 Iniciar com o Windows", (*) => (ToggleStartup(), BuildMenu()))
    if (IsStartupEnabled())
        A_TrayMenu.Check("🪟 Iniciar com o Windows")
    else
        A_TrayMenu.Uncheck("🪟 Iniciar com o Windows")

    A_TrayMenu.Add("❌ Sair", (*) => ExitApp())
}

; =========================================================
; INICIAR COM O WINDOWS (ATALHO NA PASTA STARTUP DO USUÁRIO)
; =========================================================
StartupLinkPath() {
    ; Startup do usuário atual (não precisa admin)
    return A_Startup "\ControleMonitores.lnk"
}

IsStartupEnabled() {
    return FileExist(StartupLinkPath())
}

ToggleStartup() {
    if (IsStartupEnabled())
        DisableStartup()
    else
        EnableStartup()
}

EnableStartup() {
    try {
        link := StartupLinkPath()
        shell := ComObject("WScript.Shell")
        sc := shell.CreateShortcut(link)

        if (A_IsCompiled) {
            sc.TargetPath := A_ScriptFullPath
            sc.Arguments := ""
        } else {
            sc.TargetPath := A_AhkPath
            sc.Arguments := '"' A_ScriptFullPath '"'
        }

        sc.WorkingDirectory := A_ScriptDir
        sc.IconLocation := "shell32.dll,16"
        sc.Save()
    } catch as e {
        MsgBox "Não foi possível ativar 'Iniciar com o Windows'.`n`n" e.Message,
              "Controle de Monitores", 48
    }
}

DisableStartup() {
    try {
        link := StartupLinkPath()
        if FileExist(link)
            FileDelete(link)
    } catch as e {
        MsgBox "Não foi possível desativar 'Iniciar com o Windows'.`n`n" e.Message,
              "Controle de Monitores", 48
    }
}

; =========================================================
; AJUDA (janela com botão OK)
; =========================================================
ShowHelp() {
    helpText :=
    (
"INSTRUÇÕES – CONTROLE DE MONITORES

Atalhos:
• Ctrl + Shift + 1  → Ativa/Desativa a tela do notebook
• Ctrl + Shift + 2  → Liga/Desliga o monitor externo (DDC/CI)
• Ctrl + Shift + 3  → Alternância inteligente:
   - Se um estiver ligado e o outro desligado, sincroniza com apenas um comando.
   - Se ambos estiverem no mesmo estado, alterna os dois juntos.

Menu (ícone ao lado do relógio):
• Monitor interno (notebook): Ativar / Desativar tela
• Monitor externo: Ligar / Desligar

Observações importantes:
• Alguns monitores não voltam a ligar via software em certos modos de economia de energia.
  Se o monitor não ligar, pressione e segure o botão físico de ligar do monitor por alguns
  segundos até ele voltar."
    )

    MsgBox helpText, "Ajuda – Controle de Monitores", "OK Iconi"
}

; =========================================================
; NOTEBOOK (INTERNAL) – DisplaySwitch
; =========================================================
NotebookOff() {
    global gNotebookIsExternalOnly
    Run "DisplaySwitch.exe /external", , "Hide"
    gNotebookIsExternalOnly := true
}

NotebookOn() {
    global gNotebookIsExternalOnly
    Run "DisplaySwitch.exe /extend", , "Hide"
    gNotebookIsExternalOnly := false
}

ToggleNotebook() {
    global gNotebookIsExternalOnly
    if (gNotebookIsExternalOnly)
        NotebookOn()
    else
        NotebookOff()
}

; =========================================================
; EXTERNO (DDC/CI)
; =========================================================
ExternalIsAnyOn() {
    hs := GetExternalHandles()
    anyOn := false
    for h in hs {
        st := GetPowerMode(h)
        if (st = 0x01) {
            anyOn := true
            break
        }
    }
    return anyOn
}

ExternalSetAll(value) {
    hs := GetExternalHandles()
    if (hs.Length = 0)
        return

    for h in hs
        SetPower(h, value)

    Sleep 300
    RefreshMonitors()
    BuildMenu()
}

ToggleExternal() {
    if (GetExternalHandles().Length = 0)
        return

    if (ExternalIsAnyOn())
        ExternalSetAll(0x05)
    else
        ExternalSetAll(0x01)
}

ToggleBothSmart() {
    global gNotebookIsExternalOnly

    hs := GetExternalHandles()
    if (hs.Length = 0)
        return

    extOn := ExternalIsAnyOn()
    nbOn  := !gNotebookIsExternalOnly

    if (extOn != nbOn) {
        ; sincroniza com UM comando (notebook primeiro)
        if (extOn && !nbOn)
            NotebookOn()
        else
            NotebookOff()
        return
    }

    ; já estão iguais -> alterna ambos juntos
    if (extOn && nbOn) {
        NotebookOff()
        ExternalSetAll(0x05)
    } else {
        NotebookOn()
        ExternalSetAll(0x01)
    }
}

; =========================================================
; DDC/CI – PRIMITIVAS
; =========================================================
GetPowerMode(hPhysicalMonitor) {
    cur := 0, max := 0, vcpType := 0
    ok := DllCall(
        "dxva2\GetVCPFeatureAndVCPFeatureReply",
        "ptr", hPhysicalMonitor,
        "uchar", 0xD6,
        "uint*", &vcpType,
        "uint*", &cur,
        "uint*", &max
    )
    return ok ? cur : -1
}

SetPower(hPhysicalMonitor, value) {
    ok := DllCall(
        "dxva2\SetVCPFeature",
        "ptr", hPhysicalMonitor,
        "uchar", 0xD6,
        "uint", value
    )
    return !!ok
}

; =========================================================
; ENUMERAÇÃO (dxva2)
; =========================================================
RefreshMonitors() {
    global gMonitors
    Cleanup()
    gMonitors := []

    cb := CallbackCreate(EnumMonProc, "Fast", 4)
    DllCall("user32\EnumDisplayMonitors", "ptr",0, "ptr",0, "ptr",cb, "ptr",0)
    CallbackFree(cb)
}

EnumMonProc(hMon, hdc, lprc, lparam) {
    global gMonitors

    count := 0
    ok := DllCall(
        "dxva2\GetNumberOfPhysicalMonitorsFromHMONITOR",
        "ptr", hMon,
        "uint*", &count
    )
    if (!ok || count <= 0)
        return true

    psz := A_PtrSize + (128 * 2)
    buf := Buffer(count * psz, 0)

    ok2 := DllCall(
        "dxva2\GetPhysicalMonitorsFromHMONITOR",
        "ptr", hMon,
        "uint", count,
        "ptr", buf.Ptr
    )
    if (!ok2)
        return true

    phys := []
    loop count {
        off := (A_Index - 1) * psz
        hPhys := NumGet(buf, off, "ptr")
        name := StrGet(buf.Ptr + off + A_PtrSize, 128, "UTF-16")
        if (name = "")
            name := "Monitor físico " A_Index
        phys.Push({h: hPhys, name: name})
    }

    gMonitors.Push({hMon: hMon, phys: phys})
    return true
}

; Retorna TODOS os handles físicos detectados (dedupe por valor do handle)
GetExternalHandles() {
    global gMonitors
    hs := []
    seen := Map()

    for mon in gMonitors {
        for phys in mon.phys {
            h := phys.h
            key := Format("0x{:X}", h)
            if (seen.Has(key))
                continue
            seen[key] := true
            hs.Push(h)
        }
    }
    return hs
}

; =========================================================
; CLEANUP
; =========================================================
Cleanup(*) {
    global gMonitors
    if (gMonitors.Length = 0)
        return

    for mon in gMonitors {
        cnt := mon.phys.Length
        if (cnt <= 0)
            continue

        psz := A_PtrSize + (128 * 2)
        buf := Buffer(cnt * psz, 0)
        i := 0
        for p in mon.phys {
            off := i * psz
            NumPut("ptr", p.h, buf, off)
            i += 1
        }
        DllCall("dxva2\DestroyPhysicalMonitors", "uint", cnt, "ptr", buf.Ptr)
    }
    gMonitors := []
}

ShowErr(e, mode) {
    MsgBox "Erro no script:`n`n" e.Message "`nLinha: " e.Line "`nArquivo: " e.File,
          "ControleMonitor - Erro", 16
    return true
}
