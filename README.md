# Animations Web Application
... serves the purpose of supporting students via providing animations that clarify lecture content.

## Getting Started
Follow the Angular Dart instructions [here](https://webdev.dartlang.org/angular/) to install the Dart SDK, etc. Then just clone the repository and call `pub get` (or `pub upgrade`) followed by `pub run build_runner serve` to start the application.

### Debugging (JetBrains IDE)
- Launch the debugging server with `pub run build_runner serve`
- Set up a launch configuration of type `JavaScript Debug` and set the URL to `http://localhost:8080`, set the Browser to Chrome
- Launch the launch configuration in debug mode

## Build the Application
Once you set up your environment (See Getting started), you can call `pub run build_runner build --release --output build` in your working directory. You'll find the result in the `build/web` folder. If you want to deploy the application you just need to adjust the built index.html: Change the `<base href="/">` to your base url so that navigation within the angular app is working correctly.

## Continous Deployment
All branches get automatically built & deployed [here](https://www.sam.cs.hm.edu).