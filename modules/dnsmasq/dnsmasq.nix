 {config, pkgs, ...}:
 let
   hostsPath = "https://raw.githubusercontent.com/StevenBlack/hosts/master/alternates/fakenews/hosts";
   hostsFile = builtins.fetchurl {
    url = hostsPath;
    sha256 = "1gz7q0wyijk4719z82iq0db8808jhigc463i5nlcjsyzsm7565pm";
   };

   clubcottonHosts = builtins.fetchGit ./clubcotton.list;
 in
 {


    config = {
      services.dnsmasq = {
          enable = true;
          settings.server = [ "1.1.1.1" "8.8.4.4" ];
          settings.domain-needed = true;
                      
          settings.bogus-priv = true;
          settings.no-resolv = true;
          settings.local-service = true;
            
          settings.listen-address = [ "::1"  "127.0.0.1" "192.168.5.220" ];
          settings.bind-interfaces = true;
            
          settings.cache-size = 10000;
          settings.log-queries = true;
          settings.log-facility = "/tmp/ad-block.log";
          settings.local-ttl = 300;

          #settings.conf-file = "/etc/nixos/assets/hosts-blocklists/domains.txt";
          settings.addn-hosts = [ hostsFile clubcottonHosts ];
         
      };
    };

  }