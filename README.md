US Airport dictionary for macOS

Provides dictionary entries and a Right Click -> Look Up panel for US Airports based on their FAA or IACO identifiers. 
Great for online forums or classifies where someone wants to meet at FFX but you haven't quite memorized all 20,239 airport codes.

To install:
===========

1. Open Dictionary.app
2. Choose File -> Open Dictionaries Folder
3. Drag in Airports.Dictionary
4. Choose Dictionary -> Preferences
5. Check "Airports" in the list. You may need to quit and relaunch Dictionary.app for Airports to show display.
6. Optionally, drag Airports to the top of the list. This helps airport identifiers show when using "Look Up" outside of Dictionary.app.a

Building from Source
==========

Prerequisites
-------------

- Building the dictionary requires a recent `ruby`. Consider `brew install ruby` or using RVM.
- Dependencies are installed using `bundle install`

Building
--------

`generate.rb` will read Aiports.geojson (downloaded from the FAA website) and produce
a new `Airports.xml`. This is the dictionary information. It gets compiled and bundled
using `make` and put into the dictionaries folder with `make install`.

As a one liner:
   
   ./generate.rb > Airports.xml && make && make install
   
Sometimes the lookup view service needs to be restarted to load new dictionary material:

    killall -INT LookupViewService