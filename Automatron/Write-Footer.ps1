Function Write-Footer
{
	[CmdletBinding()]
	Param
	(
		$ParentErrors,
		[String]$IgonreErrors = "AzTable|PowerShellGet",
		[Switch]$Detailed
	)

	$Errors = $ParentErrors | Where-Object ScriptStackTrace -NotMatch $IgonreErrors

	"###########################################################"
	"# StopDateTime: $(Get-Date)"
	"# Igonre Errors: $IgonreErrors"
	"# Total Errors: $($ParentErrors.Count)"
	"# Errors: $($Errors.Count)"
	if($Errors.Count)
	{
		if($Detailed) { $Errors | Select-Object * }
		Write-Error "$($Errors.Count) errors detected in the script" -ErrorAction Stop
	}

	"###########################################################"
}

#Write-Footer -ParentErrors $Error -IgonreErrors "AzTable|PowerShellGet" -Detailed