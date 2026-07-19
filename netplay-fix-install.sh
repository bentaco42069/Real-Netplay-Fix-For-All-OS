#!/bin/bash
# ============================================================================
#   NETPLAY-FOR-EVERYONE  —  one-shot netplay fix for retro handheld OSes
# ----------------------------------------------------------------------------
#   Kills the two netplay bugs that plague ArkOS, DarkOS and ROCKNIX:
#     * "this game isn't compatible with netplay"  (feature switched OFF)
#     * "my friend on the SAME WiFi can't join my host"  (routed to the
#        internet lobby / relay instead of straight across your router)
#
#   Run it once, on the handheld, as root. It backs up your config first,
#   flips the right switches, and gets out of the way. Your games are never
#   touched. It's safe to run twice.
#
#   Free. No strings. Because the strong are meant to lift everyone up.
#
#         by  Bentaco   .   7-29-15   .   6-15-18
#         built with Claudius Maximus (Claude)
# ============================================================================
set -u

ROOT="${NETPLAY_FIX_ROOT:-}"        # test hook; empty = the real system ("/")
say(){ printf '%s\n' "$*"; }
hr(){  say "------------------------------------------------------------"; }

backup(){                           # $1 = file to back up
  [ -f "$1" ] || return 0
  local b="$1.bak.netplayfix.$(date +%Y%m%d%H%M%S)"
  cp -f "$1" "$b" && say "  backed up  ->  ${b#$ROOT}"
}

set_sys(){                          # batocera/rocknix system.cfg:  key=value
  local f="$1" k="$2" v="$3"
  [ -f "$f" ] || return 0
  if grep -q "^${k}=" "$f"; then sed -i "s|^${k}=.*|${k}=${v}|" "$f"
  else printf '%s=%s\n' "$k" "$v" >> "$f"; fi
  say "  ${k}=${v}"
}

set_ra(){                           # RetroArch retroarch.cfg:  key = "value"
  local f="$1" k="$2" v="$3"
  [ -f "$f" ] || return 0
  if grep -q "^${k} = " "$f"; then sed -i "s|^${k} = .*|${k} = \"${v}\"|" "$f"
  else printf '%s = "%s"\n' "$k" "$v" >> "$f"; fi
  say "  ${k} = \"${v}\""
}

fix_retroarch(){                    # $1 = a retroarch.cfg -> LAN direct-connect
  local f="$1"
  [ -f "$f" ] || return 0
  hr; say "RetroArch config:  ${f#$ROOT}"
  backup "$f"
  set_ra "$f" content_show_netplay    true    # show the netplay menu
  set_ra "$f" netplay_public_announce false   # don't advertise to the internet
  set_ra "$f" netplay_nat_traversal   false   # don't punch out to the internet
  set_ra "$f" netplay_use_mitm_server false   # no relay server middleman
  set_ra "$f" netplay_ip_port         55435   # standard direct port
}

changed=0

# ---- ROCKNIX / JELOS family (the master switch was OFF) --------------------
SYS="$ROOT/storage/.config/system/configs/system.cfg"
if [ -f "$SYS" ]; then
  hr; say "Detected:  ROCKNIX / JELOS"
  say "System settings:  ${SYS#$ROOT}"
  backup "$SYS"
  set_sys "$SYS" global.netplay 1                     # <-- the big one: ON
  if ! grep -qE "^global.netplay.nickname=.+" "$SYS"; then
    set_sys "$SYS" global.netplay.nickname Player
  fi
  set_sys "$SYS" global.netplay.port  55435
  set_sys "$SYS" global.netplay.relay none            # LAN, no relay
  fix_retroarch "$ROOT/storage/.config/retroarch/retroarch.cfg"
  changed=1
fi

# ---- ArkOS / DarkOS family (netplay ON, but misrouted to the internet) -----
for RA in \
  "$ROOT/home/ark/.config/retroarch/retroarch.cfg" \
  "$ROOT/home/ark/.config/retroarch32/retroarch.cfg"
do
  if [ -f "$RA" ]; then
    [ "$changed" = 0 ] && { hr; say "Detected:  ArkOS / DarkOS"; }
    fix_retroarch "$RA"
    changed=1
  fi
done

hr
if [ "$changed" = 0 ]; then
  say "Couldn't find a supported netplay config."
  say "Run this ON the handheld (ArkOS / DarkOS / ROCKNIX), as root."
  exit 1
fi

cat <<'DONE'

  ===========================================================
   NETPLAY IS FIXED.  How to play a friend on the SAME WiFi:

     1) HOST   : open a game -> Netplay -> Start / Host.
     2) HOST   : note your local IP (Network settings, 192.168.x.x).
     3) FRIEND : open the SAME game + SAME core ->
                 Netplay -> Connect to Netplay Host ->
                 type the host's 192.168.x.x -> join.

   Same game, same core, same WiFi = you're in.
   No lobby, no relay, no internet required.

   Fixed for you, free.
      Bentaco  .  7-29-15  .  6-15-18   |   built with Claudius Maximus
  ===========================================================
DONE
