# Shows navigable menu of all options when hitting Tab
Set-PSReadlineKeyHandler -Key Tab -Function MenuComplete

# Autocompletion for arrow keys
Set-PSReadlineKeyHandler -Key UpArrow -Function HistorySearchBackward
Set-PSReadlineKeyHandler -Key DownArrow -Function HistorySearchForward

# auto suggestions
Import-Module PSReadLine
Set-PSReadLineOption -PredictionSource History

# emaics mode
Set-PSReadLineOption -EditMode Emacs
# Set-PSReadLineKeyHandler -Key Ctrl+p -Function HistorySearchBackward
# Set-PSReadlineKeyHandler -Key Ctrl+n -Function HistorySearchForward
# Set-PSReadLineKeyHandler -Key Ctrl+u -Function RevertLine