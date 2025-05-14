Import-Module -Name Microsoft.Entra
Connect-Entra
Connect-MgGraph -UseDeviceAuthentication

# Ask user for the UPN
$UserUPN = Read-Host "Please enter the UPN of the user in question to show its on prem stored attributes in Entra"

#Convert all output to csv is the only way to work with each individual object here 
$AllAttributesValues = @(
     "mail",
     "officeLocation",
     "surname",
     "displayName",
     "jobTitle",
     "preferredLanguage",
     "mobilePhone",
     "givenName",
     "id",
     "userPrincipalName",
     "businessPhones",
     "ObjectId",
     "UserState",
     "UserStateChangedOn",
     "Mobile",
     "DeletionTimestamp",
     "DirSyncEnabled",
     "ImmutableId",
     "LastDirSyncTime",
     "ProvisioningErrors",
     "TelephoneNumber",
     "AboutMe",
     "AccountEnabled",
     "Activities",
     "AgeGroup",
     "AgreementAcceptances",
     "AppRoleAssignments",
     "AssignedLicenses",
     "AssignedPlans",
     "Authentication",
     "AuthorizationInfo",
     "Birthday",
     "Calendar",
     "CalendarGroups",
     "CalendarView",
     "Calendars",
     "Chats",
     "City",
     "CloudClipboard",
     "CompanyName",
     "ConsentProvidedForMinor",
     "ContactFolders",
     "Contacts",
     "Country",
     "CreatedDateTime",
     "CreatedObjects",
     "CreationType",
     "CustomSecurityAttributes",
     "DeletedDateTime",
     "Department",
     "DeviceEnrollmentLimit",
     "DeviceManagementTroubleshootingEvents",
     "DirectReports",
     "Drive",
     "Drives",
     "EmployeeExperience",
     "EmployeeHireDate",
     "EmployeeId",
     "EmployeeLeaveDateTime",
     "EmployeeOrgData",
     "EmployeeType",
     "Events",
     "Extensions",
     "ExternalUserState",
     "ExternalUserStateChangeDateTime",
     "FaxNumber",
     "FollowedSites",
     "HireDate",
     "Identities",
     "ImAddresses",
     "InferenceClassification",
     "Insights",
     "Interests",
     "IsManagementRestricted",
     "IsResourceAccount",
     "JoinedTeams",
     "LastPasswordChangeDateTime",
     "LegalAgeGroupClassification",
     "LicenseAssignmentStates",
     "LicenseDetails",
     "MailFolders",
     "MailNickname",
     "MailboxSettings",
     "ManagedAppRegistrations",
     "ManagedDevices",
     "Manager",
     "MemberOf",
     "Messages",
     "MySite",
     "Oauth2PermissionGrants",
     "OnPremisesDistinguishedName",
     "OnPremisesDomainName",
     "OnPremisesExtensionAttributes",
     "OnPremisesImmutableId",
     "OnPremisesLastSyncDateTime",
     "OnPremisesProvisioningErrors",
     "OnPremisesSamAccountName",
     "OnPremisesSecurityIdentifier",
     "OnPremisesSyncEnabled",
     "OnPremisesUserPrincipalName",
     "Onenote",
     "OnlineMeetings",
     "OtherMails",
     "Outlook",
     "OwnedDevices",
     "OwnedObjects",
     "PasswordPolicies",
     "PasswordProfile",
     "PastProjects",
     "People",
     "PermissionGrants",
     "Photo",
     "Photos",
     "Planner",
     "PostalCode",
     "PreferredDataLocation",
     "PreferredName",
     "Presence",
     "Print",
     "ProvisionedPlans",
     "ProxyAddresses",
     "RegisteredDevices",
     "Responsibilities",
     "Schools",
     "ScopedRoleMemberOf",
     "SecurityIdentifier",
     "ServiceProvisioningErrors",
     "Settings",
     "ShowInAddressList",
     "SignInActivity",
     "SignInSessionsValidFromDateTime",
     "Skills",
     "Solutions",
     "Sponsors",
     "State",
     "StreetAddress",
     "Teamwork",
     "Todo",
     "TransitiveMemberOf",
     "UsageLocation",
     "UserType",
     "AdditionalProperties"
 )

# Initialize output array
$ArrayAllAttributes = @()

# Loop through each attribute
foreach ($Prop in $AllAttributesValues) {
    $Value = $null

    try {
        switch ($Prop) {
            default {
                $Result = Get-EntraUser -UserId $UserUPN -Property $Prop | Select-Object $Prop -ExpandProperty $Prop
                $Value = $Result.$Prop
            }
        }
    }
    catch {
        Write-Host -ForegroundColor Yellow "Failed to retrieve $Prop for $UserUPN, $Prop may not be applied $_.Exception"
        $Value = "N/A"
    }

    # Normalize value (if still null or empty)
    if (-not $Value) {
        $Value = "N/A"
    }

    # Add object to array
    $ArrayAllAttributes += [PSCustomObject]@{
        Attribute = $Prop
        Value     = ($Value -join ', ')
    }
}

# Show output
$ArrayAllAttributes | Format-Table -AutoSize

#Get-EntraUser -UserId "kdavignon@shclabtenant.onmicrosoft.com" -Property Settings | Select-Object -ExpandProperty Settings
#Get-MgUserSetting -UserId "kdavignon@shclabtenant.onmicrosoft.com"