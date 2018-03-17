# Networks Animations

... is a web app that serves the purpose of supporting students via animations that show certain networking topics.

## Technology

### Framework

The web app uses Googles Angular with Dart ([See here](https://webdev.dartlang.org/angular/)). To build and develop the app you will need the Dart SDK. Just check by the afore mentioned site and get started!

### Animations

All animations (of which there are none at the moment), shall be realized with (HTML5) [Canvas](https://www.w3schools.com/html/html5_canvas.asp) which is the only way to **directly** draw in a web browser. This offers the maximum performance one might get when dealing with web technology (For example compared with the browsers DOM which would also have been an alternative). Further more we are not limited in our creativity.

## Getting Started

Follow the Angular Dart instructions [here](https://webdev.dartlang.org/angular/) to install the Dart SDK, etc. Then just clone the repository and call `pub get` followed by `pub serve` to start the application.

Note that momentarily I am facing issues with pub serve which gives me an Error:
```
'package:sass_builder/sass_builder.dart': malformed type: line 28 pos 20: cannot resolve class 'Logger' from 'SassBuilder'final _log = new Logger('sass_builder');
```
It has already been asked on Stackoverflow [see here](https://stackoverflow.com/questions/49334361/dart-sassbuilder-cannot-find-logger) and a solution has been proposed which worked for me (But is of course temporarily while the issue persists).

## Building Pipeline and Continous Integration

At the moment the application is in early state so there is no real content at the moment and the app will rarely have content yet. Once the application is reaching a state which we could consider "usable" the building pipeline will be established.