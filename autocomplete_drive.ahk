#Requires AutoHotkey v2.0
#SingleInstance Force
SendMode "Input"
SetWorkingDir A_ScriptDir

global DictFile := "dictionary.txt"
global Words := Map()
global Transitions := Map() 
global Phrases := Map()     ; База целых фраз
global CurrentWord := ""
global LastWord := ""       
global SentenceBuffer := "" ; Буфер текущего предложения
global Suggestions := []
global IsPaused := false
global GuiVisible := false
global AutoSpaceEnabled := false ; Галочка авто-пробела по умолчанию ВЫКЛЮЧЕНА
global BackspacePressed := false ; Флаг отслеживания нажатия Backspace перед Пробелом

; Настройка контекстного меню в трее
A_TrayMenu.Add() ; Разделитель
A_TrayMenu.Add("Авто-пробел после автозавершения", ToggleAutoSpace)

ToggleAutoSpace(ItemName, ItemPos, MyMenu) {
    global AutoSpaceEnabled
    AutoSpaceEnabled := !AutoSpaceEnabled
    if AutoSpaceEnabled
        A_TrayMenu.Check(ItemName)
    else
        A_TrayMenu.Uncheck(ItemName)
}

; Загрузка баз данных
LoadDictionary()

; Создание GUI (6 вариантов, увеличенная ширина для фраз)
global MyGui := Gui("+AlwaysOnTop -Caption +ToolWindow")
MyGui.BackColor := "2E2E2E"
MyGui.SetFont("s11", "Consolas")
global Labels := []
Loop 6 {
    Labels.Push(MyGui.Add("Text", "w380 cFFFFFF", ""))
}

; Скрываем окно при старте
MyGui.Hide()

; Создание и запуск асинхронного перехватчика
global ih := InputHook("V I")
ih.KeyOpt("{Backspace}{Space}{Enter}{Tab}{Esc}{Delete}", "E")
ih.OnChar := ProcessChar
ih.OnEnd := EndKeyHandler
ih.Start()

ProcessChar(ih, char) {
    global CurrentWord, LastWord, SentenceBuffer, IsPaused, BackspacePressed
    
    if (IsPaused) {
        CurrentWord := ""
        SentenceBuffer := ""
        LastWord := ""
        HideGui()
        return
    }
        
    BackspacePressed := false
        
    ; Буквы и дефис считаются частью слова (например, "что-то")
    if RegExMatch(char, "[a-zA-Zа-яА-ЯёЁ\-]") {
        CurrentWord .= char
        ShowSuggestions()
    } 
    ; Знаки окончания предложения (. ? !)
    else if RegExMatch(char, "[\.\?!]") {
        SentenceBuffer .= CurrentWord . char
        if InStr(SentenceBuffer, " ") { ; Сохраняем фразу, если в ней больше 1 слова
            SavePhrase(Trim(SentenceBuffer))
        }
        EndWord()
        LastWord := ""
        SentenceBuffer := ""
    } 
    ; Запятые, двоеточия и прочие знаки
    else {
        SentenceBuffer .= CurrentWord . char
        EndWord()
    }
}

EndKeyHandler(ih, *) {
    global CurrentWord, GuiVisible, IsPaused, SentenceBuffer, BackspacePressed, LastWord
    
    if (IsPaused)
        return

    if (ih.EndReason = "Stopped")
        return

    endKey := ih.EndKey
    
    if (endKey = "Backspace") {
        BackspacePressed := true
        
        if (StrLen(CurrentWord) > 0) {
            CurrentWord := SubStr(CurrentWord, 1, -1)
        } else {
            SentenceBuffer := ""
            LastWord := ""
        }
        HideGui()
    } 
    else if (endKey = "Delete") {
        if (!GuiVisible) {
            CurrentWord := ""
            HideGui()
        }
    } 
    else if (endKey = "Space") {
        SentenceBuffer .= CurrentWord . " "
        EndWord()
        ih.Start()
        
        if (BackspacePressed) {
            HideGui()
            BackspacePressed := false
        } else {
            ShowSuggestions()
        }
        return
    } 
    else if (endKey = "Enter") {
        SentenceBuffer .= CurrentWord
        if InStr(SentenceBuffer, " ") {
            SavePhrase(Trim(SentenceBuffer))
        }
        SentenceBuffer := ""
        LastWord := ""
        EndWord()
        BackspacePressed := false
    } 
    else {
        EndWord()
        BackspacePressed := false
    }
    
    ih.Start()
    
    if (BackspacePressed) {
        HideGui()
        BackspacePressed := false
    } else {
        ShowSuggestions()
    }
}

