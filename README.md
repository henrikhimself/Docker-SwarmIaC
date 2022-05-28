# Powershell script for an Infrastructure-as-Code tool targeting Docker Swarm.
This repository contains Powershell scripts that implements an Infrastructure-as-Code (IaC) tool. It is simple and heavy-handed yet effective when one need to quickly move between different Docker Swarm configurations.

The script ensures Docker Swarm is active before creating configs, secrets, networks and stacks as described in a configuration file. Each invocation of the script will tear down all services, undeploy stacks and delete configs/secrets/networks before setting up Docker Swarm to match the configuration file being used.

I use this tool in my homelab only. There are much better tools for real set ups.

# Example use:
./Set-Docker.ps1 -ConfigFilePath ./example.host/Config.json
