##----------------------------------------------------------------------------------------------------
##           
##  Script:      AD-Create.ps1 
##  Purpose:     Create users in Active directory from a suplied .json file 
##
##  Requirements: This script requries a constructed .json file according to Standard XXXX
##
##  Usage:       .\AD-Create.ps1 
##
##  Authour:     Jean-Paul Curtin
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

#Parse values from JSON Input File
$Import = ConvertFrom-Json -InputObject (Gc testsingle.json -Raw)

#Map Imported Data to Declared Variables
$FirstName = $Import.name.givenname
$LastName = $Import.name.familyname
$MiddleName = $Import.name.middlename

Function Determine-Domain
{
$Script:Domain = "@apgteam.com.au"
}

Function Determine-UPN
{
$Script:UPN = $FirstName+"."+$LastName+$Domain
}

Function Determine-SAMAccountName
{
    if ($LastName.length -gt 9){
        $Script:SAMAccountName = $LastName.substring(0,9)+"."+$FirstName.substring(0,1)
    }
    Else{
        $Script:SAMAccountName = $LastName+"."+$FirstName.substring(0,1)
    }
}

Determine-Domain
Determine-UPN
Determine-SAMAccountName
Write-Host Set-AdUser -UserPrincipalName $UPN -SAMAccountName $SAMAccountName
