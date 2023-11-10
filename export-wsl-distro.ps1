


function Check-IsElevated {
  $id = [System.Security.Principal.WindowsIdentity]::GetCurrent()
  $p = New-Object System.Security.Principal.WindowsPrincipal($id)
  if ($p.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Output $true
  }
  else {
    Write-Output $false
  }
}



# Define the function with a parameter for the process name to quit Docker Desktop
function StopProcessByName ($processName) {

  # Check if the process is running
  $process = Get-Process -Name $processName -ErrorAction SilentlyContinue

  # If the process is running, stop it and display a message
  if ($process) {

    Stop-Process -Name $processName

    Write-Host "`n [:::Information:::] The process $processName has been stopped" -ForegroundColor Blue -BackgroundColor Black 

    Start-Sleep -Seconds 10

  } else {

    # If the process is not running, display a message
    Write-Host "`n [:::Information:::] The process $processName is not running" -ForegroundColor Blue -BackgroundColor Black 

  }
}



# Define the function to check for specific errors for Shutting down "Docker Desktop" and "WSL" and retry
function CheckErrorAndRetry {
  
    # Define the command to shutdown WSL
    $ShutdownWSL = "wsl --shutdown"
  
    # Define the command to export the WSL distribution to a VHD file
    # Use string interpolation to build the WSL export command
    $wslExportCommand = "wsl --export $selectedDistro $exportPath --vhd"

    Write-Host "`n [:::Action:::] Shutting down `"Docker Desktop`" ........." -ForegroundColor Magenta -BackgroundColor Black

    # Call the function with the process name to quit Docker Desktop as an argument
    StopProcessByName "Docker Desktop"

    $StopProcessByName_Status = $?

    Write-Host "`n [:::Action:::] Shutting down WSL ........." -ForegroundColor Magenta -BackgroundColor Black

    Invoke-Expression $ShutdownWSL

    $ShutdownWSL_Status = $?

    Start-Sleep -Seconds 10

    if ($ShutdownWSL_Status -and $StopProcessByName_Status ){

        Write-Host "`n [:::Information:::] Exporting the selected WSL distro ........." -ForegroundColor Blue -BackgroundColor Black

        $output = Invoke-Expression $wslExportCommand 2>&1

        # Check for specific error conditions
        if ($output -match "cannot access the file" -or $output -match "Error code" -or $output -match "used by another process") {

            # -ForegroundColor White -BackgroundColor DarkMagenta 
            Write-Host "`n [:::Warning:::] $output" -ForegroundColor White -BackgroundColor DarkRed

            # -ForegroundColor White -BackgroundColor DarkMagenta 
            Write-Host "`n [:::Warning:::] Failed to export WSL distribution. Please check the distribution name and export path." -ForegroundColor White -BackgroundColor DarkRed

            return
        }

    }

}



