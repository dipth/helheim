/**
 * April Fools' Fly — a prank module that renders a realistic fly
 * walking around the viewport on April 1st.
 *
 * The fly only appears on a random subset of page views and
 * behaves differently every time: random spawn position, random
 * movement patterns, random pause durations, and occasional
 * direction reversals to look convincingly organic.
 *
 * Force-enable for testing by adding `?fly=<count>` to the URL
 * (e.g. `?fly=1` for one fly, `?fly=10` for ten).
 *
 * @example
 *   import { AprilFoolsFly } from "./april_fools_fly";
 *   AprilFoolsFly.run(); // no-op outside April 1st (unless forced)
 */

const APPEARANCE_PROBABILITY = 0.3;

const MIN_STEP_PX = 1;
const MAX_STEP_PX = 3;
const MIN_PAUSE_MS = 400;
const MAX_PAUSE_MS = 3000;
const MIN_WALK_STEPS = 15;
const MAX_WALK_STEPS = 80;
const FRAME_INTERVAL_MS = 30;
const DIRECTION_WOBBLE_DEG = 25;
const MAX_TURN_RATE_DEG = 8;
const FLY_SIZE_PX = 9;
const EDGE_MARGIN_PX = 10;
const MOUSE_FLEE_RADIUS_PX = 120;
const FLEE_INITIAL_SPEED_PX = 24;
const FLEE_ACCELERATION = 1.15;
const FLEE_WOBBLE_DEG = 12;

/**
 * Reads the `fly` query parameter. Returns the raw string value,
 * or `null` when absent.
 *
 * @returns {string|null}
 */
function flyParam() {
  return new URLSearchParams(window.location.search).get('fly');
}

/**
 * Returns the forced fly count when the `fly` query parameter is a
 * positive integer, or `0` when the parameter is absent / not a
 * number.  Any truthy value (e.g. `?fly=1`) also forces the feature
 * on; the returned number is the exact count to spawn.
 *
 * @returns {number} Forced count (0 = not forced).
 *
 * @example
 *   // ?fly=5  → 5
 *   // ?fly=1  → 1
 *   // (none)  → 0
 */
function forcedCount() {
  var raw = flyParam();
  if (raw === null) return 0;
  var n = parseInt(raw, 10);
  return (isNaN(n) || n < 1) ? 0 : n;
}

/**
 * Returns true when the fly feature should activate — either it is
 * April 1st (in the user's local timezone) or the `fly` query
 * parameter is present.
 *
 * @returns {boolean}
 */
function isActive() {
  if (flyParam() !== null) {
    return true;
  }
  var now = new Date();
  return now.getMonth() === 3 && now.getDate() === 1;
}

/**
 * Determines how many flies to spawn.  When forced via query string
 * the exact number is used.  Otherwise a weighted random roll:
 *
 *   80% → 1 fly
 *   10% → 3 flies
 *    9% → 10 flies
 *    1% → 100 flies
 *
 * @returns {number}
 */
function rollFlyCount() {
  var forced = forcedCount();
  if (forced > 0) return forced;

  var roll = Math.random();
  if (roll < 0.80) return 1;
  if (roll < 0.90) return 3;
  if (roll < 0.99) return 10;
  return 100;
}

/**
 * Returns a random float between `min` (inclusive) and `max` (exclusive).
 *
 * @param {number} min - Lower bound.
 * @param {number} max - Upper bound.
 * @returns {number}
 *
 * @example
 *   rand(0, 10) // => 4.37…
 */
function rand(min, max) {
  return Math.random() * (max - min) + min;
}

/**
 * Returns a random integer between `min` and `max` (both inclusive).
 *
 * @param {number} min - Lower bound.
 * @param {number} max - Upper bound.
 * @returns {number}
 *
 * @example
 *   randInt(1, 6) // => 4
 */
function randInt(min, max) {
  return Math.floor(rand(min, max + 1));
}

