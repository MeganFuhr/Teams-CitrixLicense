begin {
    try {
        Add-PSSnapin Citrix.* -ErrorAction SilentlyContinue
    }
    Catch {RETURN}
    
    $uri = "https://outlook.office.com/webhook/URL_To_Channel"
    $ddcs = @("DDC01","DDC02")
    $licenseserver = "LicenseServer.Company.com"
    $output = @()
    $licenseCount = Get-WmiObject -class “Citrix_GT_License_Pool” -namespace “ROOT\CitrixLicensing” -ComputerName $licenseserver | where {$_.PLD -eq "XDS_PLT_CCS"}
    $remaining = 0
    
}

Process {
    foreach ($DDC in $DDCS) {
        $hold = Get-BrokerSite -AdminAddress $ddc

        $temp = New-Object psobject -Property @{
            name=$ddc
            Value = $hold.LicensedSessionsActive
            #PeakConcurrentSessions = $hold.PeakConcurrentLicenseUsers
            #LicenseEdition = $hold.LicenseEdition               
            }
        
        $output += $temp
    }

    foreach ($a in $output) {
        $remaining += $a.value
    }
}


end{

    # these values would be retrieved from or set by an application
$body = @()
$body = ConvertTo-Json -Depth 4 @{
    title = 'Citrix License Usage'
    text = "This card displays the current active license usage for Citrix."
    sections = @(
        @{
            #activityTitle = 'Citrix License Count'
            #activitySubtitle = 'Current license count'
            #activityText = 'See the current license usage count'
            #activityImage = '\\Path\To\Image\0.png' # this value would be a path to a nice image you would like to display in notifications
            title = 'Total Licenses Available'
            text = "$($licenseCount.count - $licenseCount.overdraft)"
        },
        @{
            title = 'Total Licenses Remaining'
            text = "$(($licenseCount.count - $licenseCount.overdraft)-$remaining)"

            facts = @(
                $output       
            )
        }
        
    )
    #potentialAction = @(@{
    #        '@context' = 'http://schema.org'
    #        '@type' = 'ViewAction'
    #        name = 'Click here to visit PowerShell.org'
    #        target = @('http://powershell.org')
    #    })
}

Invoke-RestMethod -uri $uri -Method Post -body $body -ContentType 'application/json'
}