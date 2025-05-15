function Get-EzIdentityAttribute {
    #Import-Module -Name Microsoft.Entra -ErrorAction Stop
    #Connect-Entra
    #Connect-MgGraph -UseDeviceAuthentication
#Ask user for the upn 
$UserUPN = Read-Host "Please enter the UPN of the user in question to show its Entra Identity based attributes"

#array of Idneity Attributes
$IdentityAttributeValues = @(
    "assignedLicenses",                     # Assigned licenses
    "displayName",                          # Display name
    "givenName",                            # First name
    "surname",                              # Last name
    "userPrincipalName",                    # User principal name
    "id",                                   # Object ID
    "identities",                           # Identities
    "userType",                             # User type
    "creationType",                         # Creation type
    "createdDateTime",                      # Created date time
    "lastPasswordChangeDateTime",           # Last password change date time
    "externalUserState",                    # Invitation state (closest match)
    "externalUserStateChangeDateTime",      # External user state change date time
    "passwordPolicies",                     # Password policies
    "passwordProfile",                      # Password profile
    "preferredLanguage",                    # Preferred language
    "signInSessionsValidFromDateTime",      # Sign in sessions valid from date time
    "authorizationInfo"                     # Authorization info
)

#Initialize Array to store the output of all Identity attributes
$ArrayIDAttributes = @()

#Loop through each attribute and expand 
foreach($Prop in $IdentityAttributeValues){

    #This is the value of the Property at the current iteration of the loop
    $Values = Get-MgUser -UserId $UserUPN -Property $Prop | Select-Object -ExpandProperty $Prop

    #Check for Null and Write NA if Values are Null
    if($null -eq $Values){
        #Set Identity attribute to Null Value 
            $IdentityAttributes = [PSCustomObject]@{
            $Prop = "NA"
            }
        }

        #Store the key value pairs in a hashtable for rich output
        foreach($Value in $Values){

            #assigned License check need to expand more 
            if($Prop -eq "assignedLicenses"){
            $Value = Get-MgUser -UserId $UserUPN -Property assignedLicenses `
        |   Select-Object -ExpandProperty assignedLicenses
            }

            #Store key value pairs 
            $IdentityAttributes = [PSCustomObject]@{
            $Prop = $Value
            }
    }

    #Store of values  
    $ArrayIDAttributes += $IdentityAttributes

    
} 

$ArrayIDAttributes | Format-List



}