EndWord() {
    global CurrentWord
    if (StrLen(CurrentWord) > 0) {
        SaveWord(CurrentWord)
    }
    CurrentWord := ""
    HideGui()
}

ShowSuggestions() {
    global CurrentWord, Suggestions, GuiVisible, MyGui, Labels
    
    Suggestions := GetSuggestionsList(CurrentWord)
    
    if (Suggestions.Length = 0) {
        HideGui()
        return
    }
    
    Loop 6 {
        if (A_Index <= Suggestions.Length) {
            item := Suggestions[A_Index]
            
            if (item.type == "phrase") {
                text := A_Index . ". [ФРАЗА] " . item.text
            } else {
                text := A_Index . ". " . item.text
            }
            
            Labels[A_Index].Value := text
            
            if (A_Index = 1) {
                Labels[A_Index].Opt("Background1E4E79") 
            } else if (item.type == "phrase") {
                Labels[A_Index].Opt("Background4A2E4E") 
            } else {
                Labels[A_Index].Opt("Background2E2E2E")
            }
        } else {
            Labels[A_Index].Value := ""
            Labels[A_Index].Opt("Background2E2E2E")
        }
    }
    
    if (!GuiVisible) {
        MonitorGetWorkArea(, &left, &top, &right, &bottom)
        x := right - 400 
        y := bottom - 160
        MyGui.Show("x" . x . " y" . y . " NoActivate")
        GuiVisible := true
    }
}

HideGui() {
    global GuiVisible, MyGui
    MyGui.Hide()
    GuiVisible := false
}

; --- Горячие клавиши оверлея ---
#HotIf GuiVisible
; Выбор автозаполнения (1-6 и Enter)
1::Complete(1)
2::Complete(2)
3::Complete(3)
4::Complete(4)
5::Complete(5)
6::Complete(6)
Enter::Complete(1)

; Удаление вариантов (Shift + 1..6 или Shift + Delete)
+1::DeleteWord(1)
+2::DeleteWord(2)
+3::DeleteWord(3)
+4::DeleteWord(4)
+5::DeleteWord(5)
+6::DeleteWord(6)
+Delete::DeleteWord(1)
#HotIf