/**
 * Clamps `value` so it stays within `[min, max]`.
 *
 * @param {number} value
 * @param {number} min
 * @param {number} max
 * @returns {number}
 */
function clamp(value, min, max) {
  return Math.max(min, Math.min(max, value));
}

/**
 * Normalizes an angle to the range [-180, 180).
 *
 * @param {number} deg - Angle in degrees, possibly outside [-180, 180).
 * @returns {number} Equivalent angle within [-180, 180).
 *
 * @example
 *   normalizeAngle(370)  // => 10
 *   normalizeAngle(-200) // => 160
 */
function normalizeAngle(deg) {
  deg = deg % 360;
  if (deg > 180) deg -= 360;
  if (deg <= -180) deg += 360;
  return deg;
}

/**
 * Returns the shortest signed angular distance from angle `a` to
 * angle `b`, taking wrapping into account.  Positive = counter-clockwise
 * in screen-space (increasing degrees), negative = clockwise.
 *
 * @param {number} a - Start angle in degrees.
 * @param {number} b - Target angle in degrees.
 * @returns {number} Signed distance in degrees within (-180, 180].
 *
 * @example
 *   shortestAngularDistance(10, 350) // => -20
 *   shortestAngularDistance(350, 10) // => 20
 */
function shortestAngularDistance(a, b) {
  return normalizeAngle(b - a);
}

/**
 * Builds the fly's DOM element and injects the required inline styles
 * so the module stays self-contained (no external CSS dependency).
 *
 * The fly is an absolutely-positioned container with three child
 * elements: a body oval and two semi-transparent wing ovals.
 *
 * @returns {HTMLElement} The fly wrapper element, ready to be appended
 *   to the document body.
 */
function createFlyElement() {
  var wrapper = document.createElement('div');
  wrapper.setAttribute('id', 'april-fools-fly');
  wrapper.setAttribute('aria-hidden', 'true');
  wrapper.style.cssText = [
    'position:fixed',
    'z-index:999999',
    'width:' + FLY_SIZE_PX + 'px',
    'height:' + FLY_SIZE_PX + 'px',
    'pointer-events:none',
    'transition:none',
    'will-change:transform'
  ].join(';');

  var body = document.createElement('div');
  body.style.cssText = [
    'position:absolute',
    'top:25%',
    'left:20%',
    'width:60%',
    'height:50%',
    'background:#1a1a1a',
    'border-radius:50%'
  ].join(';');

  var leftWing = document.createElement('div');
  leftWing.className = 'af-fly-wing af-fly-wing-l';
  leftWing.style.cssText = [
    'position:absolute',
    'top:5%',
    'left:0',
    'width:45%',
    'height:55%',
    'background:rgba(180,180,180,0.35)',
    'border-radius:50%',
    'transform:rotate(-15deg)'
  ].join(';');

  var rightWing = document.createElement('div');
  rightWing.className = 'af-fly-wing af-fly-wing-r';
  rightWing.style.cssText = [
    'position:absolute',
    'top:5%',
    'right:0',
    'width:45%',
    'height:55%',
    'background:rgba(180,180,180,0.35)',
    'border-radius:50%',
    'transform:rotate(15deg)'
  ].join(';');

  wrapper.appendChild(leftWing);
  wrapper.appendChild(rightWing);
  wrapper.appendChild(body);
  return wrapper;
}

/**
 * Core fly simulation.  Call `start()` to spawn the fly; it manages
 * its own animation loop and cleans up when the tab is hidden.
 *
 * Behaviour phases (chosen randomly in a loop):
 *   1. **Walk** — move in small steps with slight directional wobble.
 *   2. **Pause** — sit still for a short random duration (the "leg rub"
 *      idle animation is done via CSS on the wings).
 *   3. **Turn** — pick a brand-new heading before the next walk.
 *
 * Additionally the fly will:
 *   - Bounce off viewport edges instead of disappearing.
 *   - Flee away from the mouse cursor when it gets too close.
 *
 * @returns {{ start: function(): void }}
 */
