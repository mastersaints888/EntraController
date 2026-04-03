#converting the cache objects to XML and back to objects to ensure 
#that they are serializable and can be stored in a file or transmitted 
#over a network without losing any information. 
#This process is useful for debugging, logging, or persisting the cache data.

function Start-EzRbacDataBaseUpdate {


$mgCach_ToConvert = Get-RbacCache -mancache
$mgCach_ToConvert | ConvertTo-Xml  -As String -Depth 4 -NoTypeInformation
$mgCach_ToConvert | Export-Clixml -Path "$env:TEMP\mgCache.xml"
$global:mgCacheXML = Import-Clixml -Path "$env:TEMP\mgCache.xml"

$SubscriptionCache_toConvert = Get-RbacCache -subcache
$SubscriptionCache_toConvert | ConvertTo-Xml  -As String -Depth 4 -NoTypeInformation
$SubscriptionCache_toConvert | Export-Clixml -Path "$env:TEMP\subCache.xml"
$global:SubCacheXML = Import-Clixml -Path "$env:TEMP\subCache.xml"

$rgCache_toConvert = Get-RbacCache -rgcache
$rgCache_toConvert | ConvertTo-Xml  -As String -Depth 4 -NoTypeInformation
$rgCache_toConvert | Export-Clixml -Path "$env:TEMP\rgCache.xml"
$global:rgCacheXML = Import-Clixml -Path "$env:TEMP\rgCache.xml"

}


Function Start-EzRbacDataBaseUpdateJob {
    $Get_EzRbacCache = "$env:USERPROFILE\Documents\EntraController\SubsAndRBAC\Get-EzRbac.ps1"
    $Get_XmlCache = "$env:USERPROFILE\Documents\EntraController\Cache\RbacCache.ps1"
    

    Start-ThreadJob -ScriptBlock {
        # Dot-source the entire script — loads ALL functions from it into the job's scope
        . $using:Get_EzRbacCache
        . $using:Get_XmlCache

        $running = $true
        While ($running) {
            Start-EzRbacDataBaseUpdate
            Start-Sleep -Seconds 900 # Sleep for 15 minutes (900 seconds) before the next update
        }
    }
}




