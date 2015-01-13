# nesspresso
Run credentialed authenticated Nessus scan / audit through web shell, bind shell or reverse shell

Sash @ Modux 2014
Run “credentialed” Nessus scans and audits through web, bind and reverse shells
Currently only for compromised *nix hosts

Usage: ./nesspresso type
  type: "web" or "bind" or "reverse"

This script sets up a local SSH login which Nessus connects to
The SSH commands are then forwarded through the users login shell to the remote shell on the compromised box

Works quick and easy with web and bind shells

For reverse shells you need to specify the port only

#---------#     #---------#     #--------#
#         #     #         #     # Web/   #
# Nessus  # --> # Local   # --> # Bind/  #
#         #     #  SSH    #     # Reverse#
#         #     #   Login #     # Shell  #
#---------#     #---------#     #--------#
