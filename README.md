# opnsense-ospf-alias-automation

This is a simple shell script to read the OSPF routes and add the to a network alias

This script find the alias UUID, deletes any existing networks from the alias, then queries the routing table to find the OSPF routes and adds them to the alias.

You will need to add your API key and Secret, Server URL and Port, and the name of your Network alias.

I chose to store this as /root/update_ospf_alias.sh

Run from a cron job created on the command line.
