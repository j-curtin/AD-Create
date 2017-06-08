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

#Specify the parameters to be parsed from input file
PARAM(
  [String]$GUID,
  [String]$CPNumber,
  [String]$UPN,
  [String]$FirstName,
  [String]$LastnameName,
  [String]$MiddleInitial,
  [String]$Title,
  [String]$UserType,
  [String]$TimeZone,
  [String]$Enabled,
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

$SAMAccountName= $import.name.familyname + $import.name.givenname.substring(0,1)

#Test Script Command Output
Write-Host New-ADUser -SamAccountName $SAMAccountName
