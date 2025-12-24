$u="https://github.com/raysan5/raylib/releases/download/5.5/raylib-5.5_win64_msvc16.zip"
$z="$PWD\raylib.zip"
$d="$PWD\raylib"

Invoke-WebRequest $u -OutFile $z
Expand-Archive $z -DestinationPath $d -Force


$inner=Get-ChildItem $d | Where-Object {$_.PSIsContainer} | Select-Object -First 1
Get-ChildItem $inner.FullName | Move-Item -Destination $d -Force
Remove-Item $inner.FullName -Recurse -Force
Remove-Item $z
