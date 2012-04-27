(function() {
  var Game, HEIGHT, Line, MAX_FPS_HISTORY, MAX_HISTORY, TRAIN_SIZE, Train, WIDTH, firstTime, firstTimeFromIndex, formatNumberLength, game, requestAnimFrame,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  HEIGHT = 723;

  WIDTH = 1024;

  TRAIN_SIZE = 4;

  MAX_HISTORY = (WIDTH - 30) / 3;

  MAX_FPS_HISTORY = 20;

  requestAnimFrame = window.requestAnimationFrame || window.webkitRequestAnimationFrame || window.mozRequestAnimationFrame || window.oRequestAnimationFrame || window.msRequestAnimationFrame || (function(callback, element) {
    return window.setTimeout(callback, 1000 / 60);
  });

  firstTime = function(arr) {
    var i;
    i = 0;
    while (arr[i] < 0 && i < arr.length - 1) {
      i += 1;
    }
    return [arr[i], i];
  };

  firstTimeFromIndex = function(arr, idx) {
    var i;
    i = idx;
    while (arr[i] < 0 && i < arr.length - 1) {
      i += 1;
    }
    return [arr[i], i];
  };

  formatNumberLength = function(num, length) {
    var r;
    r = "" + num;
    while (r.length < length) {
      r = "0" + r;
    }
    return r;
  };

  Line = (function() {

    function Line(name, color, points, times) {
      this.name = name;
      this.color = color;
      this.points = points;
      this.times = times;
      this.trains = [];
      this.last_added = 0;
    }

    Line.prototype.update = function(date) {
      var current_mins, current_time, start, station, time, train, trains, _i, _j, _len, _len2, _ref, _ref2, _ref3;
      current_time = game.current_time();
      current_mins = game.current_minutes();
      trains = [];
      _ref = this.trains;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        train = _ref[_i];
        if (train.update()) trains.push(train);
      }
      if (this.last_added !== current_mins) {
        this.last_added = current_mins;
        _ref2 = this.times;
        for (_j = 0, _len2 = _ref2.length; _j < _len2; _j++) {
          time = _ref2[_j];
          _ref3 = firstTime(time), start = _ref3[0], station = _ref3[1];
          if (current_mins === start) {
            trains.push(new Train(station, this.color, time, this.points.slice(0, station + time.length + 1)));
          }
        }
      }
      return this.trains = trains;
    };

    Line.prototype.draw = function(ctx) {
      var train, _i, _len, _ref, _results;
      _ref = this.trains;
      _results = [];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        train = _ref[_i];
        _results.push(train.draw(ctx));
      }
      return _results;
    };

    return Line;

  })();

  Train = (function() {

    function Train(station, color, times, points) {
      this.station = station;
      this.color = color;
      this.times = times;
      this.points = points;
      this.w = TRAIN_SIZE;
      this.h = TRAIN_SIZE;
      this.x = -10;
      this.y = -10;
      this.station = 0;
    }

    Train.prototype.lerp = function(p1, p2, total, current) {
      var ratio, x, y;
      ratio = current / total;
      x = p1[0] + (p2[0] - p1[0]) * ratio;
      y = p1[1] + (p2[1] - p1[1]) * ratio;
      return [x, y];
    };

    Train.prototype.update = function(points) {
      var curr, date, next_station, next_time, p1, p2, totl, _ref, _ref2;
      date = game.current_time();
      _ref = firstTimeFromIndex(this.times, this.station + 1), next_time = _ref[0], next_station = _ref[1];
      p1 = this.points[this.station];
      p2 = this.points[next_station];
      totl = this.station >= this.times.length - 1 ? 200 : next_time - this.times[this.station];
      curr = date - this.times[this.station];
      if (totl < -80000) totl += 86400;
      if (curr < -80000) curr += 86400;
      _ref2 = this.lerp(p1, p2, totl, curr), this.x = _ref2[0], this.y = _ref2[1];
      if (curr >= totl) {
        this.station += 1;
        if (this.station > this.times.length - 1) return false;
      }
      return true;
    };

    Train.prototype.draw = function(ctx) {
      ctx.fillStyle = this.color;
      return ctx.fillRect(this.x - this.w / 2, this.y - this.h / 2, this.w, this.h);
    };

    return Train;

  })();

  Game = (function() {

    function Game(canvas, ctx) {
      var line, _i, _len;
      this.canvas = canvas;
      this.ctx = ctx;
      this.draw = __bind(this.draw, this);
      this.frameCount = 0;
      this.lastFrameReset = new Date();
      this.fps = 0;
      this.bg = new Image;
      this.bg.src = "metro.gif";
      this.dt = 0;
      this.start_time = new Date(2012, 1, 1, 4, 45, 0);
      this.last_update = this.lastFrameReset.getTime();
      this.ratio = 10;
      this.train_counts = [];
      this.train_count_idx = 0;
      this.fps_history = [];
      this.fps_history_idx = 0;
      this.lines = [];
      for (_i = 0, _len = lines.length; _i < _len; _i++) {
        line = lines[_i];
        this.lines.push(new Line(line.name, line.color, line.stations, line.timetable));
      }
    }

    Game.prototype.train_count = function() {
      var count, line, _i, _len, _ref;
      count = 0;
      _ref = this.lines;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        line = _ref[_i];
        if (line.trains) count += line.trains.length;
      }
      return count;
    };

    Game.prototype.current_time = function() {
      return this.start_time.getHours() * 3600 + this.start_time.getMinutes() * 60 + this.start_time.getSeconds();
    };

    Game.prototype.current_minutes = function() {
      return this.start_time.getHours() * 3600 + this.start_time.getMinutes() * 60;
    };

    Game.prototype.update = function(dt) {
      var date, elapsed, line, ratio, _i, _len, _ref;
      date = dt.getTime();
      _ref = this.lines;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        line = _ref[_i];
        line.update(date);
      }
      elapsed = date - this.last_update;
      if (elapsed > 10) {
        ratio = parseFloat(document.getElementById("ratio").value);
        if (!isNaN(ratio)) this.ratio = ratio;
        this.start_time.setSeconds(this.start_time.getSeconds() + elapsed * this.ratio);
        return this.last_update = date;
      }
    };

    Game.prototype.updateFPS = function(date) {
      this.frameCount++;
      if (this.frameCount > 50) {
        this.dt = date.getTime() - this.lastFrameReset.getTime();
        this.fps = this.frameCount / this.dt * 1000;
        this.frameCount = 0;
        this.lastFrameReset = date;
        if (this.train_counts.length < MAX_HISTORY) {
          this.train_counts.push(game.train_count());
        } else {
          this.train_counts[this.train_count_idx] = game.train_count();
          this.train_count_idx++;
          if (this.train_count_idx > this.train_counts.length - 1) {
            this.train_count_idx = 0;
          }
        }
        if (this.fps_history.length < MAX_FPS_HISTORY) {
          return this.fps_history.push(this.fps);
        } else {
          this.fps_history[this.fps_history_idx] = this.fps;
          this.fps_history_idx++;
          if (this.fps_history_idx > MAX_FPS_HISTORY) {
            return this.fps_history_idx = 0;
          }
        }
      }
    };

    Game.prototype.draw = function() {
      var date, fps, height, i, line, train_count, _i, _j, _k, _len, _len2, _len3, _ref, _ref2, _ref3;
      date = new Date();
      this.updateFPS(date);
      this.update(date);
      this.ctx.fillStyle = '#000';
      this.ctx.fillRect(0, 0, this.canvas.width, this.canvas.height);
      if (document.getElementById("map").checked) {
        this.ctx.save();
        this.ctx.globalAlpha = 0.1;
        this.ctx.drawImage(this.bg, 0, 0, 1024, 723);
        this.ctx.restore();
      }
      this.ctx.fillStyle = '#f00';
      this.ctx.fillText("" + (this.start_time.getHours()) + ":" + (this.start_time.getMinutes()) + " - Trains: " + (this.train_count()), 10, 15);
      this.ctx.fillText("FPS:" + (Math.round(this.fps * 100) / 100), WIDTH - 70, 15);
      _ref = this.lines;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        line = _ref[_i];
        line.draw(this.ctx);
      }
      i = 0;
      _ref2 = this.train_counts;
      for (_j = 0, _len2 = _ref2.length; _j < _len2; _j++) {
        train_count = _ref2[_j];
        this.ctx.fillStyle = i === this.train_count_idx - 1 ? '#6f6' : '#66f';
        height = (train_count / 5) * 2 + 1;
        this.ctx.fillRect(15 + i * 3, HEIGHT - 15 - height, 2, height);
        i++;
      }
      i = 0;
      _ref3 = this.fps_history;
      for (_k = 0, _len3 = _ref3.length; _k < _len3; _k++) {
        fps = _ref3[_k];
        this.ctx.fillStyle = i === this.fps_history_idx - 1 ? '#f22' : '#2f2';
        height = (fps / 60) * 30;
        this.ctx.fillRect(WIDTH - 15 - MAX_FPS_HISTORY * 3 + i * 3, 55 - height, 2, 2);
        i++;
      }
      if (document.getElementById("render").checked) {
        return requestAnimFrame(this.draw);
      }
    };

    return Game;

  })();

  game = null;

  window.onload = function() {
    var c, canvas, render_button;
    canvas = document.getElementById('canvas');
    canvas.width = WIDTH;
    canvas.height = HEIGHT;
    c = canvas.getContext('2d');
    game = new Game(canvas, c);
    render_button = document.getElementById("render");
    render_button.onchange = function() {
      if (this.checked) return game.draw();
    };
    return game.draw();
  };

}).call(this);
