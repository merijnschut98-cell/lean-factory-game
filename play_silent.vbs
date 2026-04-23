Set oShell = CreateObject("WScript.Shell")
oShell.CurrentDirectory = Left(WScript.ScriptFullName, InStrRev(WScript.ScriptFullName, "\") - 1)
oShell.Run ".venv\Scripts\pythonw.exe main.py", 0, False
