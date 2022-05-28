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
	Clears Docker configuration.
    .DESCRIPTION
    This script will clear configuration. It will do this by removing 
    previously deployed stacks, configs, secrets and custom networks.
    .EXAMPLE
    PS> ./Clear-Docker.ps1
#>
#requires -Version 7
[CmdletBinding()]
param()
Set-StrictMode -Version Latest
$InformationPreference = 'Continue'
$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot 'Shared.ps1')

Function Clear-Docker {
    # - Invoke functions to clear Docker configuration.
    Start-RemoveStacks
    Start-RemoveConfigs
    Start-RemoveSecrets
    Start-RemoveNetworks
}

if ($MyInvocation.InvocationName -ne '.') {
    Clear-Docker
}
