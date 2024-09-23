<#
This script creates the Microsoft Entra Id App Registration that will be used by the monitoring solution to access the Microsoft Graph API. 

The script creates an application with the following properties:
- Display Name: App Registration Secret Expiry Monitoring Solution
- Required Resource Access: Application.Read.All and Directory.Read.All
- Admin Consent: Required
- Redirect URI: https://www.microsoft.com
- Secret Expiry: 24 months
- Secret Display Name: Initial Password created by PowerShell Script
#>

#
# Parameters
#

[CmdletBinding()]
param (
    $TenantId = "f57d05db-8771-4aa9-8802-d97fcff5b2ab",
    
    $ApplicationDisplayName = "App Registration Secret Expiry Monitoring Solution",
    
    # Client secret expiry in months
    $ApplicationSecretExpiryInMonths = 24,
       
    # Redirect URI for the application
    $ApplicationRedirectUri = "https://www.microsoft.com"
)

#
# Request the "Application.Read.All" and "Directory.Read.All" Microsoft Graph application permissions
#

# Reference: https://learn.microsoft.com/en-us/graph/api/resources/requiredresourceaccess?view=graph-rest-1.0
$RequiredResourceAccess = @{
    # Microsoft Graph Application Id
    resourceAppId = "00000003-0000-0000-c000-000000000000"
    resourceAccess = @(
        @{
            # Application.Read.All application permission: https://learn.microsoft.com/en-us/graph/permissions-reference#applicationreadall
            id = "9a5d68dd-52b0-4cc2-bd40-abcf44ac3a30"
            # Application Permissions are also known as App "Roles"
            type = "Role"
        },
        @{
            # Directory.Read.All application permission: https://learn.microsoft.com/en-us/graph/permissions-reference#directoryreadall
            id = "7ab1d382-f21e-4acd-a863-ba3e13f7da61"
            # Use "Role" for Application Permissions - and "Scope" for Delegated Permissions
            type = "Role"
        }
    )
}

#
# Connect to Microsoft Graph and create a new application
#

Connect-MgGraph -TenantId $TenantId -Scopes @("User.Read", "Application.ReadWrite.All") -NoWelcome

$App = New-MgApplication -DisplayName $ApplicationDisplayName -RequiredResourceAccess $RequiredResourceAccess -SignInAudience $ApplicationSignInAudience -Spa @{redirectUris = $ApplicationRedirectUri}

$AppId = $App.AppId

$AppObjectId = $App.Id

Write-Host "`nApplication ID: $AppId"
Write-Host "`nApplication Display Name: $($App.DisplayName)"

#
# Add a new secret to the application
#

$startDate = Get-Date
$endDate = $startDate.AddMonths($ApplicationSecretExpiryInMonths)

$PasswordCredential = @{
   displayName = 'Initial Password created by PowerShell Script'
   startDateTime = $startDate
   endDateTime = $endDate
}

$secret = Add-MgApplicationPassword -ApplicationId $AppObjectId -PasswordCredential $PasswordCredential
$secret | Format-List

#
# Grant Admin Consent for the application
#

Write-Host "Please provide Admin Consent for the application in the new browser window."

# Wait for 2 seconds before opening the browser
Start-Sleep -Seconds 2

# Open the default browser to the Microsoft Entra Admin Consent URL for the new application: https://learn.microsoft.com/en-us/entra/identity/enterprise-apps/grant-admin-consent?pivots=portal#construct-the-url-for-granting-tenant-wide-admin-consent
Start-Process "https://login.microsoftonline.com/$TenantId/adminconsent?client_id=$AppId"
