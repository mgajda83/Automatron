Function Write-Header
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
	if($null -ne $PSPrivateMetadata.JobId)
	{
		#Usually on HybridWorker PS 5.1 or SandboxHost
		$JobId = $PSPrivateMetadata.JobId.Guid
		$JobIdStatus = "PSPrivateMetadata"
	} else {
		if($Env:PSPrivateMetadata -ne "System.Collections.Hashtable")
		{
			#Usually on HybridWorker PS 7.2
			$JobId = $Env:PSPrivateMetadata
			$JobIdStatus = "Env"
		} else {
			#Fix HybridWorker v1.3.63 problem (System.Collections.Hashtable as String)
			$SandboxesPath = "C:\ProgramData\Microsoft\System Center\Orchestrator\7.2\SMA\Sandboxes\"
			if(Test-Path -Path $SandboxesPath)
			{
				$LastSandboxPath = Get-ChildItem -Path $SandboxesPath | Sort-Object LastWriteTime -Descending | Select-Object -ExpandProperty FullName -First 1
				$LogPath = Get-ChildItem -Path $LastSandboxPath -Include "trace.log" -Recurse
				$JobId = ((Get-Content $LogPath | Select-String "jobId") -split 'jobId=')[1] -replace ']',''
				$JobIdStatus = "Trace.log"
			} 
		}
	}
	if($null -ne $JobId) { if([Guid]::TryParse($JobId, $([ref][Guid]::Empty))) { Set-Variable -Name CorrelationId -Value $JobId -Scope Global } }

	#Get HostIP
	$IPInfo = Invoke-RestMethod -Uri ipinfo.io -ErrorAction SilentlyContinue

	#Get HybridWorkerForWindows version
	$HybridWorkerAgentPath = "C:\Packages\Plugins\Microsoft.Azure.Automation.HybridWorker.HybridWorkerForWindows"
	if(Test-Path -Path $HybridWorkerAgentPath)
	{
		$HybridWorker = Get-ChildItem -Path $HybridWorkerAgentPath | Sort-Object CreationTime -Descending | Select-Object -ExpandProperty Name -First 1
		$HybridWorkerVersion = " (HybridWorkerAgent:$HybridWorker)"
	}

	#Show enviroment
	"###########################################################"
	"### Run at:"
	"# StartDateTime: $(Get-Date)"
	if($null -ne $IPInfo) { "# PublicIP: $($IPInfo.ip) ($($IPInfo.City), $($IPInfo.region), $($IPInfo.country))" }
	"# Hostname: $(hostname)$HybridWorkerVersion"
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
Set-Alias -Name Write-Automatron -Value Write-Header

#Write-Automatron -ParentInvocation $MyInvocation -ErrorAction SilentlyContinue
