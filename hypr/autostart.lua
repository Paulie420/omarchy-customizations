-- Extra autostart processes.
--
-- The startup sound used to be an `exec-once` in hyprland.conf. Quattro no
-- longer reads that file, so the sound was silently dead after the migration
-- until this was re-added here.

o.launch_on_start(os.getenv("HOME") .. "/.config/omarchy/bin/hypr-startup-sound.sh")
