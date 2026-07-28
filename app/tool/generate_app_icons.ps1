param(
    [string]$ProjectRoot = (Split-Path -Parent $PSScriptRoot)
)

Add-Type -AssemblyName System.Drawing

$backgroundColor = [System.Drawing.ColorTranslator]::FromHtml('#F8FBEE')
$brandColor = [System.Drawing.ColorTranslator]::FromHtml('#50752D')

function New-ServiUpIcon {
    param([int]$Size)

    $bitmap = [System.Drawing.Bitmap]::new(
        $Size,
        $Size,
        [System.Drawing.Imaging.PixelFormat]::Format32bppArgb
    )
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
    $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $graphics.Clear($backgroundColor)

    $scale = $Size * 0.70 / 300
    $offsetX = ($Size - (168 * $scale)) / 2
    $offsetY = ($Size - (300 * $scale)) / 2
    $graphics.TranslateTransform($offsetX, $offsetY)
    $graphics.ScaleTransform($scale, $scale)

    $pen = [System.Drawing.Pen]::new($brandColor, 21)
    $pen.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
    $pen.EndCap = [System.Drawing.Drawing2D.LineCap]::Round
    $pen.LineJoin = [System.Drawing.Drawing2D.LineJoin]::Round

    $mark = [System.Drawing.Drawing2D.GraphicsPath]::new()
    $mark.StartFigure()
    $mark.AddLine(53, 12, 53, 55)
    $mark.AddBezier(53, 55, 53, 75, 66, 85, 84, 85)
    $mark.AddBezier(84, 85, 102, 85, 115, 75, 115, 55)
    $mark.AddLine(115, 55, 115, 12)
    $mark.AddBezier(115, 12, 143, 27, 157, 50, 157, 75)
    $mark.AddBezier(157, 75, 157, 98, 147, 116, 132, 130)
    $mark.StartFigure()
    $mark.AddBezier(53, 12, 25, 27, 11, 50, 11, 75)
    $mark.AddBezier(11, 75, 11, 104, 25, 123, 41, 136)
    $mark.AddBezier(41, 136, 49, 143, 53, 153, 53, 166)
    $mark.AddLine(53, 166, 53, 255)
    $mark.AddBezier(53, 255, 53, 274, 66, 288, 84, 288)
    $mark.AddBezier(84, 288, 102, 288, 115, 274, 115, 255)
    $mark.AddLine(115, 255, 115, 183)
    $graphics.DrawPath($pen, $mark)

    $arrow = [System.Drawing.Drawing2D.GraphicsPath]::new()
    $arrow.AddLine(88, 199, 115, 165)
    $arrow.AddLine(115, 165, 142, 199)
    $graphics.DrawPath($pen, $arrow)

    $arrow.Dispose()
    $mark.Dispose()
    $pen.Dispose()
    $graphics.Dispose()
    return $bitmap
}

function Save-Png {
    param(
        [string]$RelativePath,
        [int]$Size
    )

    $path = Join-Path $ProjectRoot $RelativePath
    $directory = Split-Path -Parent $path
    [System.IO.Directory]::CreateDirectory($directory) | Out-Null
    $bitmap = New-ServiUpIcon -Size $Size
    $bitmap.Save($path, [System.Drawing.Imaging.ImageFormat]::Png)
    $bitmap.Dispose()
}

$pngTargets = [ordered]@{
    'assets/branding/serviup_app_icon.png' = 1024
    'android/app/src/main/res/mipmap-mdpi/ic_launcher.png' = 48
    'android/app/src/main/res/mipmap-hdpi/ic_launcher.png' = 72
    'android/app/src/main/res/mipmap-xhdpi/ic_launcher.png' = 96
    'android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png' = 144
    'android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png' = 192
    'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@1x.png' = 20
    'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@2x.png' = 40
    'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@3x.png' = 60
    'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@1x.png' = 29
    'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@2x.png' = 58
    'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@3x.png' = 87
    'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@1x.png' = 40
    'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@2x.png' = 80
    'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@3x.png' = 120
    'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-60x60@2x.png' = 120
    'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-60x60@3x.png' = 180
    'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-76x76@1x.png' = 76
    'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-76x76@2x.png' = 152
    'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-83.5x83.5@2x.png' = 167
    'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png' = 1024
    'macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_16.png' = 16
    'macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_32.png' = 32
    'macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_64.png' = 64
    'macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_128.png' = 128
    'macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_256.png' = 256
    'macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_512.png' = 512
    'macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_1024.png' = 1024
    'web/icons/Icon-192.png' = 192
    'web/icons/Icon-512.png' = 512
    'web/icons/Icon-maskable-192.png' = 192
    'web/icons/Icon-maskable-512.png' = 512
    'web/favicon.png' = 32
}

foreach ($target in $pngTargets.GetEnumerator()) {
    Save-Png -RelativePath $target.Key -Size $target.Value
}

$icoSizes = @(16, 32, 48, 64, 128, 256)
$icoImages = foreach ($size in $icoSizes) {
    $bitmap = New-ServiUpIcon -Size $size
    $stream = [System.IO.MemoryStream]::new()
    $bitmap.Save($stream, [System.Drawing.Imaging.ImageFormat]::Png)
    $bitmap.Dispose()
    $bytes = $stream.ToArray()
    $stream.Dispose()
    ,$bytes
}

$icoPath = Join-Path $ProjectRoot 'windows/runner/resources/app_icon.ico'
$icoStream = [System.IO.File]::Open(
    $icoPath,
    [System.IO.FileMode]::Create,
    [System.IO.FileAccess]::Write
)
$writer = [System.IO.BinaryWriter]::new($icoStream)
$writer.Write([uint16]0)
$writer.Write([uint16]1)
$writer.Write([uint16]$icoImages.Count)

$dataOffset = 6 + (16 * $icoImages.Count)
for ($index = 0; $index -lt $icoImages.Count; $index++) {
    $size = $icoSizes[$index]
    $writer.Write([byte]$(if ($size -eq 256) { 0 } else { $size }))
    $writer.Write([byte]$(if ($size -eq 256) { 0 } else { $size }))
    $writer.Write([byte]0)
    $writer.Write([byte]0)
    $writer.Write([uint16]1)
    $writer.Write([uint16]32)
    $writer.Write([uint32]$icoImages[$index].Length)
    $writer.Write([uint32]$dataOffset)
    $dataOffset += $icoImages[$index].Length
}
foreach ($image in $icoImages) {
    $writer.Write($image)
}
$writer.Dispose()
$icoStream.Dispose()

Write-Output "Generated $($pngTargets.Count) PNG icons and one Windows ICO."
