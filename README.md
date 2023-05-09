## Watcher

A tool for observing / restarting http servers similar to nodemon for node. Automatically reloads the server when changes occur. It's lightweight and portable.

It works on a system level, so it's implementation / language agnostic, works with php, python, node, go, etc.

Can be use with local or remote servers, docker containers, etc.

### Installation

Put the binary executable or the shell script file in one of your profile's $PATH directories, e.g

```
~/bin
~/.local/bin

# or system wide

/bin
/usr/local/bin

...

```

You can also place it directly in your project, root folder preferably.

Rename it if you wish, watcher is pretty generic.

### Command line options

```
Usage:
  -e
    	Path to the entry file.
        REQUIRED
  -c
    	Command to run the server, be it "node", "go run", "python", "npm run".
        Must be quouted if contains more than 1 word.
        REQUIRED
  -p
        Http port the server is listening at
        REQUIRED
  -w
    	Files / directories to watch for changes:
        Entries should be included as whitespace separated quoted string.
        "one two three sub1/sub2"
        The entry file is included by default.
        Avoid scanning 3rd party module folders if you have no reason to do so.
        Include what actually may change.
        OPTIONAL
  -d
    	Delay in seconds between consecutive checks, default is 2.
        OPTIONAL
  -l
    	Path to error log file. It get's created if doesn't exist.
        OPTIONAL

```

### Runtime options

```
Usage:

  o
    	Prints available runtime options
  r
    	Restarts the server
  p
        Shows running processes ids
  c
    	Clears console output
  l
    	Shows the contents of the log file (if specified)
  t
    	Empties the log file (truncates to 0)
  u
        Shows usage, available command-line options
  q
        Terminates all processes and leaves

```

### Examples:

run from terminal

```bash

watcher -e path/to/js/index.js -c node -p 4000 -d 3 -w "./src/lib .src/utils"

watcher -e path/to/go/index.go -c "go run" -p 8080 -d 2 -l errors.log

```

e.g package.json

```json

"scripts" : {
    "dev" : "watcher -f index.js -p 4000 -c node -w 'src/lib src/utils'"
}

// run as npr run dev

```
