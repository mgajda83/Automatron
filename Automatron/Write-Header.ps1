Function Write-Header
{
	[CmdletBinding()]
	Param
	(
		$ParentInvocation,
		$Requires
	)

	#Disable pwsh ANSI colour code - '[32;1m' junks
	if($Host.Version -gt [Version]"7.2") { $PSStyle.OutputRendering = [System.Management.Automation.OutputRendering]::PlainText }

	#Check required elements
	if($null -ne $Requires)
	{
		#Test minimum PS version
		if($null -ne $Requires.PSVersion)
		{
			if($Host.Version -lt [Version]$Requires.PSVersion)
			{
				throw "The script cannot be run because it contained a statement for minimum Windows PowerShell version:$($Requires.PSVersion). The version of Windows PowerShell that is required by the script does not match the currently running version of Windows PowerShell $($Host.Version.ToString())."
			}
		}

		#Test modules are available
		if($null -ne $Requires.Modules)
		{
			Foreach($Module in $Requires.Modules)
			{
				if($null -ne $Module.ModuleVersion)
				{
					if($null -eq $(Get-Module -ListAvailable -Name $Module.ModuleName | Where-Object { $_.Version -ge [Version]$Module.ModuleVersion }))
					{
						throw "The script cannot be run because it contained a statement for required module:$($Module.ModuleName) in minimum version $($Module.ModuleVersion). The module that is required by the script does not match the currently available modules."
					}
				} else {
					if($null -eq $(Get-Module -ListAvailable -Name $Module.ModuleName))
					{
						throw "The script cannot be run because it contained a statement for required module:$($Module.ModuleName). The module that is required by the script does not match the currently available modules."
					}
				}
			}
		}
	}

	#Get JobId
	$JobIdStatus = ""
	if($null -ne $PSPrivateMetadata.JobId)
	{
		#Usually on HybridWorker PS 5.1 or SandboxHost
		$JobId = $PSPrivateMetadata.JobId.Guid
		$JobIdStatus = " (PSPrivateMetadata)"
	} else {
		if($Env:PSPrivateMetadata -ne "System.Collections.Hashtable" -and $null -ne $Env:PSPrivateMetadata)
		{
			#Usually on HybridWorker PS 7.2
			$JobId = $Env:PSPrivateMetadata
			$JobIdStatus = " (Env)"
		} else {
			#Fix HybridWorker v1.3.63+ problem (System.Collections.Hashtable as String)
			$SandboxesPath = "C:\ProgramData\Microsoft\System Center\Orchestrator\7.2\SMA\Sandboxes\"
			if(Test-Path -Path $SandboxesPath)
			{
				$LastSandboxPath = Get-ChildItem -Path $SandboxesPath | Sort-Object LastWriteTime -Descending | Select-Object -ExpandProperty FullName -First 1
				$LogPath = Get-ChildItem -Path $LastSandboxPath -Include "trace.log" -Recurse
				$JobId = ((Get-Content $LogPath | Select-String "jobId") -split 'jobId=')[1] -replace ']',''
				$JobIdStatus = " (Trace.log)"
			}
		}
	}
	if($null -ne $JobId) { if([Guid]::TryParse($JobId, $([ref][Guid]::Empty))) { Set-Variable -Name CorrelationId -Value $JobId -Scope Global } }

	#Get HostIP
	$IPInfo = Invoke-RestMethod -Uri ipinfo.io -ErrorAction SilentlyContinue

	#If HybridWorker, check agent version
	$Hostname = hostname
	if($Hostname -notmatch "SandboxHost-")
	{
		#Get HybridWorkerForWindows version from current running service
		$HybridWorkerAgentPath = Get-CimInstance -Query 'Select * from Win32_Service Where name="HybridWorkerService"' | Select-Object -exp PathName
		if($null -ne $HybridWorkerAgentPath)
		{
			$HybridWorker = $HybridWorkerAgentPath -Replace('C:\\Packages\\Plugins\\Microsoft.Azure.Automation.HybridWorker.HybridWorkerForWindows\\','') -Replace('\\HybridWorkerPackage\\HybridWorkerAgent\\HybridWorkerService.exe','')
			$HybridWorkerVersion = " (HybridWorkerAgent:$HybridWorker)"
		} else {
			#If cant, get HybridWorkerForWindows latest version of agent folder
			$HybridWorkerAgentPath = "C:\Packages\Plugins\Microsoft.Azure.Automation.HybridWorker.HybridWorkerForWindows"
			if(Test-Path -Path $HybridWorkerAgentPath)
			{
				$HybridWorker = Get-ChildItem -Path $HybridWorkerAgentPath | Select-Object @{l="Version";e={[Version]$_.Name}} | Sort-Object Version -Descending | Select-Object @{l="Version";e={$_.Version.ToString()}} -First 1 | Select-Object -ExpandProperty Version
				$HybridWorkerVersion = " (HybridWorkerAgent:$($HybridWorker)?)"
			}
		}
	}

	#Show enviroment
	"###########################################################"
	"### Run at:"
	"# StartDateTime: $(Get-Date)"
	if($null -ne $IPInfo) { "# PublicIP: $($IPInfo.ip) ($($IPInfo.City), $($IPInfo.region), $($IPInfo.country))" }
	"# Hostname: $Hostname$HybridWorkerVersion"
	"# Username: $(whoami)"
	"# PowerShell: $($Host.Version.ToString())"
	"# CorrelationId: $JobId$JobIdStatus"
	"# Automatron: $((Get-Module Automatron).Version.ToString())"
	if($null -ne $Requires)	{ "# Requires: $($Requires | ConvertTo-Json -Compress)" }

	#List used params
	$Params = [Ordered]@{}
	#Get parameters with default defined value
	[ScriptBlock]::Create($ParentInvocation.MyCommand.ScriptBlock.ToString()).Ast.ParamBlock.Parameters | Where-Object { $null -ne $_.DefaultValue } | ForEach-Object { $Params[$($_.Name -replace '\$')] = [PSCustomObject]@{Name=$($_.Name -replace '\$');Value=$(Invoke-Expression -Command $_.DefaultValue.ToString());Default=$true} }

	#Get parameters with user defined value
	$ParentInvocation.BoundParameters.GetEnumerator() | ForEach-Object { $Params[$($_.Key)] = [PSCustomObject]@{Name=$_.Key;Value=$_.Value;Default=$false} }
	if($Params.GetEnumerator().Count) { "### Params:" }

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

#Write-Automatron -ParentInvocation $MyInvocation -Requires @{PSVersion="7.6"}
