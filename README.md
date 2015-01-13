nesspresso Nessus Scan SSH Proxy
===============================

License
-------
Run credentialed authenticated Nessus scan / audit through web shell, bind shell or reverse shell


Description
-----------

Perform authenticated Nessus compliance checks, scans and patch audits of compromised hosts without credentials.

This tool proxies the Nessus SSH connection through to your web, bind or reverse shells.

Usage
-----

Currently only for compromised *nix hosts

Usage: ./nesspresso type
  
  type: "web" or "bind" or "reverse"

This script sets up a local SSH login which Nessus connects to

The SSH commands are then forwarded through the users login shell to the remote shell on the compromised box

Works quick and easy with web and bind shells

For reverse shells you need to specify the port only




Author
------

Sash (@secdefect) from Modux Digital Security

Copyright
---------

&copy; 2014 Modux Digital Security
