# updb (update backup)
Bash script interfacing [rsync](https://rsync.samba.org/) command line utility for maintaining a backup in a remote server.

## USAGE:
```bash
$ updb COMMAND [OPTIONS]
```
Available commands:
- init
- add
- forget
- push
- pull
- diff
- clean
- rename
- log
- restore

## Workflow
1. Move to the directory you want to backup
```bash
$ cd /path/to/dir/
```
2. Init will create a configuration file _.updb.conf_ needed for effectuate transactions and operations.
```bash
$ updb init
```
3. Add a backup destination (local path or remote address) and assign an alias to it using keyword *as*
```bash
$ updb add /path/to/local/dir as local_backup
$ updb add user@address:/path/to/remote/dir as remote_backup
```
4. List your destinations
```bash
$ updb list
```
To change the alias of a destination use the command *rename*
```bash
$ updb rename previous_alias new_alias
```
5. Synchronize your directory with backup destinations.
```bash
$ updb push
```
6. The diff command run a dry-run rsync instance to check differences between a backup and local repository. [More information](https://unix.stackexchange.com/questions/57305/rsync-compare-directories).
```bash
$ updb diff alias
```
7. To pull from a repository rather than push, you use the command *pull* passing the alias of the backup destination to use.
```bash
$ updb pull alias
```
8. All the changes and operations are registered in a log file, which can be displayed by running command *log*.
```bash
$ updb log
```
9. Command restore can undo last change to the configuration.
```bash
$ updb restore
```

### Deleting a backup destination
A destination can be forgot it (*updb* stops syncing to it) or, in addition, can be removed with option *clean*. The main difference between both commands is that *forget* will keep the files in the backup destination while *clean* will attempt to delete them if they are still accessible.
An alias for the destination has to be provided; more than one alias can be passed or the *all* reserved keyword may be passed in order to instruct **updb** to forget (or remove) all the destinations.
```bash
$ updb forget local_backup
$ updb forget all
$ updb remove remote_backup
```

As removing files can be a dangerous option, **updb** will ask user confirmation to execute this operation.
