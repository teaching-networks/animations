import "dart:html";
import 'dart:math';
import "package:angular/angular.dart";
import "package:netzwerke_animationen/src/canvas/animation/canvas_animation.dart";
import 'package:netzwerke_animationen/src/canvas/canvas_component.dart';

@Component(
  selector: "dummy-animation",
  templateUrl: "dummy_animation.html",
  directives: const [CanvasComponent]
)
class DummyAnimation extends CanvasAnimation {

  ImageElement earth = new ImageElement(src: "https://mdn.mozillademos.org/files/1429/Canvas_earth.png");
  ImageElement moon = new ImageElement(src: "https://mdn.mozillademos.org/files/1443/Canvas_moon.png");
  ImageElement sun = new ImageElement(src: "https://mdn.mozillademos.org/files/1456/Canvas_sun.png");

  @override
  void render(num timestamp) {
    context.globalCompositeOperation = "destination-over";
    context.clearRect(0, 0, size.width, size.height); // clear canvas

    context.fillStyle = "rgba(0, 0, 0, 0.4)";
    context.strokeStyle = "rgba(0, 153, 255, 0.4)";
    context.save();
    context.translate(size.width / 2, size.height / 2);

    double seconds = timestamp / 1000;

    // Earth
    context.rotate(((2 * PI) / 60) * seconds + ((2 * PI) / 60000) * timestamp);
    context.translate(105, 0);
    context.fillRect(0, -12, 50, 24); // Shadow
    context.drawImage(earth, -12, -12);

    // Moon
    context.save();
    context.rotate(((2 * PI) / 6) * seconds + ((2 * PI) / 6000) * timestamp);
    context.translate(0, 28.5);
    context.drawImage(moon, -3.5, -3.5);
    context.restore();

    context.restore();

    context.beginPath();
    context.arc(size.width / 2, size.height / 2, 105, 0, PI * 2, false); // Earth orbit
    context.stroke();

    context.drawImageScaled(sun, 0, 0, size.width, size.height);
  }

}