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

Function Start-CreateStacks([string]$configPath, [PSCustomObject[]]$stacks) {
    Write-Information '- Creating stacks'
    foreach ($stack in $stacks) {
        [string]$stackName = $($stack.Name).ToLower()
        [string]$stackFilePath = $stack.FilePath
        Write-Information "$stackName $stackFilePath"
        docker @('stack', 'deploy', '-c', (Join-Path $configPath $stackFilePath), $stackName)
    }
}

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

Function Start-CreateConfigs([string]$configPath, [PSCustomObject[]]$configs) {
    Write-Information '- Creating configs'
    foreach ($config in $configs) {
        [string]$configName = $($config.Name).ToLower()
        [string]$configFilePath = $config.FilePath
        Write-Information "$configName $configFilePath"
        & docker @('config', 'create', $configName, (Join-Path $ConfigPath $configFilePath))
    }
}

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

Function Start-CreateSecrets([string]$configPath, [PSCustomObject[]]$secrets) {
    Write-Information '- Creating secrets'
    foreach ($secret in $secrets) {
        [string]$secretName = $($secret.Name).ToLower()
        [string]$secretFilePath = $secret.FilePath
        Write-Information "$secretName $secretFilePath"
        docker @('secret', 'create', $secretName, (Join-Path $configPath $secretFilePath))
    }
}

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
    function RemoveNetwork([string]$networkName) {
        & docker @('network', 'rm', $networkName)
        while (@(GetNetworkNames) -contains $networkName) {
            Start-Sleep 1
        }
    }
    $deferredNetwork = @()
    foreach ($networkName in @((GetNetworkNames))) {
        if ((& docker @('network', 'inspect', '--format', '{{.ConfigOnly}}', $networkName)) -eq 'true') {
            $deferredNetwork += $networkName
        } else {
            RemoveNetwork($networkName)
        }
    }
    foreach ($networkName in $deferredNetwork) {
        RemoveNetwork($networkName)
    }
}

Function Start-CreateNetworks([string]$configPath, [PSCustomObject[]]$networks) {
    Write-Information '- Creating networks'
    function CreateNetwork([PSCustomObject]$network) {
        [string]$networkName = $($network.Name).ToLower()
        [string[]]$networkArgs = $network.Args
        Write-Information "$networkName"
        $dockerArgs = @(
            'network', 'create'
        )
        $dockerArgs += $networkArgs
        $dockerArgs += @(
            $networkName
        )
        & docker $dockerArgs
    }
    $deferredNetwork = @()
    foreach ($network in $networks) {
        if ($network.Args -contains '--config-only') {
            CreateNetwork($network)
        } else {
            $deferredNetwork += $network
        }
    }
    foreach ($network in $deferredNetwork) {
        CreateNetwork($network)
    }
}
