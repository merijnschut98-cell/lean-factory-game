$ws = New-Object -ComObject WScript.Shell
$desktop = [Environment]::GetFolderPath('Desktop')
$sc = $ws.CreateShortcut("$desktop\Lean Factory.lnk")
$sc.TargetPath = "wscript.exe"
$sc.Arguments = "`"C:\Users\MerijnSchut\Lean Game\play_silent.vbs`""
$sc.WorkingDirectory = "C:\Users\MerijnSchut\Lean Game"
$sc.Description = "Lean Factory"
$sc.Save()
Write-Host "Shortcut created at $desktop\Lean Factory.lnk"
