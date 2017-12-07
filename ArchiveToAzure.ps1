#########################################
##  HyTrust Inc.
##  December 2017
##  Archive files to Azure from exported CSV file
##  Tested with HyTrust for Data v2.1
##  Free to distribute and modify
##  THIS SCRIPT IS PROVIDED WITHOUT WARRANTY, ALWAYS FULLY BACK UP DATA BEFORE INVOKING ANY SCRIPT
##  ALWAYS VERIFY NO BLANK ROWS IN BETWEEN DATA IN CSV
##########################################

##########################################
## Instructions:
## 1) Use HyTrust UI to filter by files, dormant data, etc
## 2) Export CSV file
## 3) Use Excel/OpenOffice if more filtering is needed, use commas only not ;
## 4) Modify script paths
## 5) Run script
## 6) Take DiscoveryPoint and verify file deletion
## 7) Optional - Verify Archive Stubs if -ArchiveStub parameter specified
##
##
## Ex. ArchiveToAzure.ps1 -SourceFilePath "\\192.168.15.40\Sales$" -CloudFilePath "\\azure16.file.core.windows.net\archive" -csvFilePath "c:\temp\sales.csv" -logFile "C:\Temp\HyTrust Delete From CSV.log" -ArchiveStub
##
##########################################

##----------------------------------------
## Input Paramaters
##----------------------------------------

param (
[Parameter(Mandatory=$true)]
    [string]$sourceFilePath,
[Parameter(Mandatory=$true)]
    [string]$cloudFilePath,
[Parameter(Mandatory=$true)]
    [string]$csvFilePath,
[Parameter(Mandatory=$true)]
    [string]$logFile,
    [switch]$ArchiveStub
 )

function Copy-ToCloud($source, $destination)
{
    #write-host "`tIn CopyToCloud"
    $file = Get-Item -Path $source
    $copyTo = $file.FullName -replace [Regex]::Escape($source), $destination
    if ( $source -isnot [io.directoryinfo] ){
			$tmp = ([System.IO.FileInfo]$copyTo).Directory.FullName
			if (!(Test-Path -path $tmp)) {
				New-Item -path $tmp -type directory -force 
			}
    }
	Copy-item "$source" "$destination" -force
	#Write-Host "`t" Copy-item "$source" "$destination" -force
}

function New-Shortcut($targetPath, $shortcutPath){
## Create a shortcut in place of the original file
    #Write-Host "Creating a shortcut for file:  " $targetPath
    #Write-Host "Shortcut name:  " $shortcutPath" - Archived.lnk"

    $targetFile = Get-Item -Path $targetPath
    $sourceFile = Get-Item -Path $shortcutPath
    $tmp = Join-Path ([system.io.fileinfo]$targetFile).DirectoryName ([system.io.fileinfo]$targetfile).BaseName
    $ShortcutFile =  "$tmp - Archived.lnk"
    $WScriptShell = New-Object -ComObject WScript.Shell
    $Shortcut = $WScriptShell.CreateShortcut($ShortcutFile)
    $Shortcut.TargetPath = $sourceFile.FullName
    $Shortcut.Save()
    
}

function Get-FingerPrint($file) {
## Calculate the SHA1 hash of a file and return the hash
    Write-Host "Calculating Fingerprint for " $file
    $fingerPrint = Get-FileHash -path $file -Algorithm SHA1
    return $fingerPrint
}

