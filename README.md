## lightsup.sh
### Bash script to maintain lighthouse up to date
#### M.I.T. Licence


 !!! NOT PRODUCTION READY YET !!!

### BE WARNED
# Current version 0.2: the untested! am waiting for new lighthouse version to test ^^

My previous attempt sacrificed stability on the altar of functionality.  This was a bad idea.

Last time I was implementing features that I was not using myself.  This was a bad idea.

This time I take the other approach, I center on what I need, do little but do it well.

I have only one node on an ubuntu box, other distros might run fine but I can not test.

If you are searching for a similar script that compiles the binaries, 
- https://github.com/ChuckNorrison/lighthouse-update-script is the closest

### Vision: Security and uptime are the objectives.
- I decided to run the precompiled binaries to not have build tools on the server
- Check checksums and pgp signature when getting new binaries.
- Create control checksums of binaries and configuration files
- Ensure secure ownership, modes and attributes lighthouse binary (root:root 755 - chattr +i)
- Manage safe start/stop of the services

You can see the desired result configuration in secure_files.png

This script does not cover the firewall nor 2fa settings: do it yourself!

### Prerequisites / dependencies
As this script, my setup oriented towards uptime and security, hence:
- I run validator and beacon as different users without shell access
- Both services have proper SystemD entries to ensure optimal uptime
which happen to be some of the variables you are expexted to set in config.

To setup my node, I didn't follow one specific guide, but mixed the best practices of many.
- https://someresat.medium.com/guide-to-staking-on-ethereum-2-0-ubuntu-lighthouse-41de20513b12?sk=ac7477fd99b6648a5745a3e327f2701c
- https://www.coincashew.com/coins/overview-eth/guide-or-how-to-setup-a-validator-on-eth2-mainnet
- https://www.coincashew.com/coins/overview-eth/guide-or-security-best-practices-for-a-eth2-validator-beaconchain-node

### Files:
- lightsup.sh          ==> script
- config_prebuilt.txt  ==> configuration
- lightsuplog.txt      ==> log
- README.md            ==> this file
- secure_files.png     ==> example of secure configuration

### Usage: 
!!! Automatic modes won't be reliable until I find a decent API for scheduling downtime !!!
- ./lightsup.sh	- Calls main menu, speaks but doesn't log
- ./lightsup.sh 0 - Automatic mode - Doesn't speak, doesn't log (not recommended)
- ./lightsup.sh 1 - Automatic mode - Speaks, doesn't log.
- ./lightsup.sh 2 - Automatic mode - Doesn't speak, Logs (good for cron)
- ./lightsup.sh 3 - Automatic mode - Speaks and Logs

Backup and fallback functions have been implemented, not tested yet! 
Note that backing-up/falling back implies shutting down and restarting services.

### Todo:
- 1 Find an API that allows to know if the validator is scheduled to propose.
- 2 Manage fallback conditions... hard to say... manual so far

### Contributions:
If you would like to contribute to this project, you can either:
- Help enhance the code
- send some eth to 0xB1DcBDe40202b4d5BD352041126Ba6f29f7f4b77
