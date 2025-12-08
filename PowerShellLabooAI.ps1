# --- PART 1: THE NEW "BLACK BOX" HELPER ---
# This is the function you found. It creates a robust way to check idle time.
# It returns the number of seconds since you last touched the mouse/keyboard.
Function Get-IdleTime {
    # We only want to add the type ONCE. If we try to add it twice, PowerShell errors out.
    if (-not ([System.Management.Automation.PSTypeName]'IdleTime').Type) {
        Add-Type -TypeDefinition @"
            using System;
            using System.Runtime.InteropServices;
            public class IdleTime {
                [DllImport("user32.dll")] private static extern UInt32 GetLastInputInfo(ref LASTINPUTINFO plii);
                internal struct LASTINPUTINFO { public UInt32 cbSize; public UInt32 dwTime; }
                public static double Get() {
                    LASTINPUTINFO lii = new LASTINPUTINFO();
                    lii.cbSize = (UInt32)Marshal.SizeOf(typeof(LASTINPUTINFO));
                    GetLastInputInfo(ref lii);
                    return (Environment.TickCount - lii.dwTime) / 1000.0;
                }
            }
"@
    }
    return [IdleTime]::Get()
}

# --- PART 2: CONFIGURATION ---
$FanControlPath  = "C:\Program Files (x86)\FanControl\FanControl.exe"
$WebhookURL      = "https://discord.com/api/webhooks/1447676125256876114/YxLbzA6zXMvNm5oz4sZ6lfEXrjSsS8NI6q0ZGYccLtdBiOsS1ssaKJlLtLQCzyOypz5q"

$NasPlanGUID     = "1356f684-3682-4786-beee-9ae0cee16e26"
$BalancedGUID    = "381b4222-f694-41f0-9685-ff5bb260df2e"

# --- PART 3: SETUP & TESTING ---
# TIP: Set this to 10 seconds for testing. Set to 300 (5 mins) for real use.
$IdleThreshold   = 300 
$CurrentState    = "Balanced" # We assume we start in Balanced mode

Clear-Host
Write-Host "--- AUTOMATION STARTED ---"
Write-Host "Monitoring user activity..."
Write-Host "Will switch to IDLE after $IdleThreshold seconds."

# --- PART 4: THE INFINITE LOOP ---
while ($true) {
    # 1. Get current idle time using your new function
    $SecondsInactive = Get-IdleTime
    
    # DEBUG: Remove the '#' below if you want to see the seconds count up in real time!
    # Write-Host "Current Idle Time: $SecondsInactive seconds" -ForegroundColor Gray

    # 2. CHECK: Are we gone longer than the limit? AND Are we currently Balanced?
    if ($SecondsInactive -ge $IdleThreshold -and $CurrentState -eq "Balanced") {
        
        Write-Host " [!] User inactive ($SecondsInactive s). Switching to NAS IDLE." -ForegroundColor Cyan
        
        # Apply Settings
        powercfg /setactive $NasPlanGUID
        & $FanControlPath -c "idle.json"
        
        # Update State
        $CurrentState = "Idle"
        
        # Log to Discord
        $Payload = @{ content = "💤 **Auto-Switch:** User is away ($SecondsInactive s). System set to **NAS IDLE**." }
        try { Invoke-RestMethod -Uri $WebhookURL -Method Post -Body ($Payload | ConvertTo-Json) -ContentType 'application/json' -ErrorAction Stop } catch {}
    }

    # 3. CHECK: Did the user come back? (Idle time drops near 0) AND Are we in Idle?
    # We use -le 1 (Less than or equal to 1 second) to detect immediate activity.
    elseif ($SecondsInactive -le 1 -and $CurrentState -eq "Idle") {
        
        Write-Host " [!] User returned! Switching to BALANCED." -ForegroundColor Green
        
        # Apply Settings
        powercfg /setactive $BalancedGUID
        & $FanControlPath -c "balanced.json"
        
        # Update State
        $CurrentState = "Balanced"
        
        # Log to Discord
        $Payload = @{ content = "👋 **Auto-Switch:** User returned. System set to **BALANCED**." }
        try { Invoke-RestMethod -Uri $WebhookURL -Method Post -Body ($Payload | ConvertTo-Json) -ContentType 'application/json' -ErrorAction Stop } catch {}
    }

    # 4. Small pause to save CPU
    Start-Sleep -Milliseconds 500
}