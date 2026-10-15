A module that helps organize PowerShell runbooks work in Azure Automation Account.

Show header output:
```
> Write-Header -ParentInvocation $MyInvocation -Requires @{PSVersion="7.6"}


###########################################################
### Run at:
# StartDateTime: 04/13/2026 16:03:58
# PublicIP: 20.31.141.166 (Amsterdam, North Holland, NL)
# Hostname: SandboxHost-639116928817572349
# Username: user manager\containeruser
# PowerShell: 7.4.6
# CorrelationId: 62637f90-9182-4279-bc2d-4bc672026841 (PSPrivateMetadata)
# Automatron: 1.0.0.27
# Requires: @{PSVersion="7.6"}
### Params:
# CheckOnly: false [Boolean] (Default)
# LastRun: "2026-04-13T16:03:58.1618642+00:00" [DateTime] (Default)
###########################################################
```


Show footer output:
```
> Write-Footer -ParentErrors $Error -IgonreErrors @{ScriptStackTrace="PowerShellGet";ErrorDetails="ConversationBlockedByUser"} -ErrorFooterAction Continue -Detailed


###########################################################
# StopDateTime: 04/13/2026 16:23:34
# Igonre Errors: {"ScriptStackTrace":"PowerShellGet","ErrorDetails":"ConversationBlockedByUser"}
# Total Errors: 0
# Errors: 0
###########################################################
```
