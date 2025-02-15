using namespace System.Net

# Input bindings are passed in via param block.
param($Request, $TriggerMetadata)

# Write to the Azure Functions log stream.
Write-Host "PowerShell HTTP trigger function processed a request."
Log-Request -user $request.headers.'x-ms-client-principal' -API $APINAME  -message "Accessed this API" -Sev "Debug"
# Interact with query parameters or the body of the request.
$TenantFilter = $Request.Query.TenantFilter
$currentTime = Get-Date -Format "yyyy-MM-ddTHH:MM:ss"
$ts = (Get-Date).AddDays(-30)
$endTime = $ts.ToString("yyyy-MM-ddTHH:MM:ss")
##Create Filter for basic auth sign-ins
$filters = "createdDateTime ge $($endTime)Z and createdDateTime lt $($currentTime)Z and (clientAppUsed eq 'AutoDiscover' or clientAppUsed eq 'Exchange ActiveSync' or clientAppUsed eq 'Exchange Online PowerShell' or clientAppUsed eq 'Exchange Web Services' or clientAppUsed eq 'IMAP4' or clientAppUsed eq 'MAPI Over HTTP' or clientAppUsed eq 'Offline Address Book' or clientAppUsed eq 'Outlook Anywhere (RPC over HTTP)' or clientAppUsed eq 'Other clients' or clientAppUsed eq 'POP3' or clientAppUsed eq 'Reporting Web Services' or clientAppUsed eq 'Authenticated SMTP' or clientAppUsed eq 'Outlook Service')"
try {
    $GraphRequest = New-GraphGetRequest -uri "https://graph.microsoft.com/beta/auditLogs/signIns?api-version=beta&filter=$($filters)" -tenantid $TenantFilter -erroraction stop | Select-Object userPrincipalName, clientAppUsed | Sort-Object -Unique -Property clientAppUsed
    $response = $GraphRequest
    Log-Request -user $request.headers.'x-ms-client-principal' -API $APINAME  -message  "Retrieved basic authentication report" -Sev "Debug" -tenant $TenantFilter
    
    # Associate values to output bindings by calling 'Push-OutputBinding'.
    Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
            StatusCode = [HttpStatusCode]::OK
            Body       = @($response)
        })
}
catch {
    Log-Request -user $request.headers.'x-ms-client-principal' -API $APINAME  -message "Failed to retrieve basic authentication report: $($_.Exception.message) " -Sev "Error"  -tenant $TenantFilter
    # Associate values to output bindings by calling 'Push-OutputBinding'.
    Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
            StatusCode = '500'
            Body       = $(Get-NormalizedError -message $_.Exception.message)
        })
}
