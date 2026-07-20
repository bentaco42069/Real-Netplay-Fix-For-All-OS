' Claude Remote-Control - Always On: launch the keep-alive with NO visible window.
' Used by the auto-start shortcut so it runs quietly in the background from the
' moment you log in. The restart loop lives in start-claude-rc.bat, so it still
' relaunches remote-control on its own if it drops.
Set sh = CreateObject("WScript.Shell")
scriptDir = CreateObject("Scripting.FileSystemObject").GetParentFolderName(WScript.ScriptFullName)
sh.CurrentDirectory = scriptDir
' Window style 0 = hidden. NOPAUSE keeps the batch from waiting on a keypress.
sh.Run "cmd /c set CLAUDE_RC_NOPAUSE=1&& """ & scriptDir & "\start-claude-rc.bat""", 0, False
