# set PowerShell to UTF-8
[console]::InputEncoding = [console]::OutputEncoding = New-Object System.Text.UTF8Encoding

# posh-git
Import-Module posh-git

# oh-my-posh
# https://ohmyposh.dev/docs
$omp_config = Join-Path $PSScriptRoot ".\xxx.omp.json"
oh-my-posh --init --shell pwsh --config $omp_config | Invoke-Expression

# terminal-icons
Import-Module -Name Terminal-Icons

# PSReadLine
# Get-Module PSReadLine -> check load PSReadLine status
# Install-Module -Name PSReadLine -Scope CurrentUser
Set-PSReadLineOption -EditMode Emacs
Set-PSReadLineOption -BellStyle None
Set-PSReadLineOption -PredictionSource History

# Fzf
Import-Module PSFzf
Set-PsFzfOption -PSReadlineChordProvider 'Ctrl+f' -PSReadlineChordReverseHistory 'Ctrl+r'

# Alias
Set-Alias -Name vim -Value nvim
Set-Alias -Name pwsh -Value powershell
Set-Alias -Name tig -Value 'GIT_PATH\usr\bin\tig.exe'
Set-Alias -Name less -Value 'GIT_PATH\usr\bin\less.exe'

# Env
$env:editor = 'nvim'
$env:pager = 'less'
$env:shell = 'powershell'

# which command like Unix
function which ($command) {
  Get-Command -Name $command -ErrorAction SilentlyContinue |
    Select-Object -ExpandProperty Path -ErrorAction SilentlyContinue
}
