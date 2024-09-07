Import-Module -name AWSPowerShell

# Define your parameters
$hostedZoneId = "ZZZZZ"               # The ID of your hosted zone in Route 53.
$recordName = "subdomain.url.co"               # The A record you want to update (e.g., "subdomain.example.com.")
$awsRegion = "us-west-2"              # The AWS region (if using Route 53 in a specific region)

# Fetch the public IPv4 address from the metadata service.
$ipUrl = "http://checkip.amazonaws.com/"
$publicIp = Invoke-RestMethod -Uri $ipUrl
if (-not $publicIp) {
    Write-Error "Failed to retrieve the public IP address."
    exit 1
}
Write-Output "Public IP Address: $publicIp"
#$publicIp = "2.2.2.2"

# Update Route53.
$changer = New-Object Amazon.Route53.Model.Change
$changer.Action = "UPSERT"
$changer.ResourceRecordSet = New-Object Amazon.Route53.Model.ResourceRecordSet
$changer.ResourceRecordSet.Name = $recordName
$changer.ResourceRecordSet.Type = "A"
$changer.ResourceRecordSet.TTL = 300
$changer.ResourceRecordSet.ResourceRecords.Add(@{Value=$publicIp})
$params = @{
    HostedZoneId=$hostedZoneId
	ChangeBatch_Comment="Auto-update."
	ChangeBatch_Change=$changer
}
Edit-R53ResourceRecordSet @params
