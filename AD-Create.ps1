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
      [String]$PreferredName,
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

#Configure Logging (path set to Script Folder \ Log)
$Date = Get-Date -Format "yyyy MM dd HHmmss"
$LogFile = New-Item "Logs\$Date Script Execution.log" -ItemType File
Add-Content $LogFile "**********************************************************************************"
Add-Content $LogFile "Started processing at $(Get-Date)"
Add-Content $LogFile "**********************************************************************************"
Add-Content $LogFile "Running Script Version: $Script:ScriptVersion"
Add-Content $LogFile "**********************************************************************************"

#Parse profile parameters from CSV Input File
#The import command for the Profile Data CSV
Add-Content $LogFile "Import CSV File"
$RoleMapping = Import-Csv "ProfileData.csv"
Add-Content $LogFile "CSV File Imported"
# Set constants for each of the usertypes. This assigns a number to each of the usertypes. The number corresponds to the correct row of the array. This means that you can change the number and order of the usertypes plus the Attribute conditions.
$Ctr = 0
$RoleMapping | foreach {set-variable $_.employeeProfileCode -Value $Ctr;$Ctr++}
Add-Content $LogFile "Configured User Profile Matrix from imported data for later reference"
Add-Content $LogFile "**********************************************************************************"


#Parse values from JSON Input File
Add-Content $LogFile "Import JSON File"
$Import = ConvertFrom-Json -InputObject (Gc testsinglenew.json -Raw)
Add-Content $LogFile "JSON File Imported"
Add-Content $LogFile "**********************************************************************************"

#Determine Script Execution Mode
If ($Import.id)
    {
    $ScriptMode="Update"
    Add-Content $LogFile "Script Execution Mode: $ScriptMode"
    Add-Content $LogFile "**********************************************************************************"
    }
Else
    {
    $ScriptMode="New"
    Add-Content $LogFile "Script Execution Mode: $ScriptMode"
    Add-Content $LogFile "**********************************************************************************"
    }
    
#Map Imported Data to Declared Variables
$FirstName = $Import.name.givenname
$LastName = $Import.name.familyname
$MiddleName = $Import.name.middlename

#Begin creation of User Profile Identifier
$employeeProfile=$import.'urn:scim:schemas:extension:australiapost:1.0'.employeeProfile
#Remove spaces from User Profile Names
$employeeProfile=$employeeProfile.replace(" ","")
#Use concatination to finalise Profile Identifier
$employeeProfileCode=$employeeProfile+$import.'urn:scim:schemas:extension:enterprise:1.0'.Division+$import.'urn:scim:schemas:extension:australiapost:1.0'.workforceSegment+$import.'urn:scim:schemas:extension:australiapost:1.0'.workforceType
#Determine Profile Parameters for User based on employeeProfile
$RMRow = Get-Variable -name $employeeProfileCode -valueonly

#Determine if Preferred Name Required
Function Determine-PreferredName
{
    Add-Content $LogFile "Begin Determine-PreferredName Function"
    #Checks if Preferred Name has been supplied from SAP
    if ($import.name.nickname -ne $null){
        $Script:PreferredName=$import.name.nickname
        Add-Content $LogFile "Preferred Name has been detected and set"
        }
    else
        {
        $Script:PreferredName=$FirstName
        Add-Content $LogFile "No Preferred Name has been detected, First Name set as Preferred Name"
        }
    Add-Content $LogFile "Preferred Name: $Script:PreferredName"
    Add-Content $LogFile "End of Determine-PreferredName Function" 
    Add-Content $LogFile "**********************************************************************************" 
}

#Determine working Domain Environment
Function Determine-Domain
{
    Add-Content $LogFile "Begin Determine-Domain Function"
    #Uses Profile Data to determine appropriate Domain Value
    Add-Content $LogFile "Matching Domain according to Profile Data"
    $Script:Domain = $Script:RoleMapping.Domain[$RMRow]
    Add-Content $LogFile "Domain set to: $Script:Domain"
    Add-Content $LogFile "End of Determine-Domain Function" 
    Add-Content $LogFile "**********************************************************************************" 
}

#Calculate appropriate and available UPN for new Account
Function Determine-UPN
{
    Add-Content $LogFile "Begin Determine-UPN Function"
    #Check if Last Name is greater than 20 characters, if so truncate to fit
        if ($LastName.length -gt 20){
        $UPNLast = $LastName.substring(0,19)
        Add-Content $LogFile "UPN has truncated LastName to suit convention"
    }
    Else{
        $UPNLast = $LastName
    }

    #Check if First Name is greater than 20 characters, if so truncate to fit
    if ($FirstName.length -gt 20){
        $UPNFirst = $FirstName.substring(0,19)
        Add-Content $LogFile "UPN has truncated FirstName to suit convention"
    }
    Else{
        $UPNFirst = $FirstName
    }

    $Script:UPN = $Firstname+"."+$Lastname+$Domain
    Add-Content $LogFile "UPN provisionally set to: $Script:UPN"
    Add-Content $LogFile "Now checking whether UPN is Unique"

    #Check for existing UPN
    Add-Content $LogFile "Begin check for existing UPN"
    $i = 2
    While((Get-ADUser -Filter {UserPrincipalName -eq $UPN}) -ne $null){
        $Script:UPN = $Firstname+"."+$LastName+[string]$i+$Domain
        $i++
        Add-Content $LogFile "UPN was not unique, sourcing next available"
    }
    Add-Content $LogFile "The check for a unique UPN has been completed"
    Add-Content $LogFile "UPN set to: $Script:UPN"
    Add-Content $LogFile "End of Determine-UPN Function" 
    Add-Content $LogFile "**********************************************************************************" 
}

