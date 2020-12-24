# Define input parameters
param
(
	[string]$TfsUrl = $(throw "TfsUrl must be provided."),
	[string]$ServiceAccountUsername = $(throw "ServiceAccountUsername must be provided."),
	[string]$ServiceAccountPassword = $(throw "ServiceAccountPassword must be provided."),
	[string]$AgentName = $(throw "AgentName must be provided."),
	[string]$PoolName = $(throw "PoolName must be provided."),
	[string]$InstallAgentDir = $(throw "InstallAgentDir must be provided."),
	[string]$WorkFolder = $(throw "WorkFolder must be provided.")
)

& "$InstallAgentDir\config.cmd" --unattended --url $TfsUrl --auth integrated --runAsService --windowsLogonAccount $ServiceAccountUsername --windowsLogonPassword $ServiceAccountPassword --pool $PoolName --agent $AgentName --acceptTeeEula --work $WorkFolder

#Write-Host "Setting git config in global level by the agent's run as user."
#& "$InstallAgentDir\externals\git\cmd\git.exe" config --global http.sslCAInfo $InstallAgentDir\Certificate.pem