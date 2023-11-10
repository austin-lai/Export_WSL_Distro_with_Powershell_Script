
# Export WSL Distro with Powershell Script

```markdown
> Austin.Lai |
> -----------| October 26th, 2023
> -----------| Updated on November 10th, 2023
```

---

## Table of Contents

<!-- TOC -->

- [Export WSL Distro with Powershell Script](#export-wsl-distro-with-powershell-script)
    - [Table of Contents](#table-of-contents)
    - [Disclaimer](#disclaimer)
    - [Description](#description)
    - [export-wsl-distro](#export-wsl-distro)

<!-- /TOC -->

<br>

## Disclaimer

<span style="color: red; font-weight: bold;">DISCLAIMER:</span>

This project/repository is provided "as is" and without warranty of any kind, express or implied, including but not limited to the warranties of merchantability, fitness for a particular purpose and noninfringement. In no event shall the authors or copyright holders be liable for any claim, damages or other liability, whether in an action of contract, tort or otherwise, arising from, out of or in connection with the software or the use or other dealings in the software.

This project/repository is for <span style="color: red; font-weight: bold;">Educational</span> purpose <span style="color: red; font-weight: bold;">ONLY</span>. Do not use it without permission. The usual disclaimer applies, especially the fact that me (Austin) is not liable for any damages caused by direct or indirect use of the information or functionality provided by these programs. The author or any Internet provider bears NO responsibility for content or misuse of these programs or any derivatives thereof. By using these programs you accept the fact that any damage (data loss, system crash, system compromise, etc.) caused by the use of these programs is not Austin responsibility.

<br>

## Description

<!-- Description -->

Simple PowerShell script as a helper or tool to help you export WSL distro.

<span style="color: orange; font-weight: bold;">Note:</span>

- The configurations in this project/repository are for your reference:
    - <span style="color: green; font-weight: bold;">Docker Desktop</span> is running and configured as start on boot.
    - Assuming you have installed <span style="color: green; font-weight: bold;">Docker Desktop</span> at `"C:\Program Files\Docker\Docker\Docker Desktop.exe"`.
    - A default path of `"C:\Users\$env:UserName\Desktop"` is used as destination.
- A powershell script file:
    - [export-wsl-distro](#export-wsl-distro)
- Please change the configuration accordingly to suits your environment.

<!-- /Description -->

<br>

## export-wsl-distro

The `export-wsl-distro.ps1` file can be found [here](./export-wsl-distro.ps1) or below:

<details>

<summary><span style="padding-left:10px;">Click here to expand and check out the powershell script !!!</span>

</summary>

```powershell

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
```

</details>

<br>
