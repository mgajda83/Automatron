Function Write-Automatron
{
	[CmdletBinding()]
	Param
	(
		$ParentInvocation
	)

	#Disable pwsh ANSI colour code - '[32;1m' junks
	if($Host.Version -gt [Version]"7.2") { $PSStyle.OutputRendering = [System.Management.Automation.OutputRendering]::PlainText }

	#Get JobID
	$JobIdStatus = ""
	if($PSPrivateMetadata.JobId.Guid)
	{
		$JobID = $PSPrivateMetadata.JobId.Guid
		$JobIdStatus = "PSPrivateMetadata"
	} else {
		if($Env:PSPrivateMetadata -ne "System.Collections.Hashtable")
		{
			$JobID = $Env:PSPrivateMetadata
			$JobIdStatus = "Env"
		} else {
			#Fix HybridWorker v1.3.63 problem
			$ParentPath = Split-Path -Parent $PSScriptRoot
			$LogPath = Join-Path -Path $ParentPath -ChildPath "\diags\trace.log"
			$JobID = ((Get-Content $LogPath -ErrorAction Stop | Select-String "jobId") -split 'jobId=')[1] -replace ']',''
			$JobIdStatus = "trace.log"
		}
	}
	if($null -ne $JobID) { if(![Guid]::TryParse($JobID, $([ref][Guid]::Empty))) { $JobID = $null } }

	#Get HostIP
	$IPInfo = Invoke-RestMethod -Uri ipinfo.io -ErrorAction SilentlyContinue

	#Show enviroment
    "###########################################################"
	"### Run at:"
	if($null -ne $IPInfo) { "# PublicIP: " + "$($IPInfo.ip) ($($IPInfo.City), $($IPInfo.region), $($IPInfo.country))" }
	"# StartDateTime: " + (Get-Date)
    "# Hostname: " + $(hostname)
	"# Username: " + $(whoami)
	"# PowerShell: " + $Host.Version.ToString()
	"# CorrelationId: " + $JobID + " ($JobIdStatus)"

	#List used params
	"### Params:"
	#Get parameters with default defined value
	[ScriptBlock]::Create($ParentInvocation.MyCommand.ScriptBlock.ToString()).Ast.ParamBlock.Parameters | Where-Object { $null -ne $_.DefaultValue } | ForEach-Object { "# $($_.Name -replace "\$"): $($_.DefaultValue -replace '"') (Default)"}
    #Get parameters with user defined value
	$ParentInvocation.BoundParameters.GetEnumerator() | ForEach-Object { "# $($_.Key): $($_.Value)"}
    "###########################################################"

	Return [String]$JobID
}

#$CorrelationId = Write-Automatron -ParentInvocation $MyInvocation
