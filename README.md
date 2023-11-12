# debenstack-salt

Contains salt configuration for setting up the debenstack server

Configured also to work with vagrant for testing and development


# Salt Help
* Great resource for salt-call commands: https://docs.saltproject.io/en/latest/ref/cli/salt-call.html


```bash
# List all grains
salt-call --grains
# List all custom graints
cat /etc/salt/grains
# Fetch a specific grain
salt-call --local grains.get <grain>
```
