#Requires AutoHotkey v2.0
#SingleInstance Force

; --- OTOMATİK TEMİZLİK ---
DetectHiddenWindows True
for id in WinGetList(A_ScriptName) {
    if (id != A_ScriptHwnd)
        try WinClose("ahk_id " id)
}

; --- YÖNETİCİ İZNİ ---
if !A_IsAdmin {
    try Run('*RunAs "' A_ScriptFullpath '"')
    ExitApp()
}

; --- DEĞİŞKENLER ---
global IsRunning := false
global CurrentHotkey := "F1"
global IsListening := false

; --- ARAYÜZ OLUŞTURMA ---
MyGui := Gui("+AlwaysOnTop", "Otomasyon Botu v2.0")
MyGui.SetFont("s9", "Segoe UI")

; 1. GENEL KONTROL
MyGui.Add("GroupBox", "x10 y10 w250 h65", "Başlat / Durdur Kısayolu")
HK_Display := MyGui.Add("Text", "x30 y35 w130 Center +Border", CurrentHotkey)
SetBtn := MyGui.Add("Button", "x170 y30 w70 h25", "Tuş Ata")

; 2. FARE AYARLARI (Güncellendi)
MyGui.Add("GroupBox", "x10 y80 w250 h225", "Tıklama Otomasyonu")
EnableMouse := MyGui.Add("Checkbox", "x20 y100 Checked", "Tıklama açık")
ModeDrop := MyGui.Add("DropDownList", "x60 y122 w180 Choose1", ["Fare Konumu", "Belirli Koordinat"])

XLabel := MyGui.Add("Text", "x20 y155 +Hidden", "X:"), EditX := MyGui.Add("Edit", "x40 y152 w60 +Hidden", "0")
YLabel := MyGui.Add("Text", "x120 y155 +Hidden", "Y:"), EditY := MyGui.Add("Edit", "x150 y152 w60 +Hidden", "0")
CaptureBtn := MyGui.Add("Button", "x20 y185 w230 h25 +Hidden", "F3 ile Konum Yakala")

MyGui.Add("Text", "x20 y220", "Tuş:")
ClickType := MyGui.Add("DropDownList", "x55 y217 w65 Choose1", ["Left", "Right", "Middle"])
MouseMode := MyGui.Add("DropDownList", "x125 y217 w115 Choose1", ["Tıkla", "Basılı Tut"])

MyGui.Add("Text", "x20 y260", "Tıklama Aralığı (ms):")
MouseDelay := MyGui.Add("Edit", "x140 y257 w50", "100")

; 3. KLAVYE AYARLARI
MyGui.Add("GroupBox", "x10 y315 w250 h115", "Klavye Otomasyonu")
EnableKey := MyGui.Add("Checkbox", "x20 y335", "Klavye Aktif")
MyGui.Add("Text", "x20 y365", "Tuş:")
KeyToSend := MyGui.Add("Edit", "x55 y362 w50", "e")
KeyMode := MyGui.Add("DropDownList", "x115 y362 w120 Choose1", ["Bas-Bırak", "Basılı Tut"])
MyGui.Add("Text", "x20 y400", "Tuş Gecikmesi (ms):")
KeyDelay := MyGui.Add("Edit", "x140 y397 w50", "500")

; DURUM PANELİ
MyGui.SetFont("s11 Bold")
StatusText := MyGui.Add("Text", "x10 y440 w250 Center cRed", "DURDURULDU")
MyGui.SetFont("s8 Norm")
MyGui.Add("Text", "x10 y470 w250 Center cGray", "Kapat: ESC + F12 | Konum Al: F3")

MyGui.Show("w270")

; --- ETKİNLİKLER ---
ModeDrop.OnEvent("Change", (ctrl, *) => ToggleCoords(ctrl))
SetBtn.OnEvent("Click", (*) => StartListening())
MyGui.OnEvent("Close", (*) => SafeExit())

; --- FONKSİYONLAR ---

SafeExit(*) {
    StopAllActions()
    ExitApp()
}

StopAllActions() {
    SetTimer(MouseLoop, 0)
    SetTimer(KeyLoop, 0)
    ; Tuşları serbest bırak (Takılı kalmasınlar)
    try {
        if (MouseMode.Text = "Basılı Tut")
            Click(ClickType.Text " Up")
        if (KeyMode.Text = "Basılı Tut")
            SendEvent("{" KeyToSend.Value " up}")
    }
}

ToggleCoords(ctrl) {
    show := (ctrl.Text = "Belirli Koordinat")
    XLabel.Visible := EditX.Visible := YLabel.Visible := EditY.Visible := CaptureBtn.Visible := show
}

StartListening() {
    global IsListening, CurrentHotkey
    if (IsListening) {
        return
    }
    IsListening := true
    HK_Display.Value := "Tuş Bekleniyor...", HK_Display.SetFont("cBlue Bold")
    ih := InputHook("L1 T5 M"), ih.Start(), ih.Wait()
    NewKey := (ih.Input != "") ? ih.Input : ih.EndKey
    if (NewKey != "") {
        try {
            Hotkey(CurrentHotkey, "Off")
            CurrentHotkey := NewKey
            Hotkey(CurrentHotkey, (*) => ToggleLogic())
            HK_Display.Value := CurrentHotkey
        }
    }
    HK_Display.SetFont("cBlack Norm s9"), IsListening := false
}

ToggleLogic() {
    global IsRunning
    if (IsRunning) {
        IsRunning := false
        StatusText.Value := "DURDURULDU", StatusText.SetFont("cRed")
        StopAllActions()
    } else {
        IsRunning := true
        StatusText.Value := "ÇALIŞIYOR", StatusText.SetFont("cGreen")
        
        ; FARE BAŞLATMA
        if (EnableMouse.Value) {
            if (MouseMode.Text = "Basılı Tut") {
                if (ModeDrop.Text = "Belirli Koordinat")
                    Click(ClickType.Text " Down " EditX.Value " " EditY.Value)
                else
                    Click(ClickType.Text " Down")
            } else {
                SetTimer(MouseLoop, MouseDelay.Value)
            }
        }
        
        ; KLAVYE BAŞLATMA
        if (EnableKey.Value) {
            if (KeyMode.Text = "Basılı Tut") {
                SendEvent("{" KeyToSend.Value " down}")
            } else {
                SetTimer(KeyLoop, KeyDelay.Value)
            }
        }
    }
}

MouseLoop() {
    if (!IsRunning) {
        return
    }
    btn := ClickType.Text
    if (ModeDrop.Text = "Belirli Koordinat")
        Click(btn " " EditX.Value " " EditY.Value)
    else
        Click(btn)
}

KeyLoop() {
    if (!IsRunning) {
        return
    }
    tuş := KeyToSend.Value
    if (tuş != "") {
        SendEvent("{" tuş " down}")
        Sleep(50)
        SendEvent("{" tuş " up}")
    }
}

; --- KISAYOLLAR ---
~Esc & F12:: SafeExit()

F3:: {
    if (ModeDrop.Text = "Belirli Koordinat") {
        MouseGetPos(&outX, &outY)
        EditX.Value := outX, EditY.Value := outY
    }
}

Hotkey(CurrentHotkey, (*) => ToggleLogic())
