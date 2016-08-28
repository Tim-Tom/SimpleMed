=SimpleMed

A simple medical web application. The end goal is to support basic features that samll
medical practices need. It is expected that there will be at most users in the low
hundreds. As a result it is being designed to run in the simplest environment I can think
of for it. A single process with a single thread doing IO/database concurrency using
promises on AnyEvent. Given the size of the data, I'm expecting to load everything into
main memory and have the footprint still sit in the couple hundred megabytes range.
