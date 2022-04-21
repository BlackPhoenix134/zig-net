$Root = $PSScriptRoot
$Path = "$($Root)\zig-out\bin"
$Exe = "$($Path)\main_flecs.exe";


& "zig" "build"
if($LASTEXITCODE -ne 0) {   
    throw "Error"
}
    
Start-Process cmd -Argument "-NoExit /c $Exe server"
& "$Exe" "client"
