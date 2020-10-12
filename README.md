# XDFS - Distributed FS Client

## Installation
You need Ruby 2.5+ and Bundler 2+ installed to proceed.

```shell script
git clone https://github.com/totenhund/xdfs-client
cd xdfs-client
bundle install
```

## Usage

```shell script
ruby main.rb <username> <hub API address>
```

You then will be able to use an interactive shell.

* mkfs - reset filesystem (remove all contents, reclaim free space)
* cd <dir> - change current directory 
* ls - show contents of a current directory
* touch <file> - create empty file
* file <file> - display information about a file
* rm <file> - remove file
* rm-r <dir> - remove directory (if dir is not empty, use `rm-rf`)
* rm-rf <dir> - remove directory with all contents
* cp <from> <to> - copy file to another location (if need to overwrite destination, use `cp-f`)
* cp-f <from> <to> - copy file to another location (overwrite if exists)
* mv <from> <to> - move file to another location (if need to overwrite destination, use `mv-f`)
* mv-f <from> <to> - move file to another location (overwrite if exists)
* mkdir <dir> - create a directory
* xferdn <remote> <local> - copy a remote file to the local filesystem
* xferup <local> <remote> - copy a local file to the remote filesystem