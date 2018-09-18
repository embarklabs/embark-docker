# macOS Bash v4 Upgrade Instructions
When using the `run_embark <cmd>` commands, you receive the error `ERROR: this script requires Bash version >= 4.0` on macOS, follow the steps below to upgrade bash to v4:
1. Install HomeBrew (if not already installed):
`ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"`
2. Update HomeBrew packet database and install bash:
`brew update && brew install bash`
3. Change your application to use the correct shell. For example, in Terminal, open Preferences, then change *Shells open with:* to `/usr/local/bin/bash`:
![Terminal preferences](https://i.imgur.com/vDWQfO7.png)
In iTerm2, change *Preferences > Profiles > (Select profile) > General > Command > Command* to `/usr/local/bin/bash`:
![iTerm2 preferences](https://i.imgur.com/zUZE663.png)
4. `bash --version` should show version 4+:
`$ bash --version`
`GNU bash, version 4.4.23(1)-release (x86_64-apple-darwin17.5.0)
Copyright (C) 2016 Free Software Foundation, Inc.
License GPLv3+: GNU GPL version 3 or later <http://gnu.org/licenses/gpl.html>`
5. There is a [guide to upgrading to bash 4 in macOS](http://clubmate.fi/upgrade-to-bash-4-in-mac-os-x/) if you need more help.