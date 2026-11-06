# Sleep, wake and what is kept

## Billing

A running sandbox uses your plan's equivalent minutes. The status action shows
the runtime and the credits used so far, the same numbers as
`rzv sandboxes get <id>`. A sleeping sandbox has no compute charge.

## Sleep

Sleep runs `rzv sandboxes stop`. The Herdr server, every pane and every
process in the sandbox end.

## Wake

Wake runs `rzv sandboxes start`, refreshes the SSH alias and starts the
sandbox's Herdr server again, so the saved machine reconnects. Open new panes;
old ones do not come back.

Files in `/workspace` are kept across sleep and wake. Do not count on anything
else, such as your home directory, being kept. If Herdr is missing after a
wake, the plugin adds the machine again and Herdr offers to reinstall itself.

## Expiry

Every sandbox has a fixed lifetime (8 h by default) that cannot be extended.
At expiry it stops for good and everything in it is deleted, including
`/workspace`. Status shows the expiry time and the time left. Delete an
expired sandbox to remove its Herdr machine too.

## Delete

Delete asks you to type the sandbox name. It deletes the sandbox, then
removes its SSH config file and its Herdr machine. A wrong name deletes
nothing. If the delete fails, the machine stays, so you can retry.

## Reconnecting

Each SSH connection gets a short-lived certificate from `rzv`, so the machine
keeps working while your `rzv` sign-in is valid. If you see `! auth` in the
sidebar, run `rzv login`, then the attach action.
