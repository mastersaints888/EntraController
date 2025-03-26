Function New-SHCGroup {
    <#
    .SYNOPSIS 
    Supplemental Health Care group creation tool
    .DESCRIPTION
    Supplemental Healthcare Group Structure cmdlet for quick and easy group creation with Valid sets and Case checking To easily adhear to naming schemas 
    .PARAMETER GroupType 
    Please Enter in a Valid GroupType case sensitive. Valid GroupTypes: UG, AR, PR
    .PARAMETER AssignmentType
    Valid Assignment Types are as follows: s, d, or f
    s = Static
    d = Dynamic
    f = Function ( a group that may be tied to some azure automation)
    .PARAMETER Context 
    Valid contexts includ: 'Azure', 'SharePoint', 'SQL', 'Teams', 'ADO', 'Entra', 'RedGate', 'KeyVault'
    .PARAMETER Subscription
    This is a manditory value please copy the subscription EXACTLY as written in Azure or Entra
    .PARAMETER ResourceGroup
    This is NOT Manditory but please copy the RG EXACTLY as written in Azure or Entra if you so choose to use this param
    .PARAMETER Resource
    This is NOT Manditory but please copy the Resource EXACTLY as written in Azure or Entra if you so choose to use this param
    .PARAMETER Role
    This is a Manditory please copy the Role Name EXACTLY as written in Azure or Entra and use underscore for spaces.
    Example: Key_Vault_Secrets_User
    .EXAMPLE
    New-SHCGroup -GroupType UG -AssignmentType d -Context Azure -Subscription Sub-Dev-TRM -ResourceGroup rg-resourcegroup_name -Resource my_resource -Role my_role
    
    Output:
    UGd-Azure:Sub-Dev-TRM.rg-resourcegroup.resource 
    #>
    #Basic Security Group Parameters 
    [CmdletBinding()]
    param (
        #Group type parameter 
        [Parameter(Mandatory=$true, HelpMessage="Please Enter in a Valid GroupType case sensitive. Valid GroupTypes: UG, AR, PR")]
        [ValidateSet('UG','AR','PR', IgnoreCase=$false)]
        [String]
        $GroupType,

        #Assignment type is static, dynamic or function
        [Parameter(Mandatory=$true, HelpMessage="Enter in a Valid GroupType case sensitive. Valid Types: s, d, f")]
        [ValidateSet('s','d','f', IgnoreCase=$false)]
        [string]
        $AssignmentType,
        
        #Group Context here ie: Azure, Entra, keyvault etc
        [Parameter(Mandatory=$True, HelpMessage="Enter a valid context 'Azure', 'SharePoint', 'SQL', 'Teams', 'ADO', 'Entra', 'RedGate', 'KeyVault'")]
        [ValidateSet('Azure', 'SharePoint', 'SQL', 'Teams', 'ADO', 'Entra', 'RedGate', 'KeyVault')]
        [String]
        $Context,

        #Resource Scope Subscription
        [Parameter(Mandatory=$True, HelpMessage="This is a manditory value please copy the subscription EXACTLY as written in Azure or Entra")]
        [String]
        $Subscription,
        
        #Resource scope rg
        [Parameter(Mandatory=$false, HelpMessage="This is NOT Manditory but please copy the RG EXACTLY as written in Azure or Entra if you so choose to use this param")]
        [string]
        $ResourceGroup,

        #Resource (mostly shouldnt use this)
        [Parameter(Mandatory=$false, HelpMessage="This is NOT Manditory but please copy the Resource EXACTLY as written in Azure or Entra if you so choose to use this param")]
        [string]
        $Resource,

        #Role
        [Parameter(Mandatory=$true, HelpMessage="This is a Manditory please copy the Role Name EXACTLY as written in Azure or Entra and use underscore for spaces. Example: Key_Vault_Secrets_User")]
        [String]
        $Role
    )


    #If ResourceGroup is not provided, prompt user for input
    if (-not $ResourceGroup) {
        $ResourceGroup = Read-Host "Please enter the ResourceGroup, copy exact from azure/entra (Leave blank if not required)"
    }

    #If Resource is not provided, prompt user for input
    if (-not $Resource) {
        $Resource = Read-Host "Please enter the Resource, copy exact from azure/entra (Leave blank if not required)"
    }

    #Now process the rest of the parameters as normal
    Write-Host "Group Type: $GroupType"
    Write-Host "Assignment Type: $AssignmentType"
    Write-Host "Context: $Context"
    Write-Host "Subscription: $Subscription"
    Write-Host "Role: $Role"


    #Set Delimiter for variables
    $Delimiter = ":"

    #If ResourceGroup and Resource are provided, handle them here
    if ($ResourceGroup) {
        Write-Host "Resource Group: $ResourceGroup"
    }
    if ($Resource) {
        Write-Host "Resource: $Resource"
    }
    else {
        Write-Host "No Resource provided."
    }

    ############                             ############
    ############ Defining Group Descriptions ############
    ############                             ############

    #Set the the description variable for GroupType User 
    if ($GroupType = "UG"){
        $DescGT = "GroupType: User Group | "
    }

    #Set the the description variable for GroupType Application ROle 
    if ($GroupType = "AR"){
        $DescGT = "GroupType: Application Role | "
    }
   
   
    #Set the the description variable for GroupType PimRole
    if ($GroupType = "PR"){
        $DescGT = "GroupType: Pim Role | "
    }


    #Set the the description variable for Assignment Type if static
    if ($AssignmentType = "s"){
        $DescAssType = "Assignment Type: Static | "
    }

    #Set the the description variable for Assignment Type if dynamic
    if ($AssignmentType = "d"){
        $DescAssType = "Assignment Type: Dynamic | "
    }

    #Set the the description variable for Assignment Type if Function
    if ($AssignmentType = "f"){
        $DescAssType = "Assignment Type: Function | "
    }

    #Set the the description variable for Context
    if ($Context){
        $DescContext = "Context: $Context | "
    }

    #Set the the description variable for Sub
    if ($Subscription){
        $DescSub = "Subscription: $Subscription | "
    }

    #iF resourcegroup provided add the dot delimiter here and set the description variable for it 
    if ($ResourceGroup){
        $DescRG = "ResourceGroup: $ResourceGroup | "
        $ResourceGroup = ".$ResourceGroup" 
    }

    #If resource provided add the dot delimiter here and set the description variable for it 
    if ($Resource){
        $DescR = " $Resource | "
        $Resource = ".$Resource"
    }

    #Set role description 
    if ($Role){
        $DescRole = "Role: $Role"
    }

    #Script to run 
    
    try {
        New-EntraGroup -DisplayName "$GroupType$AssignmentType-$Context$Delimiter$Subscription$ResourceGroup$Resource$Delimiter$Role" `
        -SecurityEnabled $true `
        -Description "$DescGT$DescAssType$DescContext$DescSub$DescRG$DescR$DescRole" `
        -MailEnabled $false -MailNickname NotSet -IsAssignableToRole $false
    }
    catch {
        Write-Host $_
    }
    # New-EntraGroup -DisplayName ARs-Azure:sub-SHC-Hub_Management.rg-SHC-Dev-Hub:Reader 
    # -SecurityEnabled $true -Description 'Group Type: AR | Assignment Type: s | Context: Azure | Ressource scope: sub-SHC-Hub:Management.rg-SHC-Dev-Hub | Role: Reader' 
    # -MailEnabled $false -MailNickname NotSet -IsAssignableToRole $false
}