function createFlySimulation() {
  var el = createFlyElement();
  var x = 0;
  var y = 0;
  /** Movement heading — where the fly is actually walking. */
  var angle = 0;
  /**
   * Visual heading — what the CSS rotation shows.  Smoothly
   * interpolated toward `angle` each frame so the fly never
   * snaps to a new direction unnaturally.
   */
  var visualAngle = 0;
  var timer = null;
  var mouseX = -9999;
  var mouseY = -9999;

  /**
   * Sets the visual position and rotation of the fly element.
   * The -90° offset corrects for the fact that the fly graphic's
   * head points "down" in its default orientation while angle 0
   * means movement to the right.
   */
  function render() {
    el.style.transform =
      'translate(' + Math.round(x) + 'px,' + Math.round(y) + 'px) rotate(' + Math.round(visualAngle - 90) + 'deg)';
  }

  /**
   * Picks a new random heading in degrees (0-360).
   *
   * @returns {number}
   */
  function randomHeading() {
    return rand(0, 360);
  }

  /**
   * Adds slight random wobble to the current heading so the path
   * looks organic rather than perfectly straight.
   */
  function wobbleHeading() {
    angle += rand(-DIRECTION_WOBBLE_DEG / 2, DIRECTION_WOBBLE_DEG / 2);
  }

  /**
   * Moves `visualAngle` toward `angle` by at most
   * `MAX_TURN_RATE_DEG` per call, taking the shortest
   * rotational path.  When `instant` is true the visual angle
   * snaps immediately (used only on the very first frame so
   * the fly doesn't start rotated the wrong way).
   *
   * @param {boolean} [instant=false] - Skip interpolation.
   */
  function stepVisualAngle(instant) {
    if (instant) {
      visualAngle = angle;
      return;
    }
    var delta = shortestAngularDistance(visualAngle, angle);
    if (Math.abs(delta) <= MAX_TURN_RATE_DEG) {
      visualAngle = angle;
    } else {
      visualAngle += (delta > 0 ? 1 : -1) * MAX_TURN_RATE_DEG;
    }
  }

  /**
   * Clamps the fly's x/y so it stays within the visible viewport.
   * If it hits an edge the heading is reflected so it "bounces".
   */
  function bounceOffEdges() {
    var maxX = window.innerWidth - FLY_SIZE_PX - EDGE_MARGIN_PX;
    var maxY = window.innerHeight - FLY_SIZE_PX - EDGE_MARGIN_PX;

    if (x < EDGE_MARGIN_PX) {
      x = EDGE_MARGIN_PX;
      angle = 180 - angle + rand(-30, 30);
    } else if (x > maxX) {
      x = maxX;
      angle = 180 - angle + rand(-30, 30);
    }

    if (y < EDGE_MARGIN_PX) {
      y = EDGE_MARGIN_PX;
      angle = -angle + rand(-30, 30);
    } else if (y > maxY) {
      y = maxY;
      angle = -angle + rand(-30, 30);
    }
  }

  /**
   * Returns true when the mouse cursor is within
   * `MOUSE_FLEE_RADIUS_PX` of the fly's current position.
   *
   * @returns {boolean}
   */
  function isMouseNear() {
    var dx = x - mouseX;
    var dy = y - mouseY;
    return Math.sqrt(dx * dx + dy * dy) < MOUSE_FLEE_RADIUS_PX;
  }

  /**
   * Returns true when the fly's position is completely outside
   * the visible viewport (with a small buffer).
   *
   * @returns {boolean}
   */
  function isOffScreen() {
    return x < -FLY_SIZE_PX || x > window.innerWidth + FLY_SIZE_PX ||
           y < -FLY_SIZE_PX || y > window.innerHeight + FLY_SIZE_PX;
  }

  /**
   * Removes the fly element from the DOM and stops listening for
   * mouse events.  Called once the fly has left the screen; it
   * will not come back until the next page load.
   */
  function destroy() {
    if (el.parentNode) {
      el.parentNode.removeChild(el);
    }
    document.removeEventListener('mousemove', onMouseMove);
  }

  /**
   * Simulates the fly buzzing off the screen when startled by the
   * mouse cursor.  Cancels whatever phase is active, then rapidly
   * moves the fly in its current facing direction until it leaves
   * the viewport.  Once off screen the fly is permanently removed.
   */
  function flyOff() {
    if (timer !== null) {
      clearInterval(timer);
      clearTimeout(timer);
      timer = null;
    }

    var fleeAngleDeg = visualAngle;
    var speed = FLEE_INITIAL_SPEED_PX;
    var lastTime = null;

    function fleeFrame(timestamp) {
      if (lastTime === null) {
        lastTime = timestamp;
      }
      var dt = (timestamp - lastTime) / FRAME_INTERVAL_MS;
      lastTime = timestamp;

      fleeAngleDeg += rand(-FLEE_WOBBLE_DEG / 2, FLEE_WOBBLE_DEG / 2) * dt;
      var rad = (fleeAngleDeg * Math.PI) / 180;
      x += Math.cos(rad) * speed * dt;
      y += Math.sin(rad) * speed * dt;
      speed *= Math.pow(FLEE_ACCELERATION, dt);
      visualAngle = fleeAngleDeg;
      render();

      if (isOffScreen()) {
        destroy();
      } else {
        requestAnimationFrame(fleeFrame);
      }
    }

    requestAnimationFrame(fleeFrame);
  }

  /**
   * Executes a single "walk" phase: the fly takes `steps` small steps
   * in roughly the current heading with slight wobble, then invokes
   * `onDone` when finished.  Each frame the visual angle is smoothly
   * interpolated toward the movement heading.
   *
   * @param {number}   steps  - How many frames to walk.
   * @param {function} onDone - Callback to invoke after walking.
   */
  function walkPhase(steps, onDone) {
    var remaining = steps;
    var stepSize = rand(MIN_STEP_PX, MAX_STEP_PX);

    timer = setInterval(function () {
      if (isMouseNear()) {
        clearInterval(timer);
        timer = null;
        flyOff();
        return;
      }
      if (remaining <= 0) {
        clearInterval(timer);
        timer = null;
        onDone();
        return;
      }
      wobbleHeading();
      var rad = (angle * Math.PI) / 180;
      x += Math.cos(rad) * stepSize;
      y += Math.sin(rad) * stepSize;
      bounceOffEdges();
      stepVisualAngle(false);
      render();
      remaining--;
    }, FRAME_INTERVAL_MS);
  }

  /**
   * Executes a "turn" phase: the fly sits briefly while its visual
   * heading smoothly rotates toward a new randomly chosen movement
   * heading.  Once the visual angle catches up (or a maximum number
   * of frames pass), `onDone` is invoked.
   *
   * @param {function} onDone - Callback to invoke after turning.
   */
  function turnPhase(onDone) {
    angle = randomHeading();
    var maxFrames = Math.ceil(180 / MAX_TURN_RATE_DEG) + 5;
    var frames = 0;

    timer = setInterval(function () {
      if (isMouseNear()) {
        clearInterval(timer);
        timer = null;
        flyOff();
        return;
      }
      stepVisualAngle(false);
      render();
      frames++;
      var remaining = Math.abs(shortestAngularDistance(visualAngle, angle));
      if (remaining < 1 || frames >= maxFrames) {
        clearInterval(timer);
        timer = null;
        onDone();
      }
    }, FRAME_INTERVAL_MS);
  }

  /**
   * Executes a "pause" phase: the fly sits still for a random duration,
   * subtly animating its wings (via CSS class), then invokes `onDone`.
   *
   * @param {function} onDone - Callback to invoke after the pause.
   */
  function pausePhase(onDone) {
    el.classList.add('af-fly-idle');
    var pauseDuration = rand(MIN_PAUSE_MS, MAX_PAUSE_MS);
    var elapsed = 0;
    var checkInterval = 50;

    timer = setInterval(function () {
      elapsed += checkInterval;
      if (isMouseNear()) {
        clearInterval(timer);
        timer = null;
        el.classList.remove('af-fly-idle');
        flyOff();
        return;
      }
      if (elapsed >= pauseDuration) {
        clearInterval(timer);
        timer = null;
        el.classList.remove('af-fly-idle');
        onDone();
      }
    }, checkInterval);
  }

  /**
   * Main behaviour loop. Alternates randomly between walk, pause,
   * and turn phases indefinitely.
   */
  function loop() {
    var phase = Math.random();
    if (phase < 0.6) {
      walkPhase(randInt(MIN_WALK_STEPS, MAX_WALK_STEPS), loop);
    } else if (phase < 0.85) {
      pausePhase(loop);
    } else {
      turnPhase(loop);
    }
  }

  /**
   * Tracks the mouse position so the fly can flee.
   *
   * @param {MouseEvent} e
   */
  function onMouseMove(e) {
    mouseX = e.clientX;
    mouseY = e.clientY;
  }

  /**
   * Spawns the fly at a random viewport position and starts the loop.
   */
  function start() {
    x = rand(EDGE_MARGIN_PX, window.innerWidth - FLY_SIZE_PX - EDGE_MARGIN_PX);
    y = rand(EDGE_MARGIN_PX, window.innerHeight - FLY_SIZE_PX - EDGE_MARGIN_PX);
    angle = randomHeading();
    stepVisualAngle(true);
    render();
    document.body.appendChild(el);
    document.addEventListener('mousemove', onMouseMove, { passive: true });
    loop();
  }

  return { start: start };
}

