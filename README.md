A tool for managing / restarting http servers

It works like nodemon for nodejs, but works with any type of servers: nodejs, php, go, python, etc.

Usage

Put the binary executable or the shell file:

in one of your profile's $PATH directories, e.g

~/bin
~/.local/bin

in a system wide $PATH directory if you have permissions, e.g

/bin

or at the root of your project

Required flags

-f

Path to the entry file, absolute or relative

-c

Command to run the server, be it "npm run", "node", "go run", "py", etc. Must be enclosed in double quotes.

-p

Port the server is listening to, e.g. 8080, 4000, etc.

Optional flags

-d

Delay time in seconds between consecutive checks

Runtime options

-r restarts the server

-q quits watcher and shuts the server down

-h prints help

Examples:

run from terminal

```bash

watcher -f path/to/js/index.js -c "npm run" -p 4000 -d 3

watcher -f path/to/go/index.go -c "go run" -p 8080 -d 2

```

run from your project's config, e.g package.json

```json

"scripts" : {
    "dev" : "watcher -f index.js -p 4000 -c \"node\""

}




```
