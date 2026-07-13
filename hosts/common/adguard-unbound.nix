{ ... }:
{
  # Recursive resolver behind AdGuard Home. Listens on localhost only, on a
  # non-standard port since AdGuard Home needs :53 on the LAN-facing
  # interface. `resolveLocalQueries` is off so this host's own DNS
  # resolution doesn't depend on AdGuard Home's DNS service already being
  # configured (chicken-and-egg on first boot, before the setup wizard runs).
  services.unbound = {
    enable = true;
    resolveLocalQueries = false;
    settings.server = {
      interface = [ "127.0.0.1" ];
      port = 5335;
      access-control = [ "127.0.0.1/8 allow" ];
    };
  };

  # AdGuard Home is the LAN-facing DNS server (ad/tracker blocking) and web
  # admin UI. `settings` here is a declarative baseline shared by every host
  # that imports this module (hugin, munin) - extracted from hugin's live
  # config after it went through the manual setup wizard once.
  #
  # `mutableSettings` (module default, spelled out here because the whole
  # design leans on it) merges these into each host's own on-disk config on
  # every start rather than replacing it outright - so the admin account
  # (created per-host via the web UI, bcrypt hash included) stays out of
  # git entirely, while DNS/filtering/rewrites stay declared and identical
  # across hosts. `users` is deliberately not set here for that reason - the
  # first-run web UI wizard still needs to run once per host to create it
  # (see each host's Setup.md).
  #
  # `http.*` (pprof/doh/session_ttl/etc.) is deliberately omitted: the
  # adguardhome module always overwrites the whole `http` key with
  # `{ address = "<host>:<port>"; }` derived from the options below (a
  # shallow `//` merge, so anything else nested under `http` here would
  # just get clobbered at build time anyway) - so those bits are left as
  # whatever's already live/mutable instead.
  services.adguardhome = {
    enable = true;
    openFirewall = true;
    port = 80;

    settings = {
      auth_attempts = 5;
      block_auth_min = 15;
      http_proxy = "";
      language = "";
      theme = "auto";

      dns = {
        bind_hosts = [ "0.0.0.0" ];
        port = 53;
        anonymize_client_ip = false;
        ratelimit = 20;
        ratelimit_subnet_len_ipv4 = 24;
        ratelimit_subnet_len_ipv6 = 56;
        ratelimit_whitelist = [ ];
        refuse_any = true;
        upstream_dns = [ "127.0.0.1:5335" ];
        upstream_dns_file = "";
        bootstrap_dns = [
          "9.9.9.10"
          "149.112.112.10"
          "2620:fe::10"
          "2620:fe::fe:10"
        ];
        fallback_dns = [ "1.1.1.1" "9.9.9.9" ];
        upstream_mode = "load_balance";
        fastest_timeout = "1s";
        allowed_clients = [ ];
        disallowed_clients = [ ];
        blocked_hosts = [ "version.bind" "id.server" "hostname.bind" ];
        trusted_proxies = [ "127.0.0.0/8" "::1/128" "10.1.50.4/24" ];
        cache_enabled = true;
        cache_size = 4194304;
        cache_ttl_min = 0;
        cache_ttl_max = 0;
        cache_optimistic = false;
        cache_optimistic_answer_ttl = "30s";
        cache_optimistic_max_age = "12h";
        bogus_nxdomain = [ ];
        aaaa_disabled = false;
        enable_dnssec = true;
        edns_client_subnet = {
          custom_ip = "";
          enabled = false;
          use_custom = false;
        };
        max_goroutines = 300;
        handle_ddr = true;
        ipset = [ ];
        ipset_file = "";
        bootstrap_prefer_ipv6 = false;
        upstream_timeout = "10s";
        private_networks = [ ];
        use_private_ptr_resolvers = true;
        local_ptr_upstreams = [ ];
        use_dns64 = false;
        dns64_prefixes = [ ];
        serve_http3 = false;
        use_http3_upstreams = false;
        serve_plain_dns = true;
        hostsfile_enabled = true;
        pending_requests = {
          enabled = true;
        };
      };

      tls = {
        enabled = false;
        server_name = "";
        force_https = false;
        port_https = 443;
        port_dns_over_tls = 853;
        port_dns_over_quic = 853;
        port_dnscrypt = 0;
        dnscrypt_config_file = "";
        certificate_chain = "";
        private_key = "";
        certificate_path = "";
        private_key_path = "";
        strict_sni_check = false;
      };

      querylog = {
        dir_path = "";
        ignored = [ ];
        interval = "90d";
        size_memory = 1000;
        enabled = true;
        ignored_enabled = false;
        file_enabled = true;
      };

      statistics = {
        dir_path = "";
        ignored = [ ];
        interval = "1d";
        enabled = true;
        ignored_enabled = false;
      };

      # Shared LAN-wide blocklists - same for every resolver on the network.
      filters = [
        {
          enabled = true;
          url = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_1.txt";
          name = "AdGuard DNS filter";
          id = 1;
        }
        {
          enabled = false;
          url = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_2.txt";
          name = "AdAway Default Blocklist";
          id = 2;
        }
      ];
      whitelist_filters = [ ];
      user_rules = [ ];

      dhcp = {
        enabled = false;
        interface_name = "";
        local_domain_name = "lan";
        dhcpv4 = {
          gateway_ip = "";
          subnet_mask = "";
          range_start = "";
          range_end = "";
          lease_duration = 86400;
          icmp_timeout_msec = 1000;
          options = [ ];
        };
        dhcpv6 = {
          range_start = "";
          lease_duration = 86400;
          ra_slaac_only = false;
          ra_allow_slaac = false;
        };
      };

      filtering = {
        blocking_ipv4 = "";
        blocking_ipv6 = "";
        blocked_services = {
          schedule = {
            time_zone = "UTC";
          };
          ids = [ ];
        };
        protection_disabled_until = null;
        safe_search = {
          enabled = false;
          bing = true;
          duckduckgo = true;
          ecosia = true;
          google = true;
          pixabay = true;
          yandex = true;
          youtube = true;
        };
        blocking_mode = "default";
        parental_block_host = "family-block.dns.adguard.com";
        safebrowsing_block_host = "standard-block.dns.adguard.com";

        # Split-horizon/short-name LAN records - shared so every resolver on
        # the network answers these the same way. See hugin/Setup.md for the
        # rationale behind the rdk.erixen.info entries specifically.
        rewrites = [
          { domain = "citadel"; answer = "10.1.50.10"; enabled = true; }
          { domain = "erixen-ha"; answer = "10.1.107.6"; enabled = true; }
          { domain = "erixen-nuc-pve"; answer = "10.1.1.14"; enabled = true; }
          { domain = "proxy"; answer = "10.1.50.4"; enabled = true; }
          { domain = "hugin"; answer = "10.1.50.11"; enabled = true; }
          { domain = "munin"; answer = "10.1.50.12"; enabled = true; }
          { domain = "unifi.local"; answer = "10.1.1.6"; enabled = true; }
          { domain = "homeassistant.rdk.erixen.info"; answer = "10.1.50.4"; enabled = true; }
          { domain = "citadel.rdk.erixen.info"; answer = "10.1.50.10"; enabled = true; }
          { domain = "proxmox.rdk.erixen.info"; answer = "10.1.50.4"; enabled = true; }
          # AGH's rewrite-priority sort treats a hostname answer as a CNAME
          # rewrite, and (despite the doc comment claiming otherwise) always
          # ranks CNAME entries above plain A/AAAA ones regardless of
          # exact-vs-wildcard - so a hostname answer here would shadow the
          # exact-match entries above instead of losing to them. Pointing
          # straight at citadel's IP keeps this an A rewrite so the normal
          # exact-beats-wildcard ordering applies.
          { domain = "*.rdk.erixen.info"; answer = "10.1.50.10"; enabled = true; }
        ];

        safe_fs_patterns = [ "/var/lib/private/AdGuardHome/userfilters/*" ];
        safebrowsing_cache_size = 1048576;
        safesearch_cache_size = 1048576;
        parental_cache_size = 1048576;
        cache_time = 30;
        filters_update_interval = 24;
        blocked_response_ttl = 10;
        filtering_enabled = true;
        rewrites_enabled = true;
        parental_enabled = false;
        safebrowsing_enabled = false;
        protection_enabled = true;
      };

      clients = {
        runtime_sources = {
          whois = true;
          arp = true;
          rdns = true;
          dhcp = true;
          hosts = true;
        };
        persistent = [ ];
      };

      log = {
        enabled = true;
        file = "";
        max_backups = 0;
        max_size = 100;
        max_age = 3;
        compress = false;
        local_time = false;
        verbose = false;
      };

      os = {
        group = "";
        user = "";
        rlimit_nofile = 0;
      };
    };
  };

  networking.firewall = {
    # 3000 is AdGuard Home's install/setup-wizard port, used to create the
    # per-host admin account (see each host's Setup.md) - safe to remove
    # once that's done on a given host, since normal traffic goes through
    # `services.adguardhome.port` (already opened via `openFirewall` above).
    allowedTCPPorts = [ 53 3000 ];
    allowedUDPPorts = [ 53 ];
  };
}
