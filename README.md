# Infrastructure as Code script for Docker Swarm.
This script configures Docker and creates configs, secrets, stacks as described in 
a configuration file. 

Each invocation of the script will tear down all services, undeploy stacks and delete 
configs/secrets before setting up Docker according to the definition file being used.

# Example use:
./Set-Docker.ps1 -ConfigPath example.host -ConfigFileName Config.json
