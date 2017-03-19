# Pulser

Pulser is a server and app that gives you the status of anything you wish directly to your phone.

For example, you could see the progress of a large download on your home server through the app, or if you have an internet connected doorbell (for some reason) you could see how many times it was pressed since you had left the house.

This is being made for my "Mobile and Web Technology" computer science module at university.

## Remake in Swift 3 (March 2017)

In the second semester of the MWT module at university, we were required to convert our app into Swift 3, incorporate Core Data, and use at least one Framework. Because of this, the data is persistent on the device and update deletions are also stored in Core Data until it has access to a network to update and delete the modules.

This was a challenge for such a simple app concept. The app has been rewritten from the ground up, and is *sooo* much more organised than before. Everything is separated into classes rather than a monolithic big function in a single file.

Modules have been renamed to "Updates", and are now stored in "Applications". Applications must be created on the web-based GUI before being updated by the applications themselves.

## I'll add screenshots soon. Check back at some point.
