Function Write-Automatron
{
	[CmdletBinding()]
	Param
	(
		$ParentInvocation
	)

	#Disable pwsh ANSI colour code - '[32;1m' junks
	if($Host.Version -gt [Version]"7.2") { $PSStyle.OutputRendering = [System.Management.Automation.OutputRendering]::PlainText }

	#Get JobId
	$JobIdStatus = ""
	if($PSPrivateMetadata.JobId.Guid)
	{
		$JobId = $PSPrivateMetadata.JobId.Guid
		$JobIdStatus = "PSPrivateMetadata"
	} else {
		if($Env:PSPrivateMetadata -ne "System.Collections.Hashtable")
		{
			$JobId = $Env:PSPrivateMetadata
			$JobIdStatus = "Env"
		} else {
			#Fix HybridWorker v1.3.63 problem
			$ParentPath = Split-Path -Parent $PSScriptRoot -ErrorAction SilentlyContinue
			$LogPath = Join-Path -Path $ParentPath -ChildPath "\diags\trace.log" -ErrorAction SilentlyContinue
			$JobId = ((Get-Content $LogPath -ErrorAction SilentlyContinue | Select-String "jobId") -split 'jobId=')[1] -replace ']',''
			$JobIdStatus = "trace.log"
		}
	}
	if($null -ne $JobId) { if([Guid]::TryParse($JobId, $([ref][Guid]::Empty))) { Set-Variable -Name CorrelationId -Value $JobId -Scope Global } }

	#Get HostIP
	$IPInfo = Invoke-RestMethod -Uri ipinfo.io -ErrorAction SilentlyContinue

	#Show enviroment
    "###########################################################"
	"### Run at:"
	"# StartDateTime: $(Get-Date)"
	if($null -ne $IPInfo) { "# PublicIP: $($IPInfo.ip) ($($IPInfo.City), $($IPInfo.region), $($IPInfo.country))" }
    "# Hostname: $(hostname)"
	"# Username: $(whoami)"
	"# PowerShell: $($Host.Version.ToString())"
	"# CorrelationId: $JobId ($JobIdStatus)"
	"# Automatron: $((Get-Module Automatron).Version.ToString())"

	#List used params
	"### Params:"
	$Params = [Ordered]@{}
	#Get parameters with default defined value
	[ScriptBlock]::Create($ParentInvocation.MyCommand.ScriptBlock.ToString()).Ast.ParamBlock.Parameters | Where-Object { $null -ne $_.DefaultValue } | ForEach-Object { $Params[$($_.Name -replace '\$')] = [PSCustomObject]@{Name=$($_.Name -replace '\$');Value=$(Invoke-Expression -Command $_.DefaultValue.ToString());Default=$true} }

	#Get parameters with user defined value
	$ParentInvocation.BoundParameters.GetEnumerator() | ForEach-Object { $Params[$($_.Key)] = [PSCustomObject]@{Name=$_.Key;Value=$_.Value;Default=$false} }

	#Show params
	Foreach($Param in $Params.Values) 
	{
		if($Param.Default)
		{
			"# $($Param.Name): $($Param.Value | ConvertTo-Json -Compress) [$($Param.Value.GetType().Name)] (Default)"
		} else {
			"# $($Param.Name): $($Param.Value | ConvertTo-Json -Compress) [$($Param.Value.GetType().Name)]"
		}
	}
    "###########################################################"

}

#Write-Automatron -ParentInvocation $MyInvocation -ErrorAction SilentlyContinue
