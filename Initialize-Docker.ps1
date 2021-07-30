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
<#  
    .SYNOPSIS
	Initializes Docker using a configuration file.
    .DESCRIPTION
    This script will read in a configuration file and configure Docker to match it.
    .PARAMETER ConfigFilePath
    Filepath of the configuration file to use.
    .EXAMPLE
    PS> ./Initialize-Docker.ps1 -ConfigFilePath ~/iac/example.host/Config.json
#>
#requires -Version 7
[CmdletBinding()]
param(
    [string]$ConfigFilePath = (Join-Path $PSScriptRoot 'example.host' | Join-Path -ChildPath 'Config.json')
)
Set-StrictMode -Version Latest
$InformationPreference = 'Continue'
$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot 'Shared.ps1')

Function Initialize-Docker {
    # - Read configuration.
    [PSCustomObject]$DefinitionFile = Get-Content -Path $ConfigFilePath | ConvertFrom-Json
    $Definition = [PSCustomObject]@{
        Docker = $null
    }
    $Definition.PSObject.Properties | ForEach-Object {
        if (Get-Member -InputObject $DefinitionFile -name $_.Name -Membertype Properties) {
            $_.Value = $DefinitionFile.PSObject.Properties[$_.Name].Value
        }
    }

    [string]$ConfigPath = Split-Path -Path $ConfigFilePath
    [PSCustomObject]$Docker = $Definition.Docker

    # - Invoke functions to configure Docker.
    Start-EnsureSwarmMode
    Start-CreateNetworks $ConfigPath $Docker.Networks
    Start-CreateConfigs $ConfigPath $Docker.Configs
    Start-CreateSecrets $ConfigPath $Docker.Secrets
    Start-CreateStacks $ConfigPath $Docker.Stacks
}

if ($MyInvocation.InvocationName -ne '.') {
    Initialize-Docker
}