Function Pause ($Message = "Press any key to continue . . . ") {
    If ($psISE) {
        # The "ReadKey" functionality is not supported in Windows PowerShell ISE.
 
        $Shell = New-Object -ComObject "WScript.Shell"
        $Button = $Shell.Popup("Click OK to continue.", 0, "Pausing for a moment...", 0)
 
        Return
    }
 
    Write-Host -NoNewline $Message
 
    $Ignore =
        16,  # Shift (left or right)
        17,  # Ctrl (left or right)
        18,  # Alt (left or right)
        20,  # Caps lock
        91,  # Windows key (left)
        92,  # Windows key (right)
        93,  # Menu key
        144, # Num lock
        145, # Scroll lock
        166, # Back
        167, # Forward
        168, # Refresh
        169, # Stop
        170, # Search
        171, # Favorites
        172, # Start/Home
        173, # Mute
        174, # Volume Down
        175, # Volume Up
        176, # Next Track
        177, # Previous Track
        178, # Stop Media
        179, # Play
        180, # Mail
        181, # Select Media
        182, # Application 1
        183  # Application 2
 
    While ($KeyInfo.VirtualKeyCode -Eq $Null -Or $Ignore -Contains $KeyInfo.VirtualKeyCode) {
        $KeyInfo = $Host.UI.RawUI.ReadKey("NoEcho, IncludeKeyDown")
    }
 
    Write-Host
}

$deletedFileCount = 0
$date = Get-Date

net use \\dgtest16.file.core.windows.net\dgtest /u:dgtest16 qH4HlMAac5LJa3ZjkmIEjs8AHtwe+imdtiqOx9y+o32SeniQ5vSWVMHjUJwzHuQSiinldrtckwrkrWnSjntiyA==

# Pause for 3 seconds to allow the Azure file share to be connected
Start-Sleep -Seconds 3

Invoke-Item \\192.168.49.10\Public
Invoke-Item \\dgtest16.file.core.windows.net\dgtest

# Pause for 3 seconds to allow the Windows Explorer windows to be opened, 
# then pause until the the OK buttons is pressed or any key is pressed 

Start-Sleep -Seconds 3
Pause



##########################################
## Start Logging

"Processing started (on " + $date + "): " | Out-File $logFile -append 
"--------------------------------------------" | Out-File $logFile -append 

## Import CSV and delete the file from the share and path and leave behind a shortcut link to the archived file

Import-CSV $csvFilePath | ForEach-Object {
    $shareID = $_.share_id
    $owner = $_.owner
    $lastModTime = $_.lastmodtime
    $mimeType = $_.mimeType
    $tags = $_.tags
    $size = $_.size
    $contentState = $_.contentstate
    $deleteFilePath = $_.filepath
    $sourceFingerPrint = $_.fingerprint

    # Swap out / for \ in CSV file
    $deleteFilePath = $deleteFilePath | ForEach-Object {$_ -Replace "/","\"}
    
    # complete filepath to the file that is to be archived
    $sourceFullFilePath = $sourceFilePath+$deleteFilePath

    # complete filepath to the location where the file is to be archived
    $cloudFullFilePath = $CloudFilePath+$deleteFilePath

    Copy-ToCloud $sourceFullFilePath $cloudFullFilePath
    #Copy-item -Path $sourceFullFilePath -Destination $cloudFullFilePath -Force
	#Write-Host "`t" Copy-item "$sourceFullFilePath" "$cloudFullFilePath" -force

    #Create a file/folder shortcut in place of the original
    if ($ArchiveStub) { 
        New-Shortcut $sourceFullFilePath $cloudFullFilePath
        "$sourceFullFilePath has been deleted and archived by IT (on " + $date + ") " | Out-File $logfile -Append
    
    ## Calculate the SHA1 hash of the files
    $hash1 = Get-FileHash -Path $sourceFullFilePath -Algorithm SHA1
    #Write-host $hash.hash
    $hash2 = Get-FileHash -Path $cloudFullFilePath -Algorithm SHA1
    #Write-host $hash.hash

    # Delete the File
    #Write-Host $sourceFullFilePath
    Remove-Item -verbose $sourceFullFilePath -Force

    $deletedFileCount = $deletedFileCount + 1
    #"Deleted $deleteFilePath" | Out-File $logFile -append
    
    }
    
}

"Archived $deletedFileCount files."  | Out-File $logFile -Append
Write-Host "Archived " $deletedFileCount " files."