Complete(index) {
    global CurrentWord, Suggestions, ih, LastWord, SentenceBuffer, AutoSpaceEnabled, BackspacePressed
    if (index > Suggestions.Length)
        return
        
    item := Suggestions[index]
    selected := item.text
    
    HideGui()
    ih.Stop()
    
    selection_keys := [
        "1", "2", "3", "4", "5", "6", "Enter", "Delete",
        "numpad1", "numpad2", "numpad3", "numpad4", "numpad5", "numpad6",
        "shift", "LShift", "RShift"
    ]
    
    startTime := A_TickCount
    Loop {
        anyPressed := false
        for key in selection_keys {
            if GetKeyState(key, "P") {
                anyPressed := true
                break
            }
        }
        if (!anyPressed || A_TickCount - startTime > 500) 
            break
        Sleep(10)
    }
    
    Sleep(50)
    
    SendInput("{LShift Up}{RShift Up}")
    Sleep(20) 
    
    activeProcess := WinGetProcessName("A")
    if RegExMatch(activeProcess, "i)(chrome|opera|browser|msedge|firefox|iexplore)") {
        SendInput("{Esc}")
        Sleep(30)
    }
    
    if (item.type == "phrase") {
        backspaces := StrLen(SentenceBuffer) + StrLen(CurrentWord)
        
        if (backspaces > 0) {
            SendInput("{Delete}")
            Sleep(20)
            
            Loop backspaces {
                SendInput("{Backspace}")
                Sleep(25)
            }
            Sleep(50)
        }
        
        SendInput(selected . (AutoSpaceEnabled ? " " : ""))
        
        SentenceBuffer := ""
        LastWord := ""
        CurrentWord := ""
        
    } else {
        if (CurrentWord != "" && CurrentWord == StrUpper(CurrentWord) && StrLen(CurrentWord) > 1) {
            selected := StrUpper(selected)
        } else if (CurrentWord != "" && SubStr(CurrentWord, 1, 1) == StrUpper(SubStr(CurrentWord, 1, 1))) {
            selected := Format("{:T}", selected)
        } else {
            selected := StrLower(selected)
        }
        
        backspaces := StrLen(CurrentWord)
        if (backspaces > 0) {
            SendInput("{Delete}")
            Sleep(20)
            
            Loop backspaces {
                SendInput("{Backspace}")
                Sleep(25)
            }
            Sleep(50)
        }
        
        spaceStr := AutoSpaceEnabled ? " " : ""
        SendInput(selected . spaceStr)
        
        SaveWord(selected)
        SentenceBuffer .= selected . spaceStr
        CurrentWord := ""
    }
    
    BackspacePressed := false
    ih.Start()
    
    if (AutoSpaceEnabled) {
        ShowSuggestions()
    }
}

; Обновленная функция удаления по номеру элемента (по умолчанию 1)
DeleteWord(index := 1) {
    global Suggestions, Words, Phrases, Transitions
    if (index <= Suggestions.Length) {
        item := Suggestions[index]
        
        if (item.type == "word") {
            if Words.Has(item.text)
                Words.Delete(item.text)
        } else if (item.type == "phrase") {
            if Phrases.Has(item.text)
                Phrases.Delete(item.text)
        }
            
        SyncDictionaryToFile()
        ShowSuggestions() ; Обновляем меню на экране
    }
}

; --- Пауза и возобновление работы по F12 ---
F12:: {
    global IsPaused, ih, LastWord, SentenceBuffer, CurrentWord, BackspacePressed
    IsPaused := !IsPaused
    if (IsPaused) {
        HideGui()
        ih.Stop()
        LastWord := ""
        SentenceBuffer := ""
        CurrentWord := ""
        BackspacePressed := false
        ToolTip("Автозаполнение на ПАУЗЕ")
    } else {
        LastWord := ""
        SentenceBuffer := ""
        CurrentWord := ""
        BackspacePressed := false
        ih.Start()
        ToolTip("Автозаполнение АКТИВНО")
    }
    SetTimer(RemoveToolTip, -1000)
}

RemoveToolTip() {
    ToolTip()
}

; --- Работа с базами данных ---
LoadDictionary() {
    global DictFile, Words, Transitions, Phrases
    if !FileExist(DictFile) {
        defaultData := "теперь:10`nчто-то:10`nкое-как:10`nдругая:10`nработает:10`n"
                     . "как>у:10`nу>тебя:10`nтебя>дела:10`n"
                     . "PHRASE>как у тебя дела?:10`nPHRASE>что-то пошло не так.:10"
        FileAppend(defaultData, DictFile, "UTF-8")
    }
    Loop Read, DictFile {
        if (A_LoopReadLine = "")
            continue
            
        parts := StrSplit(A_LoopReadLine, ":")
        key := parts[1]
        freq := parts[2] ? Integer(parts[2]) : 1
        
        if InStr(key, "PHRASE>") == 1 {
            phraseText := SubStr(key, 8)
            Phrases[phraseText] := freq
        } else if InStr(key, ">") {
            Transitions[key] := freq
        } else {
            if !RegExMatch(key, "^\d+$") { 
                Words[key] := freq
            }
        }
    }
}

