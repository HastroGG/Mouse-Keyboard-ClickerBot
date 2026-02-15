#Requires AutoHotkey v2.0
#SingleInstance Force

; --- Değişkenler ---
global IsRunning := false
global CurrentHotkey := "F1" 
global IsListening := false

; --- Arayüz Oluşturma ---
MyGui := Gui("+AlwaysOnTop", "Pro Multi-Otomasyon v3.3")
MyGui.SetFont("s9", "Segoe UI")

; Pencere genişliği 270 olarak varsayalım. 
; GroupBox 250 genişliğinde ise x10 vererek tam ortalarız.

; 1. Başlat/Durdur Tuş Ataması
MyGui.Add("GroupBox", "x10 y10 w250 h65", "Hotkey Tuşu")
HK_Display := MyGui.Add("Text", "vHK_Display x30 y35 w130 Center +Border", CurrentHotkey)
SetBtn := MyGui.Add("Button", "vSetBtn x170 y30 w70 h25", "Tuş Ata")
SetBtn.OnEvent("Click", StartListening)

; 2. Fare Ayarları
MyGui.Add("GroupBox", "x10 y80 w250 h195", "Tıklama Pozisyonu")
EnableMouse := MyGui.Add("Checkbox", "vEnableMouse x20 y100 Checked", "Fare Tıklaması")
MyGui.Add("Text", "x20 y125", "Mod:")
Mode := MyGui.Add("DropDownList", "vMode x60 y122 w180 Choose1", ["Fare Konumu", "Belirli Koordinat"])
Mode.OnEvent("Change", ToggleCoords)

; Koordinat Alt Bölümü
XLabel := MyGui.Add("Text", "vXLabel x20 y155 +Hidden", "X :")
EditX := MyGui.Add("Edit", "vEditX x40 y152 w60 +Hidden", "0")
YLabel := MyGui.Add("Text", "vYLabel x120 y155 +Hidden", "Y :")
EditY := MyGui.Add("Edit", "vEditY x150 y152 w60 +Hidden", "0")
CaptureBtn := MyGui.Add("Button", "vCaptureBtn x20 y185 w230 h25 +Hidden", "F3 ile Konum Yakala")

MyGui.Add("Text", "x20 y220", "Tıklama :")
ClickType := MyGui.Add("DropDownList", "vClickType x70 y217 w60 Choose1", ["Left", "Right", "Middle"])
MyGui.Add("Text", "x140 y220", "Hız(ms):")
MouseDelay := MyGui.Add("Edit", "vMouseDelay x190 y217 w50", "10")

; 3. Klavye Ayarları
MyGui.Add("GroupBox", "x10 y285 w250 h90", "Tuş Otomasyonu")
EnableKey := MyGui.Add("Checkbox", "vEnableKey x20 y305", "Tuş Basımı")
MyGui.Add("Text", "x20 y335", "Tuş :")
KeyToSend := MyGui.Add("Edit", "vKeyToSend x55 y332 w50", "u")
MyGui.Add("Text", "x120 y335", "Gecikme(ms) :")
KeyDelay := MyGui.Add("Edit", "vKeyDelay x200 y332 w45", "1")

; Durum Paneli
MyGui.SetFont("s11 Bold", "Segoe UI")
MyStatus := MyGui.Add("Text", "vStatus x10 y390 w250 Center cRed", "DURDURULDU")

MyGui.Show("w270")

; --- Başlangıç Hotkey ---
Hotkey(CurrentHotkey, ToggleLogic)

; --- Fonksiyonlar ---

StartListening(*) {
    global IsListening, CurrentHotkey
    if (IsListening) {
        return
    }
    
    IsListening := true
    HK_Display.Value := "Bir tuşa bas..."
    HK_Display.SetFont("cBlue Bold")
    
    ih := InputHook("L1 T5 M")
    ih.Start()
    ih.Wait()
    
    NewKey := (ih.Input != "") ? ih.Input : ih.EndKey
    
    if (NewKey != "") {
        try {
            Hotkey(CurrentHotkey, "Off")
            CurrentHotkey := NewKey
            Hotkey(CurrentHotkey, ToggleLogic)
            HK_Display.Value := CurrentHotkey
        } catch {
            MsgBox("Hatalı tuş!")
        }
    }
    
    IsListening := false
    HK_Display.SetFont("cBlack Norm s9")
}

ToggleLogic(*) {
    global IsRunning
    if (IsRunning) {
        IsRunning := false
        MyStatus.Value := "DURDURULDU"
        MyStatus.SetFont("cRed")
        SetTimer(MouseLoop, 0)
        SetTimer(KeyLoop, 0)
    } else {
        IsRunning := true
        MyStatus.Value := "ÇALIŞIYOR"
        MyStatus.SetFont("cGreen")
        
        if (EnableMouse.Value) {
            SetTimer(MouseLoop, MouseDelay.Value)
        }
        
        if (EnableKey.Value) {
            SetTimer(KeyLoop, KeyDelay.Value)
        }
    }
}

MouseLoop() {
    global IsRunning
    if (!IsRunning) {
        return
    }
    
    btn := ClickType.Text
    if (Mode.Text = "Belirli Koordinat") {
        Click(btn " " EditX.Value " " EditY.Value)
    } else {
        Click(btn)
    }
}

KeyLoop() {
    global IsRunning
    if (!IsRunning) {
        return
    }
    Send(KeyToSend.Value)
}

ToggleCoords(*) {
    show := (Mode.Text = "Belirli Koordinat")
    XLabel.Visible := show
    EditX.Visible := show
    YLabel.Visible := show
    EditY.Visible := show
    CaptureBtn.Visible := show
}

F3:: {
    if (Mode.Text = "Belirli Koordinat") {
        MouseGetPos(&outX, &outY)
        EditX.Value := outX
        EditY.Value := outY
    }
}

GuiClose(*) => ExitApp()