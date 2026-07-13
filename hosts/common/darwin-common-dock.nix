{ config, ... }:
{
    system.defaults.dock = {
        persistent-apps = [
            "/Applications/Safari.app"
            "/Applications/Google Chrome.app"
            "/Applications/Ghostty.app"
            "System/Applications/Messages.app"
            "System/Applications/Notes.app"
            "System/Applications/Reminders.app"
            "/Applications/Obsidian.app"
            "/Applications/Discord.app"
            "/System/Applications/Music.app"
            "/Applications/Visual Studio Code.app"
        ];
    };
}
