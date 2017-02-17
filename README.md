# SimpleMed

A simple medical web application. The end goal is to support basic features that samll
medical practices need. It is expected that there will be at most users in the low
hundreds. As a result it is being designed to run in the simplest environment I can think
of for it. A single process with a single thread doing IO/database concurrency using
promises on AnyEvent. Given the size of the data, I'm expecting to load everything into
main memory and have the footprint still sit in the couple hundred megabytes range.


Configuration File
------------------

The configuration system for this application is very simple. The config directory can
have one or more config files placed in it (by default only sample.yml is used). It
currently pulls the configuration file named after your user to use as configuration. In
the future, that will be the warned default, with another (more explicit) environment
variable used preferentially, and finally a command line option.

There is no configuration file overlay in this project. Those just lead to confusions in
the developers about what is the actual configuration running in the system. If overlay is
ever desired, a simple script can be put in front that will do the overlay when desired
without the confusing aspect of the overlay being done entirely in memory at startup.