/**
 * Injects a minimal `<style>` block for the idle wing-flutter
 * animation.  Kept in JS so the module has zero CSS-file dependencies.
 */
function injectIdleAnimation() {
  var style = document.createElement('style');
  style.textContent = [
    '@keyframes af-fly-wing-flutter{',
    '  0%{transform:rotate(-15deg) scaleX(1)}',
    '  50%{transform:rotate(-15deg) scaleX(0.7)}',
    '  100%{transform:rotate(-15deg) scaleX(1)}',
    '}',
    '@keyframes af-fly-wing-flutter-r{',
    '  0%{transform:rotate(15deg) scaleX(1)}',
    '  50%{transform:rotate(15deg) scaleX(0.7)}',
    '  100%{transform:rotate(15deg) scaleX(1)}',
    '}',
    '.af-fly-idle .af-fly-wing-l{',
    '  animation:af-fly-wing-flutter 0.12s ease-in-out infinite;',
    '}',
    '.af-fly-idle .af-fly-wing-r{',
    '  animation:af-fly-wing-flutter-r 0.12s ease-in-out infinite;',
    '}'
  ].join('\n');
  document.head.appendChild(style);
}

export var AprilFoolsFly = {
  /**
   * Entry point — called once on page load from `app.js`.
   *
   * Does nothing unless today is April 1st (or `?fly=<n>` is in the
   * URL).  On April 1st there is a 30% chance the page view spawns
   * flies; the exact count is determined by a weighted random roll.
   * When forced via query string the given count is spawned directly.
   *
   * @example
   *   AprilFoolsFly.run();
   */
  run: function () {
    if (!isActive()) {
      return;
    }
    if (forcedCount() === 0 && Math.random() > APPEARANCE_PROBABILITY) {
      return;
    }

    var count = rollFlyCount();
    injectIdleAnimation();
    for (var i = 0; i < count; i++) {
      createFlySimulation().start();
    }
  }
};
