param(
  [Parameter(Mandatory=$true)][string]$Src,   # source dir, e.g. 设计源\v3.1.1\BACnet
  [string]$Name = "",                          # output subfolder name (default: leaf of Src)
  [int]$TileH = 2400,                          # tile height
  [int]$Overlap = 200                          # overlap between tiles, avoid cutting text
)
# Slice tall PNGs in $Src into full-width vertical tiles -> _临时\tiles\<Name>\
# Purpose: let AI read very tall design boards clearly, section by section.

Add-Type -AssemblyName System.Drawing
$root = Split-Path -Parent $PSScriptRoot
if (-not (Test-Path $Src)) { $Src = Join-Path $root $Src }
if ([string]::IsNullOrWhiteSpace($Name)) { $Name = Split-Path $Src -Leaf }
$out = Join-Path $root "_临时\tiles\$Name"
New-Item -ItemType Directory -Force -Path $out | Out-Null
$step = $TileH - $Overlap

Get-ChildItem $Src -Filter *.png | ForEach-Object {
  $img = [System.Drawing.Image]::FromFile($_.FullName)
  $w = $img.Width; $h = $img.Height
  $base = [System.IO.Path]::GetFileNameWithoutExtension($_.Name)
  $idx = 0; $y = 0
  while ($y -lt $h) {
    $curH = [Math]::Min($TileH, $h - $y)
    if ($curH -le 0) { break }
    $idx++
    $tile = New-Object System.Drawing.Bitmap($w, $curH)
    $g = [System.Drawing.Graphics]::FromImage($tile)
    $g.DrawImage($img, (New-Object System.Drawing.Rectangle(0,0,$w,$curH)), 0, $y, $w, $curH, [System.Drawing.GraphicsUnit]::Pixel)
    $g.Dispose()
    $tile.Save((Join-Path $out ("{0}__{1:D2}.png" -f $base,$idx)), [System.Drawing.Imaging.ImageFormat]::Png)
    $tile.Dispose()
    if ($curH -lt $TileH) { break }
    $y += $step
  }
  $img.Dispose()
  Write-Output ("{0} -> {1} tiles" -f $base, $idx)
}
Write-Output ("out: {0}" -f $out)
