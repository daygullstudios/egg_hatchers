# Generates cute placeholder PNG sprites for Nestarium.
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

$Root = (Resolve-Path (Join-Path (Join-Path $PSScriptRoot '..') 'assets\images')).Path

function New-Bitmap {
    param([scriptblock]$Draw)
    $bmp = New-Object System.Drawing.Bitmap 128, 128
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $g.Clear([System.Drawing.Color]::FromArgb(0, 0, 0, 0))
    & $Draw $g
    $g.Dispose()
    return $bmp
}

function Save-Png($bmp, $path) {
    $dir = Split-Path $path -Parent
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    $bmp.Save($path, [System.Drawing.Imaging.ImageFormat]::Png)
    $bmp.Dispose()
}

function Get-Color($r, $g, $b, $a = 255) { [System.Drawing.Color]::FromArgb($a, $r, $g, $b) }

function Draw-GradientEllipse($g, $x, $y, $w, $h, $c1, $c2) {
    $rect = [System.Drawing.Rectangle]::new([int]$x, [int]$y, [int]$w, [int]$h)
    $brush = New-Object System.Drawing.Drawing2D.LinearGradientBrush $rect, $c1, $c2, 135
    $g.FillEllipse($brush, $rect)
    $brush.Dispose()
}

function Draw-EggBase($g, $fill1, $fill2, $outline) {
    Draw-GradientEllipse $g 30 18 68 98 $fill1 $fill2
    $pen = New-Object System.Drawing.Pen $outline, 3
    $g.DrawEllipse($pen, 30, 18, 68, 98)
    $pen.Dispose()
    $hi = Get-Color 255 255 255 100
    $g.FillEllipse((New-Object System.Drawing.SolidBrush $hi), 46, 34, 22, 16)
}

function Draw-Star($g, $cx, $cy, $size, $color) {
    $brush = New-Object System.Drawing.SolidBrush $color
    $pts = @()
    for ($i = 0; $i -lt 5; $i++) {
        $a1 = [Math]::PI / 2 + $i * 4 * [Math]::PI / 5
        $a2 = $a1 + 2 * [Math]::PI / 5
        $pts += [System.Drawing.PointF]::new($cx + $size * [Math]::Cos($a1), $cy - $size * [Math]::Sin($a1))
        $pts += [System.Drawing.PointF]::new($cx + ($size * 0.4) * [Math]::Cos($a2), $cy - ($size * 0.4) * [Math]::Sin($a2))
    }
    $g.FillPolygon($brush, $pts)
    $brush.Dispose()
}

function Draw-Speckle($g, $x, $y, $color) {
    $b = New-Object System.Drawing.SolidBrush $color
    $g.FillEllipse($b, $x, $y, 4, 4)
    $b.Dispose()
}

function Draw-Eyes($g, $lx, $ly, $rx, $ry, $pupil) {
    $white = Get-Color 255 255 255
    $g.FillEllipse((New-Object System.Drawing.SolidBrush $white), $lx, $ly, 14, 16)
    $g.FillEllipse((New-Object System.Drawing.SolidBrush $white), $rx, $ry, 14, 16)
    $g.FillEllipse((New-Object System.Drawing.SolidBrush $pupil), $lx + 4, $ly + 5, 7, 8)
    $g.FillEllipse((New-Object System.Drawing.SolidBrush $pupil), $rx + 4, $ry + 5, 7, 8)
}

