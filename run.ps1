$Root = $PSScriptRoot
$Path = "$($Root)\zig-out\bin"
$ServerExe = "$($Path)\example-server.exe";
$ClientExe = "$($Path)\example-client.exe";
Write-Host $ServerExe
Write-Host $ClientExe



cmd.exe /c $ServerExe