<#
This script monitors the Microsoft Entra Id App Registrations that are about to expire.

The script retrieves all the applications in the tenant and checks the credentials that are about to expire in the next 90 days.

The script requires the following parameters:
- DaysUntilExpiration: The number of days until the credential expires. The default value is 90 days.
- TenantId: The tenant ID where the applications are registered.
- ClientId: The client ID of the application that will be used to connect to the Microsoft Graph API.
- ClientSecret: The client secret of the application that will be used to connect to the Microsoft Graph API.

The script outputs the following information for each credential that is about to expire:
- ApplicationID: The application ID.
- ApplicationName: The application display name.
- CredentialID: The credential ID.
- CredentialName: The credential display name.
- CredentialType: The credential type (Password or Certificate).
- CredentialStartDate: The credential start date.
- CredentialEndDate: The credential end date.

#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [Int32]$DaysUntilExpiration = 90,
    
    [Parameter(Mandatory = $true)]
    [String]$TenantId,
    
    [Parameter(Mandatory = $true)]
    [String]$ClientId,
    
    [Parameter(Mandatory = $true)]
    [String]$CertificateThumbprint
)

Connect-MgGraph -TenantId $TenantId -ClientId -CertificateThumbprint $CertificateThumbprint -NoWelcome

$Now = Get-Date

$Applications = Get-MgApplication -All

foreach ($App in $Applications) {
    
    $AppName = $App.DisplayName
    $AppId   = $App.AppId

    $AppCredentials = @($App.PasswordCredentials) + @($App.KeyCredentials)

    foreach ($Credential in $AppCredentials) {

        $StartDate      = $Credential.StartDateTime
        $EndDate        = $Credential.EndDateTime
        $CredentialId   = $Credential.KeyId
        $CredentialName = $Credential.DisplayName
        $CredentialType = switch ($Credential.GetType().Name) {
            'MicrosoftGraphPasswordCredential' { 'Password' }
            'MicrosoftGraphKeyCredential' { 'Certificate' }
            default { 'Unknown' }
        }
        
        $RemainingDaysCount = ($EndDate - $Now).Days

        if ($RemainingDaysCount -le $DaysUntilExpiration -and $RemainingDaysCount -ge 0) {
            
            @{
                'ApplicationID'         = $AppId
                'ApplicationName'       = $AppName
                'CredentialID'          = $CredentialId
                'CredentialName'        = $CredentialName
                'CredentialType'        = $CredentialType
                'CredentialStartDate'   = $StartDate
                'CredentialEndDate'     = $EndDate
            }

            Write-Host "`n`n"
        }

    }

}