# Define the function to start "Docker Desktop" process or service
function StartDockerDesktop {

    Start-Process -FilePath "C:\Program Files\Docker\Docker\Docker Desktop.exe" -WindowStyle Normal

    if ($?){
            Write-Host "`n [:::Information:::]  `"Docker Desktop`" start and run correctly." -ForegroundColor Blue -BackgroundColor Black

    } else {

        Write-Host "`n [:::Warning:::] `"Docker Desktop`" does not start and run correctly. Re-run starting `"Docker Desktop`" process." -ForegroundColor White -BackgroundColor DarkRed

        StartDockerDesktop

        Start-Sleep -Seconds 10

    }

}



if (Check-IsElevated) {

    ################################################
    # Preperation to export wsl distro to vhdx
    ################################################

    # List down available WSL distros
    $WSL_Distro_List = wsl -l -q | Where-Object { $_ -ne "" }

    # Write-Host "`nAvailable WSL Distros:"
    Write-Host "`n Available WSL Distros: `n" -ForegroundColor Yellow -BackgroundColor Black 

    $WSL_Distro_List | ForEach-Object { Write-Host " * $_ " -ForegroundColor Yellow -BackgroundColor Black }

    $validDistro = $false

    do {

        $default_selectedDistro = "kali-linux"

        # Prompt the user to choose a WSL distro
        $selectedDistro = Read-Host "`n Enter the name of the distro you want to export or press `"Enter`" to use the default selected disro ( $default_selectedDistro )"

        if ($selectedDistro -eq "") {

          $selectedDistro = $default_selectedDistro
          
        }
        
        # Validate user input, must be from the list
        if ($WSL_Distro_List -contains $selectedDistro) {

            # Valid input, set $validDistro = $true and exit the loop
            $validDistro = $true

            break
        }
        else {
          
            $validDistro = $false

            # Invalid input, display an error message and repeat the loop
            Write-Host "`n [:::Warning:::] Invalid distro choice. Please select a valid distro from the list." -ForegroundColor White -BackgroundColor DarkRed

        }
    }
    while ($true)

    # Display the selected distro to user
    Write-Host "`n [:::Information:::] You have selected `"$selectedDistro`" WSL distro !" -ForegroundColor Blue -BackgroundColor Black 

    # Add Date variable with DDMMYYYY format
    $Date = Get-Date -Format "ddMMyyyy-HHmm"

    # Define the default path to be used to save the VHDX file
    $defaultPath = "C:\Users\$env:UserName\Desktop"


    # Prompt user to enter the path where the VHDX file will be saved
    $exportPath = Read-Host -Prompt "`n Enter the path where you want to save the VHDX file or press `"Enter`" to use the default path ( $defaultPath )"

    if ($exportPath -eq "") {
        $exportPath = $defaultPath
    }

    Write-Host "`n [:::Information:::] The VHDX file will be saved at: `"$exportPath\$selectedDistro-$Date.vhdx`" " -ForegroundColor Blue -BackgroundColor Black 

    # Combine all the variable for exported path with the format of "exportPath\$selectedDistro-$Date.vhdx"
    $exportPath = [System.IO.Path]::Combine($exportPath, "$selectedDistro-$Date.vhdx")

    # Define the command to shutdown WSL
    $ShutdownWSL = "wsl --shutdown"

    # Define the command to export the WSL distribution to a VHD file
    # Use string interpolation to build the WSL export command
    $wslExportCommand = "wsl --export $selectedDistro $exportPath --vhd"

    # Check if the chosen distro is in the list, if yes then run the function of CheckErrorAndRetry
    if ($validDistro -eq $true) {

        # Initial run of the command
        CheckErrorAndRetry

        $CheckErrorAndRetry_Status = $?

    } else {

        Write-Host "" -ForegroundColor White -BackgroundColor DarkRed

    }

    # Check if the function of CheckErrorAndRetry is running correctly, if not re-run it
    $export_status = $false
    # if ($CheckErrorAndRetry_Status = $?){
    if ($CheckErrorAndRetry_Status -eq $true){

        Start-Sleep -Seconds 10
            
        if (Test-Path $exportPath) {

            Write-Host "`n [:::Information:::] $exportPath exists." -ForegroundColor Blue -BackgroundColor Black

            Write-Host "`n [:::Information:::] Exported $selectedDistro to $exportPath" -ForegroundColor Blue -BackgroundColor Black 

            Write-Host "`n [:::Information:::] Set `$export_status to `$true" -ForegroundColor Blue -BackgroundColor Black 

            $export_status = $true

        } else {

            Write-Host "`n [:::Warning:::] $exportPath does not exist." -ForegroundColor White -BackgroundColor DarkRed

            Write-Host "`n [:::Warning:::] Re-run CheckErrorAndRetry." -ForegroundColor White -BackgroundColor DarkRed

            $export_status = $false

            CheckErrorAndRetry
        }

    } else {

        Write-Host "`n [:::Warning:::] CheckErrorAndRetry_Status return failed and Re-run CheckErrorAndRetry." -ForegroundColor White -BackgroundColor DarkRed

        Write-Host "`n [:::Information:::] Set `$export_status to `$false" -ForegroundColor Blue -BackgroundColor Black

        $export_status = $false

        CheckErrorAndRetry
    }

    # Check if the function of CheckErrorAndRetry is running correctly and the $export_status is set to $true
    # Clean-up
    if ($export_status = $true){
        
        Start-Sleep -Seconds 10

        Write-Host "`n [:::Information:::] Starting `"Docker Desktop`" process." -ForegroundColor Blue -BackgroundColor Black

        StartDockerDesktop

    }

}
else {

  # prompt the user to use elevated powershell and exit the script
  Write-Host "`n [:::Warning:::] Please run this script as Administrator.`n" -ForegroundColor Blue -BackgroundColor Black

  exit

}