# --- EGGS ---
$eggs = @{
    'basic_egg' = { param($g)
        Draw-EggBase $g (Get-Color 255 248 220) (Get-Color 255 230 180) (Get-Color 210 170 120)
        Draw-Speckle $g 52 58 (Get-Color 220 190 140)
        Draw-Speckle $g 64 72 (Get-Color 220 190 140)
        Draw-Speckle $g 58 84 (Get-Color 220 190 140)
    }
    'forest_egg' = { param($g)
        Draw-EggBase $g (Get-Color 190 230 170) (Get-Color 120 180 100) (Get-Color 70 130 60)
        $leaf = Get-Color 60 140 50
        $g.FillEllipse((New-Object System.Drawing.SolidBrush $leaf), 48, 70, 18, 10)
        $g.FillEllipse((New-Object System.Drawing.SolidBrush $leaf), 62, 78, 16, 9)
    }
    'farm_egg' = { param($g)
        Draw-EggBase $g (Get-Color 255 240 210) (Get-Color 230 200 150) (Get-Color 180 140 90)
        $hay = Get-Color 220 180 80
        $g.FillRectangle((New-Object System.Drawing.SolidBrush $hay), 44, 88, 40, 8)
        $g.FillRectangle((New-Object System.Drawing.SolidBrush $hay), 50, 82, 6, 14)
    }
    'magic_egg' = { param($g)
        Draw-EggBase $g (Get-Color 230 200 255) (Get-Color 170 120 230) (Get-Color 120 70 180)
        Draw-Star $g 54 62 8 (Get-Color 255 240 120)
        Draw-Star $g 72 78 5 (Get-Color 255 220 255)
    }
    'jungle_egg' = { param($g)
        Draw-EggBase $g (Get-Color 170 220 120) (Get-Color 90 160 70) (Get-Color 50 110 40)
        $g.FillEllipse((New-Object System.Drawing.SolidBrush (Get-Color 50 130 40)), 42, 55, 20, 12)
        $g.FillEllipse((New-Object System.Drawing.SolidBrush (Get-Color 40 100 35)), 60, 68, 18, 11)
    }
    'ocean_egg' = { param($g)
        Draw-EggBase $g (Get-Color 180 230 255) (Get-Color 80 170 230) (Get-Color 40 120 190)
        $wave = New-Object System.Drawing.Pen (Get-Color 255 255 255 180), 3
        $g.DrawArc($wave, 38, 58, 50, 20, 0, 180)
        $g.DrawArc($wave, 42, 72, 46, 18, 180, 180)
        $wave.Dispose()
    }
    'arctic_egg' = { param($g)
        Draw-EggBase $g (Get-Color 230 245 255) (Get-Color 180 210 240) (Get-Color 120 160 200)
        $snow = Get-Color 255 255 255
        $g.DrawLine((New-Object System.Drawing.Pen $snow, 2), 54, 50, 54, 62)
        $g.DrawLine((New-Object System.Drawing.Pen $snow, 2), 48, 56, 60, 56)
        $g.DrawLine((New-Object System.Drawing.Pen $snow, 2), 68, 74, 68, 86)
        $g.DrawLine((New-Object System.Drawing.Pen $snow, 2), 62, 80, 74, 80)
    }
    'dino_egg' = { param($g)
        Draw-EggBase $g (Get-Color 200 220 140) (Get-Color 140 170 90) (Get-Color 90 120 50)
        Draw-Speckle $g 48 52 (Get-Color 90 110 50)
        Draw-Speckle $g 66 64 (Get-Color 90 110 50)
        $crack = New-Object System.Drawing.Pen (Get-Color 80 60 40), 2
        $g.DrawLine($crack, 58, 40, 62, 55)
        $g.DrawLine($crack, 62, 55, 56, 68)
        $crack.Dispose()
    }
    'space_egg' = { param($g)
        Draw-EggBase $g (Get-Color 80 60 150) (Get-Color 30 20 80) (Get-Color 20 10 60)
        Draw-Star $g 50 58 4 (Get-Color 255 255 200)
        Draw-Star $g 72 70 3 (Get-Color 200 180 255)
        Draw-Star $g 60 88 3 (Get-Color 180 220 255)
        $g.FillEllipse((New-Object System.Drawing.SolidBrush (Get-Color 120 80 200 120)), 52, 72, 20, 12)
    }
}

foreach ($kv in $eggs.GetEnumerator()) {
    $bmp = New-Bitmap $kv.Value
    Save-Png $bmp (Join-Path (Join-Path $Root 'eggs') "$($kv.Key).png")
}

# --- ANIMALS ---
function Draw-BodyRound($g, $x, $y, $w, $h, $c1, $c2, $outline) {
    Draw-GradientEllipse $g $x $y $w $h $c1 $c2
    $pen = New-Object System.Drawing.Pen $outline, 3
    $g.DrawEllipse($pen, $x, $y, $w, $h)
    $pen.Dispose()
}

