##----------------------------------------------------------------------------------------------------
##           
##  Script:      AD-Create.ps1 
##  Purpose:     Create users in Active directory from a suplied .json file 
##
##  Requirements: This script requries a constructed .json file according to Standard XXXX
##
##  Usage:       .\AD-Create.ps1 
##
##  Author:     Jean-Paul Curtin
##           
## +----------------------------------------------------------------------------------------------------
## | Change Control
## | -------------------
## | Name                        Date                 Version         Description
## | ---------------------------------------------------------------------------------------------------
## | Jean-Paul Curtin            08.06.17             0.1             Release
## |
## +----------------------------------------------------------------------------------------------------

#Specify the working parameters, used through the script and in conjunction with the parsed data
PARAM(
      [String]$ScriptVersion="0.1",
      [String]$ScriptMode,
      [String]$GUID,
      [String]$CPNumber,
      [String]$Domain,
      [String]$UPN,
      [String]$SAMAccountName,
      [String]$FirstName,
      [String]$LastName,
      [String]$MiddleName,
      [String]$Title,
      [String]$UserType,
      [String]$TimeZone,
      [String]$Action,
      [String]$EMail,
      [String]$OfficeNo,
      [String]$MobileNo,
      [String]$StreetAddress,
      [String]$Suburb,
      [String]$State,
      [String]$Country,
      [String]$Company,
      [String]$Division,
      [String]$Department,
      [String]$Manager
      )

#Configure Logging
$Date = Get-Date -Format "yyyy MM dd HHmmss tt"
$LogFile = New-Item "$Date Script Execution.log" -ItemType File
Add-Content $LogFile "**************************************************************"
Add-Content $LogFile "Started processing at $(Get-Date)"
Add-Content $LogFile "**************************************************************"
Add-Content $LogFile "Running Script Version: $Script:ScriptVersion"
Add-Content $LogFile "**************************************************************"

#Parse values from JSON Input File
$Import = ConvertFrom-Json -InputObject (Gc testsingle.json -Raw)
Add-Content $LogFile "Import JSON File"
Add-Content $LogFile "**************************************************************"

#Determine Script Execution Mode
If ($Import.id)
    {
    $ScriptMode="Update"
    Add-Content $LogFile "Script Execution Mode: $ScriptMode"
    Add-Content $LogFile "**************************************************************"
    }
Else
    {
    $ScriptMode="New"
    Add-Content $LogFile "Script Execution Mode: $ScriptMode"
    Add-Content $LogFile "**************************************************************"
    }
    
#Map Imported Data to Declared Variables
$FirstName = $Import.name.givenname
$LastName = $Import.name.familyname
$MiddleName = $Import.name.middlename

#Determine working Domain Environment
Function Determine-Domain
{
$Script:Domain = "@apgteam.com.au"
Add-Content $LogFile "Domain set to: $Script:Domain"
Add-Content $LogFile "**************************************************************"
}

#Calculate appropriate and available UPN for new Account
Function Determine-UPN
{
    #Check if Last Name is greater than 20 characters, if so truncate to fit
    if ($LastName.length -gt 20){
        $Script:UPN = $LastName.substring(0,19)
        Add-Content $LogFile "UPN has truncated LastName to suit convention"
    }
    Else{
        $Script:UPN = $LastName
    }

    #Check if First Name is greater than 20 characters, if so truncate to fit
    if ($FirstName.length -gt 20){
        $Script:UPN = $Script:UPN+"."+$FirstName.substring(0,19)
        Add-Content $LogFile "UPN has truncated FirstName to suit convention"
    }
    Else{
        $Script:UPN = $Script:UPN+"."+$FirstName
    }


$Script:UPN = $Script:UPN+$Domain
Add-Content $LogFile "UPN set to: $Script:UPN"
Add-Content $LogFile "**************************************************************"
}

#Calculate appropriate and available SAMAccountName for new Account
Function Determine-SAMAccountName
{
    #Check if Surname is greater than 9 characters, if so truncate to fit
    if ($LastName.length -gt 9){
        $Script:SAMAccountName = $LastName.substring(0,9)+"."+$FirstName.substring(0,1)
        Add-Content $LogFile "SAMAccountName has truncated LastName to suit convention"
        Add-Content $LogFile "SAMAccountName has been set to $Script.SAMAccountName"
        Add-Content $LogFile "**************************************************************"
    }
    Else{
        $Script:SAMAccountName = $LastName+"."+$FirstName.substring(0,1)
        Add-Content $LogFile "SAMAccountName has been set to $Script.SAMAccountName"
        Add-Content $LogFile "**************************************************************"
    }


    #Check if SAMAccountName is currently available, if not append with numerical value in ascending order

}

Determine-Domain
Determine-UPN
Determine-SAMAccountName
Write-Host Set-AdUser -UserPrincipalName $UPN -SAMAccountName $SAMAccountName


Add-Content $LogFile "Finished processing at $(Get-Date)"
Add-Content $LogFile "**************************************************************"