SaveWord(word) {
    global Words, Transitions, LastWord
    word := Format("{:L}", word)
    
    if (word == "" || RegExMatch(word, "^\d+$"))
        return
        
    if Words.Has(word)
        Words[word] += 1
    else
        Words[word] := 1
    
    if (LastWord != "") {
        transitionKey := LastWord . ">" . word
        if Transitions.Has(transitionKey)
            Transitions[transitionKey] += 1
        else
            Transitions[transitionKey] := 1
    }
    
    LastWord := word
    SyncDictionaryToFile()
}

SavePhrase(phraseText) {
    global Phrases
    if (StrLen(phraseText) < 5)
        return
        
    if Phrases.Has(phraseText)
        Phrases[phraseText] += 1
    else
        Phrases[phraseText] := 1
        
    SyncDictionaryToFile()
}

SyncDictionaryToFile() {
    global Words, Transitions, Phrases, DictFile
    
    fileContent := ""
    for w, freq in Words
        fileContent .= w . ":" . freq . "`n"
    for t, freq in Transitions
        fileContent .= t . ":" . freq . "`n"
    for p, freq in Phrases
        fileContent .= "PHRASE>" . p . ":" . freq . "`n"
        
    try {
        fileObj := FileOpen(DictFile, "w", "UTF-8")
        fileObj.Write(fileContent)
        fileObj.Close()
    } catch {
        ; Игнорируем временную блокировку диска
    }
}

GetSuggestionsList(prefix) {
    global Words, Transitions, Phrases, LastWord, SentenceBuffer
    wordList := []
    phraseList := []
    
    ; --- 1. Сбор слов и биграмм (слоты 1-4) ---
    if (prefix = "") {
        if (LastWord != "") {
            searchKey := LastWord . ">"
            len := StrLen(searchKey)
            for t, freq in Transitions {
                if (SubStr(t, 1, len) = searchKey) {
                    word2 := SubStr(t, len + 1)
                    wordList.Push({type: "word", text: word2, freq: freq})
                }
            }
        }
    } else {
        prefixLower := Format("{:L}", prefix)
        for w, freq in Words {
            if (SubStr(w, 1, StrLen(prefixLower)) = prefixLower) {
                wordList.Push({type: "word", text: w, freq: freq})
            }
        }
    }
    
    SortArrayByFreq(wordList)
    
    ; --- 2. Сбор фраз (слоты 5-6) ---
    searchPhrase := SentenceBuffer . prefix
    if (StrLen(searchPhrase) > 1) {
        searchPhraseLower := Format("{:L}", searchPhrase)
        for p, freq in Phrases {
            pLower := Format("{:L}", p)
            if (InStr(pLower, searchPhraseLower) == 1 && StrLen(p) > StrLen(searchPhrase)) {
                phraseList.Push({type: "phrase", text: p, freq: freq})
            }
        }
    }
    
    SortArrayByFreq(phraseList)
    
    ; --- 3. Финальный список ---
    finalList := []
    
    Loop wordList.Length {
        if (A_Index > 4)
            break
        finalList.Push(wordList[A_Index])
    }
    
    Loop phraseList.Length {
        if (A_Index > 2)
            break
        finalList.Push(phraseList[A_Index])
    }
    
    return finalList
}

SortArrayByFreq(arr) {
    Loop {
        swapped := false
        Loop (arr.Length - 1) {
            if (arr[A_Index].freq < arr[A_Index+1].freq) {
                temp := arr[A_Index]
                arr[A_Index] := arr[A_Index+1]
                arr[A_Index+1] := temp
                swapped := true
            }
        }
    } Until !swapped
}