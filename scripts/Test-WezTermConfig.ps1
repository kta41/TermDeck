$ErrorActionPreference = 'Stop'

$wezterm = (Get-Command wezterm.exe -ErrorAction Stop).Source
$root = Split-Path -Parent $PSScriptRoot
$config = Join-Path $root 'wezterm\wezterm.lua'

if (-not (Test-Path -LiteralPath $config)) {
  throw "WezTerm config not found: $config"
}

$keys = & $wezterm show-keys --lua 2>&1
if ($LASTEXITCODE -ne 0) {
  throw "WezTerm rejected the configuration:`n$($keys -join "`n")"
}

$text = $keys -join "`n"
$required = @(
  @{ Name = 'direct Ctrl+P palette'; Pattern = "key = 'p', mods = 'CTRL'" },
  @{ Name = 'Ctrl+H help tab'; Pattern = "key = 'h', mods = 'CTRL'" },
  @{ Name = 'leader palette'; Pattern = "key = 'p', mods = 'LEADER'" },
  @{ Name = 'F9 palette'; Pattern = "key = 'F9'" }
)

foreach ($check in $required) {
  if ($text -notmatch [regex]::Escape($check.Pattern)) {
    throw "Missing $($check.Name) in effective WezTerm keymap."
  }
}

$source = Get-Content -LiteralPath $config -Raw
if ($source -notmatch 'show_new_tab_button_in_tab_bar\s*=\s*true') {
  throw 'The tab-bar launcher button is not explicitly enabled.'
}
if ($source -notmatch 'config\.launch_menu\s*=\s*\{') {
  throw 'The launcher menu has no entries.'
}

Write-Output 'PASS: WezTerm config loads and exposes Ctrl+P, Ctrl+H, LEADER+P, F9, and the launcher button.'
