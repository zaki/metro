HEIGHT= 723
WIDTH = 1024

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
          trains.push new Train(station, @color, time, @points)

    @trains = trains

  draw: (ctx) ->
    for train in @trains
      train.draw(ctx)

class Train
  constructor: (@station, @color, @times, @points) ->
    @w = 3
    @h = 3
    @x = 0
    @y = 0
    @station = 0

  lerp: (p1, p2, total, current) ->
    ratio = current / total
    x = p1[0] + ( p2[0] - p1[0] ) * ratio
    y = p1[1] + ( p2[1] - p1[1] ) * ratio

    [x, y]

  update: (points) ->
    date = game.current_time()
    p1 = @points[@station]
    p2 = @points[@station+1]

    totl = if @station == @times.length - 1 then 200 else @times[@station+1]-@times[@station]
    curr = date - @times[@station]

    [@x, @y] = this.lerp p1, p2, totl, curr

    if curr >= totl
      @station += 1
      if @station == @points.length - 1
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
    @last_update = new Date().getTime()

    @lines = []
    for line in lines
      console.log line.timetable[2]
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
      @start_time.setSeconds(@start_time.getSeconds()+elapsed/5)
      @last_update = date

  updateFPS: (date) ->
    @frameCount++

    if @frameCount > 50
      @dt = date.getTime() - @lastFrameReset.getTime()
      @fps = @frameCount / @dt * 1000
      @frameCount = 0
      @lastFrameReset = date

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

