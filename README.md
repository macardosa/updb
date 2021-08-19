# upd
Bash script interfacing [rsync](https://rsync.samba.org/) command line utility for maintaining a backup in a remote server.

## USAGE:
```bash
$ upd COMMAND [OPTIONS]
```
Available commands:
- init
- add
- forget
- sync
- diff
- remove
- rename

## Workflow
1. Move to the directory you want to backup
```bash
$ cd /path/to/dir/
```
2. Init will create a configuration file _.upd.conf_ needed for effectuate transactions and operations.
```bash
$ upd init
```
3. Add a backup destination (local path or remote address) and assign an alias to it using keyword *as*
```bash
$ upd add /path/to/local/dir as local_backup
$ upd add user@address:/path/to/remote/dir as remote_backup
```
4. List your destinations
```bash
$ upd list
```
To change the alias of a destination use the command *rename*
```bash
$ upd rename previous_alias new_alias
```
5. Synchronize your directory with backup destinations.
```bash
$ upd sync
```
6. Alternatively do a dry-run to see differences. Only the pairs source/destination that show a difference will be listed. An empty output means no difference at all.
```bash
$ upd diff
```
### Deleting a backup destination
A destination can be forgot it (*upd* stops syncing to it) or, in addition, can be removed with option *remove*. The main difference between both commands is that *forget* will keep the files in the backup destination while *remove* will attempt to delete them if they are still accessible.
An alias for the destination has to be provided; more than one alias can be passed or the *all* reserved keyword may be passed in order to instruct **upd** to forget (or remove) all the destinations.
```bash
$ upd forget local_backup
$ upd forget all
$ upd remove remote_backup
```

As removing files can be a dangerous option, **upd** will ask user confirmation to execute this operation. This test can be skip it by passing --force option after *remove*, although it's not recommended to prevent unconciously data lost.
