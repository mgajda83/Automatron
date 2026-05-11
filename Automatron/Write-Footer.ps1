Function Write-Footer
{
	[CmdletBinding()]
	Param
	(
		$ParentErrors,
		$IgonreErrors,
		[Switch]$Detailed,
		[ValidateSet("Stop","Continue")]
		[String]$ErrorFooterAction
	)

	#Build footer
	"###########################################################"
	"# StopDateTime: $(Get-Date)"

	#Filter Errors
	if($null -ne $IgonreErrors)
	{
		"# Ignore Errors: $($IgonreErrors | ConvertTo-Json -Compress)"
		"# Total Errors: $($ParentErrors.Count)"

		$TempErrors = $ParentErrors
		if($IgonreErrors -is [String])
		{
			#Basic filter
			$TempErrors = $TempErrors | Where-Object ScriptStackTrace -NotMatch $IgonreErrors
		} else {
			#Advanced filters
			if($IgonreErrors['ScriptStackTrace']) { $TempErrors = $TempErrors | Where-Object ScriptStackTrace -NotMatch $IgonreErrors['ScriptStackTrace'] }
			if($IgonreErrors['ErrorDetails']) { $TempErrors = $TempErrors | Where-Object ErrorDetails -NotMatch $IgonreErrors['ErrorDetails'] }
			if($IgonreErrors['Exception']) { $TempErrors = $TempErrors | Where-Object Exception -NotMatch $IgonreErrors['Exception'] }
		}

		$Errors = $TempErrors 
	} else {
		$Errors = $ParentErrors
	}

	"# Errors: $($Errors.Count)"
	if($Errors.Count)
	{
		if($Detailed) { $Errors | Select-Object * }
		Write-Error "$($Errors.Count) errors detected in the script" -ErrorAction $ErrorFooterAction
	}

	"###########################################################"
}

#Write-Footer -ParentErrors $Error -IgonreErrors @{ScriptStackTrace="AzTable|PowerShellGet";ErrorDetails="ConversationBlockedByUser"} -ErrorFooterAction Continue -Detailed
#Write-Footer -ParentErrors $Error -IgonreErrors "AzTable|PowerShellGet" -ErrorFooterAction Stop -Detailed