param(
  [Parameter(Mandatory = $true)]
  [ValidateSet('list', 'attach', 'detach')]
  [string]$Action,
  [Int64]$Handle,
  [int]$Left,
  [int]$Top,
  [int]$Width,
  [int]$Height
)

$ErrorActionPreference = 'Stop'

Add-Type @'
using System;
using System.Text;
using System.Runtime.InteropServices;
public static class TermDeckWin32 {
  public delegate bool EnumWindowsProc(IntPtr hWnd, IntPtr lParam);
  [DllImport("user32.dll")] public static extern bool EnumWindows(EnumWindowsProc callback, IntPtr extra);
  [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr hWnd);
  [DllImport("user32.dll")] public static extern int GetWindowText(IntPtr hWnd, StringBuilder text, int count);
  [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint processId);
  [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr hWnd, out RECT rect);
  [DllImport("user32.dll")] public static extern bool SetWindowPos(IntPtr hWnd, IntPtr insertAfter, int x, int y, int cx, int cy, uint flags);
  [DllImport("user32.dll")] public static extern IntPtr GetForegroundWindow();
  [StructLayout(LayoutKind.Sequential)] public struct RECT { public int Left; public int Top; public int Right; public int Bottom; }
  public const uint SWP_NOZORDER = 0x0004;
  public const uint SWP_SHOWWINDOW = 0x0040;
}
'@

function Get-Title([IntPtr]$window) {
  $text = New-Object Text.StringBuilder 512
  [void][TermDeckWin32]::GetWindowText($window, $text, $text.Capacity)
  return $text.ToString()
}

if ($Action -eq 'list') {
  $items = New-Object Collections.Generic.List[string]
  [TermDeckWin32]::EnumWindows({
    param($window, $extra)
    if (-not [TermDeckWin32]::IsWindowVisible($window)) { return $true }
    $title = Get-Title $window
    if ([string]::IsNullOrWhiteSpace($title)) { return $true }
    $processId = 0
    [void][TermDeckWin32]::GetWindowThreadProcessId($window, [ref]$processId)
    $process = Get-Process -Id $processId -ErrorAction SilentlyContinue
    if ($null -eq $process -or $process.ProcessName -in @('ApplicationFrameHost', 'TextInputHost')) { return $true }
    $items.Add(('{0}`t{1}`t{2}' -f $window.ToInt64(), $process.ProcessName, $title))
    return $true
  }, [IntPtr]::Zero)
  $items
  exit 0
}

if ($Action -eq 'detach') {
  $state = Join-Path $env:TEMP 'termdeck-embed.state'
  if (-not (Test-Path $state)) { exit 0 }
  $values = @{}
  Get-Content $state | ForEach-Object {
    $key, $value = $_ -split '=', 2
    $values[$key] = [int]$value
  }
  $window = [IntPtr]$values.handle
  [void][TermDeckWin32]::SetWindowPos($window, [IntPtr]::Zero, $values.left, $values.top, $values.width, $values.height, [TermDeckWin32]::SWP_NOZORDER)
  Remove-Item -LiteralPath $state -Force
  exit 0
}

if ($Handle -le 0) { throw 'A valid window handle is required.' }
$target = [IntPtr]$Handle
$rect = New-Object TermDeckWin32+RECT
if (-not [TermDeckWin32]::GetWindowRect($target, [ref]$rect)) { throw 'Could not read target window bounds.' }
$state = Join-Path $env:TEMP 'termdeck-embed.state'
@(
  "handle=$Handle"
  "left=$($rect.Left)"
  "top=$($rect.Top)"
  "width=$($rect.Right - $rect.Left)"
  "height=$($rect.Bottom - $rect.Top)"
) | Set-Content -LiteralPath $state -Encoding ascii

$hostWindow = [TermDeckWin32]::GetForegroundWindow()
$hostRect = New-Object TermDeckWin32+RECT
if (-not [TermDeckWin32]::GetWindowRect($hostWindow, [ref]$hostRect)) { throw 'Could not read WezTerm bounds.' }
[void][TermDeckWin32]::SetWindowPos($target, [IntPtr]::Zero, $hostRect.Left, $hostRect.Top, $hostRect.Right - $hostRect.Left, $hostRect.Bottom - $hostRect.Top, [TermDeckWin32]::SWP_NOZORDER -bor [TermDeckWin32]::SWP_SHOWWINDOW)
