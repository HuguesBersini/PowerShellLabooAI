$NasPlanGUID    = "1356f684-3682-4786-beee-9ae0cee16e26"
$BalancedGUID   = "381b4222-f694-41f0-9685-ff5bb260df2e"
$FanControlPath = "C:\Program Files (x86)\FanControl\FanControl.exe"

Clear-Host 
Write-Host "1. NAS Idle Plan"
Write-Host "2. Balanced Plan"

$Choice = Read-Host "Choose Power Plan :"

if ($Choice -eq "1") {
    powercfg /setactive $NasPlanGUID
    Write-Host "Switched to NAS Idle Mode."
    & $FanControlPath -c "idle.json"
    Write-Host "Loaded 'idle.json' fan curve."
}
elseif ($Choice -eq "2") {
    powercfg /setactive $BalancedGUID
    Write-Host "Switched to Balanced Mode."
    & $FanControlPath -c "balanced.json"
    Write-Host "Loaded 'balanced.json' fan curve."
}
else {
    Write-Host "Invalid choice."
}