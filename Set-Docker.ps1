# Copyright 2021 Henrik Jensen
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

#requires -Version 7
[CmdletBinding()]
param(
    [string]$ConfigPath = 'example.host',
    [string]$ConfigFileName = 'Config.json'
)
Set-StrictMode -Version Latest
$InformationPreference = 'Continue'
$ErrorActionPreference = 'Stop'

<# Global #>
# - Read configuration file.
[string]$ConfigFullPath = Join-Path $PSScriptRoot $ConfigPath | Join-Path -ChildPath $ConfigFileName
[PSCustomObject]$DefinitionFile = Get-Content -Path $ConfigFullPath | ConvertFrom-Json
$Definition = [PSCustomObject]@{
    Docker = $null
}
$Definition.PSObject.Properties | ForEach-Object {
    if (Get-Member -InputObject $DefinitionFile -name $_.Name -Membertype Properties) {
        $_.Value = $DefinitionFile.PSObject.Properties[$_.Name].Value
    }
}

# - Configuration variables.
[PSCustomObject]$Docker = $Definition.Docker

<# Main #>
Function Start-EnsureSwarmMode {
    Write-Information '- Ensuring Swarm is active'
    function IsSwarmInactive {
        (& docker @('info', '--format', '{{.Swarm.LocalNodeState}}')) -ne 'active'
    }
    if (IsSwarmInactive) {
        & docker @('swarm', 'init')
    }
    if (IsSwarmInactive) {
        Write-Error 'Failed to activate Swarm mode'
    }
}
Start-EnsureSwarmMode

Function Start-RemoveStacks {
    Write-Information '- Removing stacks'
    function GetStackNames {
        & docker @('stack', 'ls', '--format', '{{.Name}}')
    }
    foreach ($stackName in @((GetStackNames))) {
        Write-Information "Stack: $stackName"
        & docker @('stack', 'rm', $stackName)
    }
    while (@((GetStackNames)).Length -gt 0) {
        Start-Sleep 1
    }
}
Start-RemoveStacks

Function Start-RemoveConfigs {
    Write-Information '- Removing configs'
    function GetConfigNames {
        & docker @('config', 'ls', '--format', '{{.Name}}')
    }
    foreach ($configName in @((GetConfigNames))) {
        & docker @('config', 'rm', $configName)
    }
    while (@((GetConfigNames)).Length -gt 0) {
        Start-Sleep 1
    }
}
Start-RemoveConfigs

Function Start-RemoveSecrets {
    Write-Information '- Removing secrets'
    function GetSecretNames {
        & docker @('secret', 'ls', '--format', '{{.Name}}')
    }
    foreach ($secretName in @((GetSecretNames))) {
        & docker @('secret', 'rm', $secretName)
    }
    while (@((GetSecretNames)).Length -gt 0) {
        Start-Sleep 1
    }
}
Start-RemoveSecrets

Function Start-RemoveNetworks {
    Write-Information '- Removing networks'
    function GetNetworkNames {
        $networkNames = @()
        $excludeNetworkNames = @('bridge', 'docker_gwbridge', 'host', 'ingress', 'none')
        foreach ($networkName in (& docker @('network', 'ls', '--format', '{{.Name}}'))) {
            if (!($excludeNetworkNames -contains $networkName)) {
                $networkNames += $networkName
            }
        }
        $networkNames
    }
    foreach ($networkName in @((GetNetworkNames))) {
        & docker @('network', 'rm', $networkName)
    }
    while (@((GetNetworkNames)).Length -gt 0) {
        Start-Sleep 1
    }
}
Start-RemoveNetworks

Function Start-CreateNetworks {
    Write-Information '- Creating networks'
    foreach ($network in $Docker.Networks) {
        [string]$networkName = $($network.Name).ToLower()
        [string]$networkDriver = $network.Driver
        Write-Information "$networkName $networkDriver"
        & docker @('network', 'create', '--driver', $networkDriver, '--attachable', $networkName)
    }
}
Start-CreateNetworks

# - Configs
Function Start-CreateConfigs {
    Write-Information '- Creating configs'
    foreach ($config in $Docker.Configs) {
        [string]$configName = $($config.Name).ToLower()
        [string]$configFilePath = $config.FilePath
        Write-Information "$configName $configFilePath"
        & docker @('config', 'create', $configName, (Join-Path $ConfigPath $configFilePath))
    }
}
Start-CreateConfigs

Function Start-CreateSecrets {
    Write-Information '- Creating secrets'
    foreach ($secret in $Docker.Secrets) {
        [string]$secretName = $($secret.Name).ToLower()
        [string]$secretFilePath = $secret.FilePath
        Write-Information "$secretName $secretFilePath"
        docker @('secret', 'create', $secretName, (Join-Path $ConfigPath $secretFilePath))
    }
}
Start-CreateSecrets

Function Start-CreateStacks {
    Write-Information '- Creating stacks'
    foreach ($stack in $Docker.Stacks) {
        [string]$stackName = $($stack.Name).ToLower()
        [string]$stackFilePath = $stack.FilePath
        Write-Information "$stackName $stackFilePath"
        docker @('stack', 'deploy', '-c', (Join-Path $ConfigPath $stackFilePath), $stackName)
    }
}
Start-CreateStacks
