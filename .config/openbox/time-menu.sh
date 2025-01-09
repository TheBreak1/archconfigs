#!/bin/sh
#
vartime=$(date +'%l:%M %p')

cat << EOFMENU
<openbox_pipe_menu>
  <item label="$vartime" />
</openbox_pipe_menu>
EOFMENU
