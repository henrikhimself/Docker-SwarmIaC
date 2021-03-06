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
	Configures Docker using a configuration file.
    .DESCRIPTION
    This script will read in a configuration file and configure Docker to match it. It will
    do this by removing previously deployed stacks, configs, secrets and custom networks 
    before creating the new configuration.
    .PARAMETER ConfigFilePath
    Filepath of the configuration file to use.
    .EXAMPLE
    PS> ./Set-Docker.ps1 -ConfigFilePath ~/iac/example.host/Config.json
#>
#requires -Version 7
[CmdletBinding()]
param(
    [string]$ConfigFilePath = (Join-Path $PSScriptRoot 'example.host' | Join-Path -ChildPath 'Config.json')
)
Set-StrictMode -Version Latest
$InformationPreference = 'Continue'
$ErrorActionPreference = 'Stop'

Function Set-Docker() {
    Clear-Docker
    Initialize-Docker
}

if ($MyInvocation.InvocationName -ne '.') {
    . (Join-Path $PSScriptRoot 'Clear-Docker.ps1')
    . (Join-Path $PSScriptRoot 'Initialize-Docker.ps1') @PSBoundParameters
    Set-Docker
}
