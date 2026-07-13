{ self, inputs, outputs, config, lib, hostname, system, username, pkgs, unstablePkgs, ... }:
let
    inherit (inputs) nixpkgs nixpkgs-unstable home-manager;
in
{
    nixpkgs = {
        config.allowUnfree = true;
        hostPlatform = "aarch64-darwin";
    };

    system.primaryUser = "jerixen";
    users.users.jerixen.home = "/Users/jerixen";
    system.stateVersion = 6;

    # The platform the configuration will be used on.

    # Necessary for using flakes on this system.
    nix.settings.experimental-features = "nix-command flakes";

    environment.systemPackages = with pkgs; [
        pkgs.bat
        pkgs.eza
        pkgs.helix
        pkgs.ripgrep
        pkgs.uv
        pkgs.vim
        pkgs.zoxide
        pkgs.fzf
        pkgs.yazi
        pkgs._7zz
        pkgs.gping
    ];

    fonts.packages = [
        pkgs.nerd-fonts.fira-code
        pkgs.nerd-fonts.fira-mono
        pkgs.nerd-fonts.hack
        pkgs.nerd-fonts.jetbrains-mono
    ];

    programs.direnv = {
        enable = true;
        nix-direnv.enable = true;
    };

    programs.nix-index.enable = true;

    programs.zsh = {
        enable = true;
        enableCompletion = true;
        promptInit = builtins.readFile ./../../dotfiles/mac-dot-zshrc;
    };

    homebrew = {
        enable = true;
        onActivation = {
            cleanup = "zap";
            autoUpdate = true;
            # Keep activation mostly automatic, but avoid MAS update/auth failures on
            # every switch. Keep masApps as inventory, but install them interactively.
            upgrade = false;
            #extraEnv.HOMEBREW_BUNDLE_MAS_SKIP =
            #  lib.concatStringsSep " " (map toString (builtins.attrValues config.homebrew.masApps));
        };
        brews=[
            "mas"
            "zsh-autosuggestions"
            "starship"
        ];
        casks = [
            "bambu-studio"
            "claude"
            "claude-code"
            "discord"
            "ghostty"
            "google-chrome"
            "logi-options+"
            "istat-menus"
            "nextcloud"
            "obsidian"
            #"slack"
            "steam"
            #"wireshark"
            "visual-studio-code"
            "vlc"
        ];
        masApps = {
            "Bitwarden" = 1352778147;
            "Tailscale" = 1475387142;
            "Keynote" = 361285480;
            "Numbers" = 361304891;
            "Pages" = 361309726;
            "iPrint&Scan" = 1193539993;
            "P-touch Editor" = 1453365242;
            "Taurine" = 960276676;
        };
    };

    # Add ability to used TouchID for sudo authentication
    security.pam.services.sudo_local.touchIdAuth = true;

    # macOS configuration
    system.defaults = {
        NSGlobalDomain.AppleShowAllExtensions = true;
        NSGlobalDomain.AppleShowScrollBars = "Always";
        NSGlobalDomain.AppleICUForce24HourTime = true;
        NSGlobalDomain.NSUseAnimatedFocusRing = false;
        NSGlobalDomain.NSNavPanelExpandedStateForSaveMode = true;
        NSGlobalDomain.NSNavPanelExpandedStateForSaveMode2 = true;
        NSGlobalDomain.PMPrintingExpandedStateForPrint = true;
        NSGlobalDomain.PMPrintingExpandedStateForPrint2 = true;
        NSGlobalDomain.NSDocumentSaveNewDocumentsToCloud = false;
        NSGlobalDomain.ApplePressAndHoldEnabled = false;
        NSGlobalDomain.InitialKeyRepeat = 25;
        NSGlobalDomain.KeyRepeat = 2;
        NSGlobalDomain."com.apple.mouse.tapBehavior" = 1;
        NSGlobalDomain.NSWindowShouldDragOnGesture = true;
        NSGlobalDomain.NSAutomaticSpellingCorrectionEnabled = false;
        LaunchServices.LSQuarantine = false; # disables "Are you sure?" for new apps
        loginwindow.GuestEnabled = false;
        finder.FXPreferredViewStyle = "Nlsv";
        menuExtraClock = {
        Show24Hour = true;
        ShowAMPM = false;
        };
    };

    system.defaults.CustomUserPreferences = {
        "com.apple.finder" = {
            ShowExternalHardDrivesOnDesktop = true;
            ShowHardDrivesOnDesktop = false;
            ShowMountedServersOnDesktop = false;
            ShowRemovableMediaOnDesktop = true;
            _FXSortFoldersFirst = true;
            # When performing a search, search the current folder by default
            FXDefaultSearchScope = "SCcf";
            DisableAllAnimations = true;
            NewWindowTarget = "PfDe";
            NewWindowTargetPath = "file://$\{HOME\}/Desktop/";
            AppleShowAllExtensions = true;
            FXEnableExtensionChangeWarning = false;
            ShowStatusBar = true;
            ShowPathbar = true;
            WarnOnEmptyTrash = false;
        };
        "com.apple.desktopservices" = {
            # Avoid creating .DS_Store files on network or USB volumes
            DSDontWriteNetworkStores = true;
            DSDontWriteUSBStores = true;
        };
        "com.apple.dock" = {
            autohide = true;
            launchanim = false;
            static-only = false;
            show-recents = false;
            show-process-indicators = true;
            orientation = "bottom";
            tilesize = 36;
            minimize-to-application = true;
            mineffect = "scale";
            enable-window-tool = false;
        };
        "com.apple.ActivityMonitor" = {
            OpenMainWindow = true;
            IconType = 5;
            SortColumn = "CPUUsage";
            SortDirection = 0;
        };
        # "com.apple.Safari" = {
        #     # Privacy: don’t send search queries to Apple
        #     UniversalSearchEnabled = false;
        #     SuppressSearchSuggestions = true;
        # };
        "com.apple.AdLib" = {
            allowApplePersonalizedAdvertising = false;
        };
        "com.apple.SoftwareUpdate" = {
            AutomaticCheckEnabled = true;
            # Check for software updates daily, not just once per week
            ScheduleFrequency = 1;
            # Download newly available updates in background
            AutomaticDownload = 1;
            # Install System data files & security updates
            CriticalUpdateInstall = 1;
        };
        "com.apple.TimeMachine".DoNotOfferNewDisksForBackup = true;
        # Prevent Photos from opening automatically when devices are plugged in
        "com.apple.ImageCapture".disableHotPlug = true;
        # Turn on app auto-update
        "com.apple.commerce".AutoUpdate = true;
        "com.googlecode.iterm2".PromptOnQuit = false;
        "com.google.Chrome" = {
            AppleEnableSwipeNavigateWithScrolls = true;
            DisablePrintPreview = true;
            PMPrintingExpandedStateForPrint2 = true;
        };
    };

}
