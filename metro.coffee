HEIGHT= 723
WIDTH = 1024
TRAIN_SIZE = 4
MAX_HISTORY = (WIDTH - 30) / 3
MAX_FPS_HISTORY = 20

#{{{ - Utilities
requestAnimFrame =
      window.requestAnimationFrame ||
      window.webkitRequestAnimationFrame ||
      window.mozRequestAnimationFrame ||
      window.oRequestAnimationFrame ||
      window.msRequestAnimationFrame ||
      ((callback, element) ->
        window.setTimeout(callback, 1000/60)
      )

firstTime = (arr) ->
  i = 0
  while arr[i] < 0 && i < arr.length - 1
    i += 1

  [arr[i], i]

firstTimeFromIndex = (arr, idx) ->
  i = idx
  while arr[i] < 0 && i < arr.length - 1
    i += 1

  [arr[i], i]

formatNumberLength = (num, length) ->
    r = "" + num
    while r.length < length
      r = "0" + r
    r
#}}}

class Line
  constructor: (@name, @color, @points, @times) ->
    @trains = []
    @last_added = 0

  update: (date) ->
    current_time = game.current_time()
    current_mins = game.current_minutes()

    trains = []

    for train in @trains
      if train.update()
        trains.push train

    if  @last_added != current_mins
      @last_added = current_mins
      for time in @times
        [start, station] = firstTime(time)
        if current_mins == start
          trains.push new Train(station, @color, time, @points.slice(0, station+time.length+1))

    @trains = trains

  draw: (ctx) ->
    for train in @trains
      train.draw(ctx)

class Train
  constructor: (@station, @color, @times, @points) ->
    @w = TRAIN_SIZE
    @h = TRAIN_SIZE
    @x = -10
    @y = -10
    @station = 0

  lerp: (p1, p2, total, current) ->
    ratio = current / total
    x = p1[0] + ( p2[0] - p1[0] ) * ratio
    y = p1[1] + ( p2[1] - p1[1] ) * ratio

    [x, y]

  update: (points) ->
    date = game.current_time()
    [next_time, next_station] = firstTimeFromIndex(@times, @station+1)
    p1 = @points[@station]
    p2 = @points[next_station]

    totl = if (@station >= @times.length - 1) then 200 else next_time-@times[@station]
    curr = date - @times[@station]

    if totl < -80000
      totl += 86400
    if curr < -80000
      curr += 86400

    [@x, @y] = this.lerp p1, p2, totl, curr

    if curr >= totl
      @station += 1
      if @station > @times.length - 1
        return false

    return true

  draw: (ctx) ->
    ctx.fillStyle = @color
    ctx.fillRect(@x-@w/2, @y-@h/2, @w, @h)

class Game
  constructor: (@canvas, @ctx) ->
    @frameCount = 0
    @lastFrameReset = new Date()
    @fps = 0
    @bg = new Image
    @bg.src = "metro.gif"
    @dt = 0
    @start_time = new Date(2012, 1, 1, 4, 45, 0)
    @last_update = @lastFrameReset.getTime()
    @ratio = 10
    @train_counts = []
    @train_count_idx = 0
    @fps_history = []
    @fps_history_idx = 0

    @lines = []
    for line in lines
      @lines.push new Line(line.name, line.color, line.stations, line.timetable)

  train_count: () ->
    count = 0
    for line in @lines
      if line.trains
        count += line.trains.length

    count

  current_time: () ->
    @start_time.getHours()*3600 + @start_time.getMinutes()*60+@start_time.getSeconds()

  current_minutes: () ->
    @start_time.getHours()*3600 + @start_time.getMinutes()*60

  update: (dt) ->
    date = dt.getTime()

    for line in @lines
      line.update(date)

    elapsed = date - @last_update
    if elapsed > 10
      ratio = parseFloat(document.getElementById("ratio").value)
      if !isNaN(ratio)
        @ratio = ratio
      @start_time.setSeconds(@start_time.getSeconds()+elapsed*@ratio)
      @last_update = date

  updateFPS: (date) ->
    @frameCount++

    if @frameCount > 50
      @dt = date.getTime() - @lastFrameReset.getTime()
      @fps = @frameCount / @dt * 1000
      @frameCount = 0
      @lastFrameReset = date

      if @train_counts.length < MAX_HISTORY
        @train_counts.push game.train_count()
      else
        @train_counts[@train_count_idx] = game.train_count()
        @train_count_idx++
        if @train_count_idx > @train_counts.length - 1
          @train_count_idx = 0

      if @fps_history.length < MAX_FPS_HISTORY
        @fps_history.push @fps
      else
        @fps_history[@fps_history_idx] = @fps
        @fps_history_idx++
        if @fps_history_idx > MAX_FPS_HISTORY
          @fps_history_idx= 0

  draw: () =>
    date = new Date()
    this.updateFPS(date)
    this.update(date)

    @ctx.fillStyle = '#000'
    @ctx.fillRect(0, 0, @canvas.width, @canvas.height)

    if document.getElementById("map").checked
      @ctx.save()
      @ctx.globalAlpha = 0.1
      @ctx.drawImage(@bg, 0, 0, 1024, 723)
      @ctx.restore()

    @ctx.fillStyle = '#f00'
    @ctx.fillText "#{@start_time.getHours()}:#{@start_time.getMinutes()} - Trains: #{this.train_count()}", 10, 15
    @ctx.fillText "FPS:#{Math.round(@fps*100)/100}", WIDTH-70, 15

    for line in @lines
      line.draw(@ctx)

    i = 0
    for train_count in @train_counts
      @ctx.fillStyle = if i == @train_count_idx-1 then '#6f6' else '#66f'
      height = (train_count / 5)*2 + 1
      @ctx.fillRect( 15+i*3, HEIGHT-15-height, 2, height)
      i++

    i = 0
    for fps in @fps_history
      @ctx.fillStyle = if i == @fps_history_idx-1 then '#f22' else '#2f2'
      height = (fps / 60) * 30
      @ctx.fillRect( WIDTH-15-MAX_FPS_HISTORY*3+i*3, 55-height, 2, 2)
      i++

    if document.getElementById("render").checked
      requestAnimFrame this.draw


game = null
window.onload = () ->
  canvas = document.getElementById('canvas')
  canvas.width  = WIDTH
  canvas.height = HEIGHT

  c = canvas.getContext('2d')

  game = new Game(canvas, c)

  render_button = document.getElementById("render")
  render_button.onchange = () ->
    if this.checked
      game.draw()

  game.draw()

