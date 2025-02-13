param (
   [switch]$Silent = $false
)

# Check if the script is running with elevated privileges
if (!([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator')) {
    # Get the absolute path of the script
    $absolutePath = Resolve-Path $MyInvocation.MyCommand.Path

    # Prepare the arguments to pass, including the script path
    $args = @("-File `"$absolutePath`"")

    # Add bound parameters to the argument list
    if ($Silent) {
        $args += "-Silent"
    }

    # Start a new PowerShell process with elevated privileges and pass the arguments
    Start-Process -FilePath PowerShell.exe -Verb RunAs -ArgumentList $args
    Exit
}
# Push location to the current script directory
Push-Location $PSScriptRoot

# Source directory and target link directory for each folder
$folders = @{
    "config" = @{
        "source" = "..\config"
        "ignoreNames" = @() # Add file or folder names to ignore
    }
    "defaultconfigs" = @{
        "source" = "..\defaultconfigs"
        "ignoreNames" = @()
    }
    "kubejs" = @{
        "source" = "..\kubejs"
        "ignoreNames" = @()
    }
    "libraries" = @{
        "source" = "..\..\libraries"
        "target" = "libraries"
        "ignoreNames" = @()
        "link" = $true
    }
    "mods" = @{
        "source" = "..\mods"
        "ignoreNames" = @(
            "Auroras-1.21-1.6.2.jar",
            "BetterAdvancements-NeoForge-1.21.1-0.4.3.21.jar",
            "clean_tooltips-1.1-neoforge-1.21.1.jar",
            "colorfulhearts-neoforge-1.21.1-10.3.8.jar",
            "darkmodeeverywhere-1.21-1.3.4.jar",
            "embeddium-1.0.15+mc1.21.1.jar",
            "EquipmentCompare-1.21-neoforge-1.3.12.jar",
            "EuphoriaPatcher-1.5.2-r5.4-neoforge.jar",
            "ExtremeSoundMuffler-3.48.3_NeoForge-1.21.jar",
            "Iceberg-1.21.1-neoforge-1.2.9.2.jar",
            "iris-neoforge-1.8.1+mc1.21.1.jar",
            "justenoughbreeding-neoforge-1.21-1.21.1-1.5.0.jar",
            "JustEnoughMekanismMultiblocks-1.21.1-7.3.jar",
            "JustEnoughProfessions-neoforge-1.21.1-4.0.3.jar",
            "justzoom_neoforge_2.0.0_MC_1.21-1.21.1.jar",
            "keybindspurger-1.21.x-neoforge-1.3.2.jar",
            "konkrete_neoforge_1.9.9_MC_1.21.jar",
            "LegendaryTooltips-1.21-neoforge-1.4.11.jar",
            "modelfix-1.21-1.10.jar",
            "monocle-0.1.9.ms.jar",
            "moreoverlays-1.23.2-mc1.21-neoforge.jar",
            "NeoAuth-1.21.1-1.0.0.jar",
            "nolijium-0.5.5.jar",
            "PackMenu-1.21-7.0.2.jar",
            "Prism-1.21-neoforge-1.0.9.jar",
            "Rainbows-1.21-1.3.1.jar",
            "simple_weather-1.0.13.jar",
            "SimpleBackups-1.21-4.0.7.jar",
            "ToastControl-1.21-9.0.0.jar",
            "wits-1.3.0+1.21-neoforge.jar"
        )
    }
    "packmenu" = @{
        "source" = "..\packmenu"
        "ignoreNames" = @()
    }
}

# Function to copy files from source to target directory
function Copy-Files {
    param(
        [string]$sourceDirectory,
        [string]$targetDirectory,
        [string[]]$ignoreNames
    )

    # Get files and folders in the source directory
    $items = Get-ChildItem -Path $sourceDirectory

    # Loop through each item and copy it to the target directory
    foreach ($item in $items) {
        # Check if item is not in the ignore list
        if ($ignoreNames -notcontains $item.Name) {
            # Check if item is a directory or file
            if ($item.PSIsContainer) {
                # Copy directory to target directory
                Write-Host "Copying directory: Copy-Item -Path `"$($item.FullName)`" -Destination `"$targetDirectory\$($item.Name)`" -Recurse -Force"
                $src = [Management.Automation.WildcardPattern]::Escape($item.FullName)
                $dest = [Management.Automation.WildcardPattern]::Escape("$targetDirectory\$($item.Name)")
                Copy-Item -Path $src -Destination $dest -Recurse -Force
            } else {
                # Copy file to target directory
                Write-Host "Copying file: Copy-Item -Path `"$($item.FullName)`" -Destination `"$targetDirectory`" -Force"
                $src = [Management.Automation.WildcardPattern]::Escape($item.FullName)
                $dest = [Management.Automation.WildcardPattern]::Escape($targetDirectory)
                Copy-Item -Path $src -Destination $dest -Force
            }
        }
    }
}

# Loop through each folder and create symbolic links or copy files
foreach ($folderName in $folders.Keys) {
    $folder = $folders[$folderName]
    $sourceDirectory = $folder["source"]
    $targetDirectory = $folderName
    $ignoreNames = $folder["ignoreNames"]

    # Remove previous symbolic link and folder if they exist
    if (Test-Path -Path $targetDirectory) {
        Write-Host "Removing previous symbolic link and folder: rmdir `"$targetDirectory`" /s /q"
        git rm --cached -r "$targetDirectory"
        # Check if item is a directory or file
        if (Test-Path -Path $targetDirectory -PathType Container) {
            cmd /c rmdir "$targetDirectory" /s /q
        } else {
            cmd /c del "$targetDirectory" /q
        }
    }

    # Check if symbolic link should be created
    if ($folder["link"]) {
        # Create symbolic link for directory
        Write-Host "Creating symbolic link for folder: mklink /D `"$targetDirectory`" `"$sourceDirectory`""
        cmd /c mklink /D "$targetDirectory" "$sourceDirectory"
        git reset HEAD -- "$targetDirectory"
    } else {
        # Create new target directory
        Write-Host "Creating target directory: New-Item -Path `"$targetDirectory`" -ItemType Directory"
        New-Item -Path $targetDirectory -ItemType Directory | Out-Null
        # Copy files from source to target directory
        Write-Host "Copying files to target directory..."
        Copy-Files -sourceDirectory $sourceDirectory -targetDirectory $targetDirectory -ignoreNames $ignoreNames
    }
}

# Pop back to the previous location
Pop-Location

# Conditionally pause based on -Silent argument
if (-not $Silent) {
    cmd /c pause
}