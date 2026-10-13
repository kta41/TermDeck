$ErrorActionPreference = 'Stop'

$wezterm = (Get-Command wezterm.exe -ErrorAction Stop).Source
$root = Split-Path -Parent $PSScriptRoot
$config = Join-Path $root 'wezterm\wezterm.lua'
$cockpitInit = Join-Path $root 'wezterm\cockpit\init.lua'
$palette = Join-Path $root 'wezterm\cockpit\palette.lua'
$shellHook = Join-Path $root 'scripts\shell-hook.sh'
$shellRcfile = Join-Path $root 'scripts\wezterm-bashrc'
$helpFile = Join-Path $root 'scripts\HELP.txt'
$runtimeFiles = @(
  (Join-Path $root 'wezterm\cockpit\runtime.lua'),
  (Join-Path $root 'wezterm\cockpit\focus.lua'),
  (Join-Path $root 'wezterm\cockpit\notifications.lua'),
  (Join-Path $root 'wezterm\cockpit\layout.lua')
)
$windowsHelper = Join-Path $root 'scripts\termdeck-windows.ps1'

if (-not (Test-Path -LiteralPath $config)) {
  throw "WezTerm config not found: $config"
}
if (-not (Test-Path -LiteralPath $cockpitInit)) {
  throw "Cockpit entry point not found: $cockpitInit"
}
if (-not (Test-Path -LiteralPath $palette)) {
  throw "Cockpit palette not found: $palette"
}
if (-not (Test-Path -LiteralPath $shellHook)) {
  throw "Shell hook not found: $shellHook"
}
if (-not (Test-Path -LiteralPath $shellRcfile)) {
  throw "WezTerm Bash rcfile not found: $shellRcfile"
}
if (-not (Test-Path -LiteralPath $helpFile)) {
  throw "Help file not found: $helpFile"
}
if (-not (Test-Path -LiteralPath $windowsHelper)) {
  throw "Windows helper not found: $windowsHelper"
}
foreach ($runtimeFile in $runtimeFiles) {
  if (-not (Test-Path -LiteralPath $runtimeFile)) {
    throw "Cockpit runtime module not found: $runtimeFile"
  }
}

$keys = & $wezterm show-keys --lua 2>&1
if ($LASTEXITCODE -ne 0) {
  throw "WezTerm rejected the configuration:`n$($keys -join "`n")"
}

$source = Get-Content -LiteralPath $config -Raw
$cockpitSource = Get-Content -LiteralPath $cockpitInit -Raw
$paletteSource = Get-Content -LiteralPath $palette -Raw
$shellHookSource = Get-Content -LiteralPath $shellHook -Raw
foreach ($check in @(
    @{ Name = 'direct Ctrl+P palette'; Pattern = "key = 'p',\s*mods = 'CTRL'" },
    @{ Name = 'Ctrl+H help overlay'; Pattern = "key = 'h',\s*mods = 'CTRL'" },
    @{ Name = 'leader palette'; Pattern = "key = cfg\.palette_key\.key" },
    @{ Name = 'F9 palette'; Pattern = "key = 'F9'" }
  )) {
  if ($cockpitSource -notmatch $check.Pattern) {
    throw "Missing $($check.Name) in cockpit wiring."
  }
}
if ($source -notmatch 'show_new_tab_button_in_tab_bar\s*=\s*true') {
  throw 'The tab-bar launcher button is not explicitly enabled.'
}
if ($source -notmatch "(?s)name\s*=\s*'WSL:Debian'.*?default_prog\s*=\s*\{\s*'/bin/bash',\s*'--rcfile',\s*'/mnt/c/dev/dotfiles/scripts/wezterm-bashrc',\s*'-i'\s*\}") {
  throw 'The explicit Debian WSL domain has no login shell.'
}
if ($source -notmatch "label\s*=\s*'Debian \(WSL\)'") {
  throw 'The launcher has no explicit Debian entry.'
}
if ($source -notmatch "domain\s*=\s*\{\s*DomainName\s*=\s*'WSL:Debian'\s*\}") {
  throw 'The Debian launcher entry does not target the WSL domain.'
}
if ($source -notmatch 'config\.launch_menu\s*=\s*\{') {
  throw 'The launcher menu has no entries.'
}
if ($cockpitSource -notmatch 'action_callback\(help\.open\)') {
  throw 'Ctrl+H does not open the native help overlay.'
}
if ($shellHookSource -notmatch '\\033\]2;%s > %s\\007') {
  throw 'The shell hook does not publish directory and command titles.'
}
if ((Get-Content -LiteralPath $shellRcfile -Raw) -notmatch 'shell-hook\.sh') {
  throw 'The WezTerm Bash rcfile does not load the shell hook.'
}
if ($paletteSource -notmatch 'focus\.toggle' -or $paletteSource -notmatch 'layout\.prompt_save' -or $paletteSource -notmatch 'embed\.open') {
  throw 'The cockpit palette does not expose focus, layout and embed actions.'
}
$helpSource = Get-Content -LiteralPath $helpFile -Raw
foreach ($helpEntry in @('attach desktop app', 'detach desktop app', 'focus mode', 'save layout')) {
  if ($helpSource -notmatch [regex]::Escape($helpEntry)) {
    throw "Help is missing the current action: $helpEntry"
  }
}

Write-Output 'PASS: WezTerm config loads and exposes Ctrl+P, Ctrl+H, LEADER+P, F9, and the launcher button.'