#Calculate appropriate and available SAMAccountName for new Account
Function Determine-SAMAccountName
{
    Add-Content $LogFile "Begin Determine-SAMAccountName Function"
    #Check if Surname is greater than 8 characters, if so truncate to fit
        if ($LastName.length -gt 8){
        $Lastname = $LastName.substring(0,8)
        $FirstName = $FirstName.substring(0,1)
        Add-Content $LogFile "SAMAccountName has truncated LastName to suit convention"
    }
    Else{
        $FirstName = $FirstName.substring(0,1)
    }

    $Script:SAMAccountName = $LastName+$FirstName
    Add-Content $LogFile "SAMAccountName provisionally set to: $Script:SAMAccountName"
    Add-Content $LogFile "Now checking whether SAMAccountName is Unique"


    #Check if SAMAccountName is currently available, if not append with numerical value in ascending order
    Add-Content $LogFile "Begin check for existing SAMAccountName"
    $i = 2
    While((Get-ADUser -Filter {SAMAccountName -eq $SAMAccountName}) -ne $null){
        $Script:SAMAccountName= $LastName+$Firstname + [string]$i
        $i++
        Add-Content $LogFile "SAMAccountName was not unique, sourcing next available"
    }
    Add-Content $LogFile "The check for a unique SAMAccountName has been completed"
    Add-Content $LogFile "SAMAccountName set to: $Script:SAMAccountName"
    Add-Content $LogFile "End of Determine-SAMAccountName Function" 
    Add-Content $LogFile "**********************************************************************************"
}

#Determine BirthRight Groups
Function Determine-BirthRightGroups
{
    Add-Content $LogFile "Begin Determine-BirthRightGroups Function"
    #Uses the Profile Matrix to capture appropriate groups and seperate values in to useable array for later function)
    $Script:BRGroupList = $($Script:RoleMapping.Groups[$RMRow]) -split "##"
    Add-Content $LogFile "Setting BirthRight Groups to:"
    Add-Content $LogFile $Script:BRGroupList
    Add-Content $LogFile "End of Determine-BirthRightGroups Function"
    Add-Content $LogFile "**********************************************************************************"
}

#Create new AD User Account
Function CreateAccount
{
    Add-Content $LogFile "Begin New-ADUser Function"
    #Uses combination of data from SAP as well as cross-referenced information from Profile Matrix
    Write-Host New-AdUser -UserPrincipalName $Script:UPN -SAMAccountName $Script:SAMAccountName -name ($Script:PreferredName+" "+$Script:LastName)
    Add-Content $Logfile "Set-AdUser -UserPrincipalName '$Script:UPN' -SAMAccountName '$Script:SAMAccountName' -name '$Script:PreferredName $Script:LastName'"
    Add-Content $LogFile "End of CreateAccount Function" 
    Add-Content $LogFile "**********************************************************************************" 
}

#Grab ObjectGUID for SAP
Function Determine-ObjectGUID
{
    Add-Content $LogFile "Begin Determine-ObjectGUID Function"
    #$GUID=Get-ADUser -Filter {UserPrincipalName -eq $UPN} | Select ObjectGuid
    #$GUID=GUID.ObjectGUID
     
    #Test Values
    $GUID=Get-ADUser -Filter {UserPrincipalName -eq "jcurtin@ce-tech.com.au"} | Select ObjectGuid
    $Script:GUID=$GUID.ObjectGUID
    Add-Content $Logfile "The ObjectGUID for the created user account is $Script:GUID"
    Add-Content $LogFile "End of Determine-ObjectGUID Function" 
    Add-Content $LogFile "**********************************************************************************" 
}

#Values for SAP
Function SAP-Export
{
    Add-Content $LogFile "Begin SAP-Export Function"
    $Script:Export=$Script:Import
    Add-Content $Logfile "Creating new Export Array based off original Import"
    $Script:Export.id=$Script:GUID
    Add-Content $Logfile "Setting the ObjectGUID as the ID"
    $Script:Export.'urn:scim:schemas:extension:australiapost:1.0'.shortName=$Script:SAMAccountName
    Add-Content $Logfile "Setting the SAMAccountName as the shortName"
    $Script:Export | Out-File testsinglenewexport.json
    Add-Content $Logfile "Exporting the Array as new JSON file"

    #Test-Export Value
    #$Script:Export
    
    Add-Content $LogFile "End of SAP-Export Function" 
    Add-Content $LogFile "**********************************************************************************" 
}

#Command Set
If ($ScriptMode="New")
    {
    Determine-PreferredName
    Determine-Domain
    Determine-UPN
    Determine-SAMAccountName
    Determine-BirthRightGroups
    CreateAccount
    Determine-ObjectGUID
    SAP-Export
    }
    ElseIf($ScriptMode="Update")
    {
    Determine-Domain
    }

Add-Content $LogFile "Finished processing at $(Get-Date)"
Add-Content $LogFile "**********************************************************************************"
