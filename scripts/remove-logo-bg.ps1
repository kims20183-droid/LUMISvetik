Add-Type -AssemblyName System.Drawing

$root = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
if (-not (Test-Path (Join-Path $root "images\logo.png"))) {
    $root = Split-Path -Parent $PSScriptRoot
}

$input = Join-Path $root "images\logo.png"
$output = Join-Path $root "images\logo-transparent.png"

$src = [System.Drawing.Bitmap]::FromFile($input)
$w = $src.Width
$h = $src.Height
$dst = New-Object System.Drawing.Bitmap $w, $h, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)

function Get-Alpha([int]$r, [int]$g, [int]$b) {
    $lum = 0.2126 * $r + 0.7152 * $g + 0.0722 * $b
    $maxC = [Math]::Max($r, [Math]::Max($g, $b))
    $minC = [Math]::Min($r, [Math]::Min($g, $b))
    $chroma = $maxC - $minC

    if ($lum -lt 22 -and $maxC -lt 32) { return 0 }

    if ($lum -lt 48 -and $chroma -lt 55 -and $maxC -lt 70) {
        $t = (48 - $lum) / 48
        return [int](255 * (1 - [Math]::Min(1, $t * 1.1)))
    }

    if ($lum -lt 72 -and $chroma -lt 35) {
        $t = (72 - $lum) / 72
        return [int](255 * (1 - $t * 0.75))
    }

    return 255
}

for ($y = 0; $y -lt $h; $y++) {
    for ($x = 0; $x -lt $w; $x++) {
        $c = $src.GetPixel($x, $y)
        $a = Get-Alpha $c.R $c.G $c.B
        $na = [Math]::Min($c.A, $a)
        $dst.SetPixel($x, $y, [System.Drawing.Color]::FromArgb($na, $c.R, $c.G, $c.B))
    }
}

$dst.Save($output, [System.Drawing.Imaging.ImageFormat]::Png)
$src.Dispose()
$dst.Dispose()

Write-Host "Saved: $output"