$animals = @{
    'chicken' = { param($g)
        Draw-BodyRound $g 28 50 72 58 (Get-Color 255 220 100) (Get-Color 255 180 60) (Get-Color 200 130 30)
        $g.FillEllipse((New-Object System.Drawing.SolidBrush (Get-Color 255 120 60)), 78, 48, 14, 12)
        Draw-Eyes $g 48 62 68 62 (Get-Color 40 30 20)
        $g.FillPolygon((New-Object System.Drawing.SolidBrush (Get-Color 255 100 50)), @(
            [System.Drawing.Point]::new(88, 52), [System.Drawing.Point]::new(100, 56), [System.Drawing.Point]::new(88, 60)))
    }
    'mouse' = { param($g)
        Draw-BodyRound $g 30 58 68 52 (Get-Color 190 190 200) (Get-Color 140 140 155) (Get-Color 90 90 100)
        $g.FillEllipse((New-Object System.Drawing.SolidBrush (Get-Color 180 170 185)), 34, 28, 22, 34)
        $g.FillEllipse((New-Object System.Drawing.SolidBrush (Get-Color 180 170 185)), 72, 28, 22, 34)
        Draw-Eyes $g 50 72 70 72 (Get-Color 30 30 40)
    }
    'rabbit' = { param($g)
        $g.FillEllipse((New-Object System.Drawing.SolidBrush (Get-Color 245 220 230)), 36, 8, 18, 44)
        $g.FillEllipse((New-Object System.Drawing.SolidBrush (Get-Color 245 220 230)), 74, 8, 18, 44)
        Draw-BodyRound $g 28 48 72 62 (Get-Color 255 240 245) (Get-Color 230 200 215) (Get-Color 190 150 170)
        Draw-Eyes $g 48 68 68 68 (Get-Color 50 40 50)
        $g.FillEllipse((New-Object System.Drawing.SolidBrush (Get-Color 255 180 190)), 56, 82, 10, 8)
    }
    'fox' = { param($g)
        $g.FillPolygon((New-Object System.Drawing.SolidBrush (Get-Color 230 120 50)), @(
            [System.Drawing.Point]::new(30, 70), [System.Drawing.Point]::new(20, 30), [System.Drawing.Point]::new(42, 50)))
        $g.FillPolygon((New-Object System.Drawing.SolidBrush (Get-Color 230 120 50)), @(
            [System.Drawing.Point]::new(98, 70), [System.Drawing.Point]::new(108, 30), [System.Drawing.Point]::new(86, 50)))
        Draw-BodyRound $g 26 44 76 68 (Get-Color 255 150 70) (Get-Color 210 90 35) (Get-Color 160 60 20)
        Draw-Eyes $g 48 62 68 62 (Get-Color 40 25 15)
        $g.FillEllipse((New-Object System.Drawing.SolidBrush (Get-Color 255 230 210)), 52, 78, 24, 20)
    }
    'cow' = { param($g)
        Draw-BodyRound $g 24 52 80 58 (Get-Color 250 250 255) (Get-Color 220 225 235) (Get-Color 80 80 90)
        $g.FillEllipse((New-Object System.Drawing.SolidBrush (Get-Color 50 50 60)), 36, 58, 16, 12)
        $g.FillEllipse((New-Object System.Drawing.SolidBrush (Get-Color 50 50 60)), 72, 70, 18, 14)
        Draw-Eyes $g 46 66 66 66 (Get-Color 30 30 35)
        $g.FillEllipse((New-Object System.Drawing.SolidBrush (Get-Color 255 200 200)), 54, 84, 16, 12)
    }
    'dragon' = { param($g)
        $g.FillPolygon((New-Object System.Drawing.SolidBrush (Get-Color 80 180 90)), @(
            [System.Drawing.Point]::new(18, 50), [System.Drawing.Point]::new(8, 28), [System.Drawing.Point]::new(28, 36)))
        Draw-BodyRound $g 24 40 72 72 (Get-Color 120 210 110) (Get-Color 60 150 70) (Get-Color 30 100 40)
        Draw-Eyes $g 46 58 66 58 (Get-Color 20 60 25)
        $g.FillEllipse((New-Object System.Drawing.SolidBrush (Get-Color 255 120 80)), 78, 52, 16, 14)
        $g.FillPolygon((New-Object System.Drawing.SolidBrush (Get-Color 255 90 70)), @(
            [System.Drawing.Point]::new(88, 58), [System.Drawing.Point]::new(108, 62), [System.Drawing.Point]::new(88, 68)))
    }
    'unicorn' = { param($g)
        $g.FillRectangle((New-Object System.Drawing.SolidBrush (Get-Color 255 200 230)), 60, 6, 8, 28)
        Draw-BodyRound $g 26 46 76 66 (Get-Color 255 250 255) (Get-Color 230 220 245) (Get-Color 180 160 200)
        $g.FillEllipse((New-Object System.Drawing.SolidBrush (Get-Color 255 180 220)), 30, 52, 18, 28)
        $g.FillEllipse((New-Object System.Drawing.SolidBrush (Get-Color 180 220 255)), 78, 52, 16, 26)
        Draw-Eyes $g 48 64 68 64 (Get-Color 80 60 120)
        $g.FillEllipse((New-Object System.Drawing.SolidBrush (Get-Color 255 190 210)), 54, 84, 14, 10)
    }
    'fossil_dragon' = { param($g)
        Draw-BodyRound $g 22 38 84 76 (Get-Color 235 220 190) (Get-Color 190 170 140) (Get-Color 130 110 85)
        $g.FillEllipse((New-Object System.Drawing.SolidBrush (Get-Color 210 195 165)), 34, 30, 28, 22)
        $g.FillEllipse((New-Object System.Drawing.SolidBrush (Get-Color 210 195 165)), 66, 30, 28, 22)
        Draw-Eyes $g 46 56 66 56 (Get-Color 60 50 40)
        $bone = Get-Color 255 245 220
        $g.DrawLine((New-Object System.Drawing.Pen $bone, 3), 40, 78, 52, 92)
        $g.DrawLine((New-Object System.Drawing.Pen $bone, 3), 76, 78, 64, 92)
        $g.FillEllipse((New-Object System.Drawing.SolidBrush (Get-Color 180 160 130)), 48, 88, 32, 16)
    }
    'galaxy_dragon' = { param($g)
        Draw-BodyRound $g 22 38 84 76 (Get-Color 100 70 180) (Get-Color 40 25 90) (Get-Color 20 10 50)
        Draw-Star $g 40 52 4 (Get-Color 255 255 200)
        Draw-Star $g 78 64 3 (Get-Color 200 180 255)
        Draw-Star $g 58 80 3 (Get-Color 180 220 255)
        Draw-Eyes $g 46 56 66 56 (Get-Color 200 180 255)
        $g.FillEllipse((New-Object System.Drawing.SolidBrush (Get-Color 120 80 200 100)), 50, 72, 28, 14)
    }
    'alien_slime' = { param($g)
        Draw-BodyRound $g 24 44 80 68 (Get-Color 140 255 120) (Get-Color 60 190 70) (Get-Color 30 130 40)
        $g.FillRectangle((New-Object System.Drawing.SolidBrush (Get-Color 100 220 90)), 58, 18, 6, 22)
        $g.FillEllipse((New-Object System.Drawing.SolidBrush (Get-Color 120 240 100)), 56, 10, 12, 12)
        Draw-Eyes $g 44 58 68 58 (Get-Color 20 80 30)
    }
    'moon_cat' = { param($g)
        $g.FillEllipse((New-Object System.Drawing.SolidBrush (Get-Color 220 220 240)), 78, 18, 28, 28)
        Draw-BodyRound $g 26 48 76 62 (Get-Color 90 100 150) (Get-Color 50 60 110) (Get-Color 30 35 80)
        $g.FillPolygon((New-Object System.Drawing.SolidBrush (Get-Color 70 80 130)), @(
            [System.Drawing.Point]::new(32, 48), [System.Drawing.Point]::new(28, 24), [System.Drawing.Point]::new(44, 38)))
        $g.FillPolygon((New-Object System.Drawing.SolidBrush (Get-Color 70 80 130)), @(
            [System.Drawing.Point]::new(96, 48), [System.Drawing.Point]::new(100, 24), [System.Drawing.Point]::new(84, 38)))
        Draw-Eyes $g 48 66 68 66 (Get-Color 255 240 180)
        Draw-Star $g 88 26 4 (Get-Color 255 255 220)
    }
    'star_fox' = { param($g)
        Draw-BodyRound $g 26 46 76 66 (Get-Color 255 170 80) (Get-Color 220 110 40) (Get-Color 160 70 20)
        $g.FillPolygon((New-Object System.Drawing.SolidBrush (Get-Color 240 140 50)), @(
            [System.Drawing.Point]::new(28, 58), [System.Drawing.Point]::new(14, 32), [System.Drawing.Point]::new(38, 44)))
        Draw-Star $g 88 30 6 (Get-Color 255 240 120)
        Draw-Eyes $g 48 64 68 64 (Get-Color 40 25 15)
        $g.FillEllipse((New-Object System.Drawing.SolidBrush (Get-Color 255 230 200)), 52, 82, 22, 16)
    }
    't_rex' = { param($g)
        Draw-BodyRound $g 20 52 88 58 (Get-Color 130 200 100) (Get-Color 70 150 60) (Get-Color 40 100 35)
        Draw-BodyRound $g 34 28 60 48 (Get-Color 140 210 110) (Get-Color 80 160 70) (Get-Color 40 100 35)
        Draw-Eyes $g 48 42 66 42 (Get-Color 25 60 20)
        $g.FillRectangle((New-Object System.Drawing.SolidBrush (Get-Color 255 120 90)), 70, 48, 20, 8)
        $g.FillRectangle((New-Object System.Drawing.SolidBrush (Get-Color 60 120 50)), 24, 88, 10, 16)
        $g.FillRectangle((New-Object System.Drawing.SolidBrush (Get-Color 60 120 50)), 78, 88, 10, 16)
    }
    'triceratops' = { param($g)
        Draw-BodyRound $g 24 54 80 56 (Get-Color 120 190 220) (Get-Color 70 140 190) (Get-Color 40 90 140)
        $g.FillEllipse((New-Object System.Drawing.SolidBrush (Get-Color 90 170 210)), 20, 44, 88, 24)
        $g.FillRectangle((New-Object System.Drawing.SolidBrush (Get-Color 200 180 160)), 36, 36, 8, 16)
        $g.FillRectangle((New-Object System.Drawing.SolidBrush (Get-Color 200 180 160)), 84, 36, 8, 16)
        Draw-Eyes $g 46 66 66 66 (Get-Color 30 60 90)
    }
    'shark' = { param($g)
        $g.FillPolygon((New-Object System.Drawing.SolidBrush (Get-Color 90 170 230)), @(
            [System.Drawing.Point]::new(64, 20), [System.Drawing.Point]::new(72, 44), [System.Drawing.Point]::new(56, 44)))
        $g.FillEllipse((New-Object System.Drawing.SolidBrush (Get-Color 120 190 240)), 18, 48, 92, 48)
        $g.FillEllipse((New-Object System.Drawing.SolidBrush (Get-Color 70 140 210)), 18, 58, 92, 38)
        Draw-Eyes $g 72 62 88 62 (Get-Color 25 50 80)
        $g.FillPolygon((New-Object System.Drawing.SolidBrush (Get-Color 240 240 250)), @(
            [System.Drawing.Point]::new(100, 68), [System.Drawing.Point]::new(118, 72), [System.Drawing.Point]::new(100, 78)))
    }
    'polar_bear' = { param($g)
        Draw-BodyRound $g 22 50 84 58 (Get-Color 250 252 255) (Get-Color 210 225 240) (Get-Color 140 170 200)
        $g.FillEllipse((New-Object System.Drawing.SolidBrush (Get-Color 235 242 250)), 30, 32, 24, 24)
        $g.FillEllipse((New-Object System.Drawing.SolidBrush (Get-Color 235 242 250)), 74, 32, 24, 24)
        Draw-Eyes $g 46 66 66 66 (Get-Color 50 70 100)
        $g.FillEllipse((New-Object System.Drawing.SolidBrush (Get-Color 180 210 235)), 52, 84, 18, 12)
    }
    'snow_owl' = { param($g)
        Draw-BodyRound $g 26 48 76 62 (Get-Color 250 252 255) (Get-Color 210 220 235) (Get-Color 140 160 190)
        $g.FillEllipse((New-Object System.Drawing.SolidBrush (Get-Color 180 200 220)), 38, 56, 52, 40)
        Draw-Eyes $g 46 64 66 64 (Get-Color 20 30 50)
        $g.FillPolygon((New-Object System.Drawing.SolidBrush (Get-Color 200 215 230)), @(
            [System.Drawing.Point]::new(30, 46), [System.Drawing.Point]::new(22, 22), [System.Drawing.Point]::new(40, 34)))
        $g.FillPolygon((New-Object System.Drawing.SolidBrush (Get-Color 200 215 230)), @(
            [System.Drawing.Point]::new(98, 46), [System.Drawing.Point]::new(106, 22), [System.Drawing.Point]::new(88, 34)))
        $g.FillEllipse((New-Object System.Drawing.SolidBrush (Get-Color 255 180 100)), 56, 78, 12, 10)
    }
}

foreach ($kv in $animals.GetEnumerator()) {
    $bmp = New-Bitmap $kv.Value
    Save-Png $bmp (Join-Path (Join-Path $Root 'animals') "$($kv.Key).png")
}

Write-Host "Generated $($eggs.Count) egg sprites and $($animals.Count) animal sprites in $Root"
