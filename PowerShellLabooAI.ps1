$NasPlanGUID    = "1356f684-3682-4786-beee-9ae0cee16e26"
$BalancedGUID   = "381b4222-f694-41f0-9685-ff5bb260df2e"
$FanControlPath = "C:\Program Files (x86)\FanControl\FanControl.exe"
$WebhookURL     = "https://discord.com/api/webhooks/1447676125256876114/YxLbzA6zXMvNm5oz4sZ6lfEXrjSsS8NI6q0ZGYccLtdBiOsS1ssaKJlLtLQCzyOypz5q"

Clear-Host 
Write-Host "1. NAS Idle Plan"
Write-Host "2. Balanced Plan"

$Choice = Read-Host "Choose Power Plan :"
$LogMessage = ""

if ($Choice -eq "1") {
    powercfg /setactive $NasPlanGUID
    Write-Host "Switched to NAS Idle Mode."
    & $FanControlPath -c "idle.json"
    Write-Host "Loaded 'idle.json' fan curve."
    $LogMessage = "✅ **Status Update:** System switched to **NAS IDLE** mode."
}
elseif ($Choice -eq "2") {
    powercfg /setactive $BalancedGUID
    Write-Host "Switched to Balanced Mode."
    & $FanControlPath -c "balanced.json"
    Write-Host "Loaded 'balanced.json' fan curve."
    $LogMessage = "🚀 **Status Update:** System switched to **BALANCED** mode."
}
else {
    Write-Host "Invalid choice."
}

if ($LogMessage -ne "") {
    Write-Host "Sending log to Discord..."
    $Payload = @{
        content = $LogMessage
    }
    Invoke-RestMethod -Uri $WebhookURL -Method Post -Body ($Payload | ConvertTo-Json) -ContentType 'application/json'
    
    Write-Host "Log sent!"
    }