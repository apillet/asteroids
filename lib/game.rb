class GameWindow < Gosu::Window
  def initialize
    super(640, 480, true)
    # @background_image = Gosu::Image.new(self, "assets/background.png", true)
    @life_image = Gosu::Image.new(self, "assets/ship.png", false)
    @font = Gosu::Font.new(self, 'Inconsolata-dz', 24)
    @game_in_progress = false
    title_screen
  end

  def title_screen
    @asteroids = spawn_asteroids(4)
    @asteroids += @asteroids[0].kill
    @asteroids += @asteroids[1].kill
    @asteroids += @asteroids.last.kill
  end

  def setup_game
    @player = Player.new(self)
    @level = 1
    @asteroid_count = 3
    @asteroids = spawn_asteroids(@asteroid_count)
    @projectiles = []
    @game_in_progress = true
  end

  # 60 times per second
  def update
    if button_down? Gosu::KbS
      setup_game unless @game_in_progress
    end

    if button_down? Gosu::KbR
      title_screen unless @game_in_progress == false
      @game_in_progress = false
    end
    
    @asteroids.each{|asteroid| asteroid.move}
    @asteroids.reject!{|asteroid| asteroid.dead?}

    return unless @game_in_progress
    return if @player.dead?

    control_player

    @player.move

    @projectiles.each{|projectile| projectile.move}
    @projectiles.reject!{|projectile| projectile.dead?}

    detect_collisions
    next_level if @asteroids.size == 0 
  end

  def next_level
    @asteroid_count += 1
    @level += 1
    @asteroids = spawn_asteroids(@asteroid_count)
  end

  # happens immediately after each iteration of the update method
  def draw
    # @background_image.draw(0, 0, 0)
    @asteroids.each{|asteroid| asteroid.draw}
    title_text unless @game_in_progress
    return unless @game_in_progress
    game_over_text if @player.lives <= 0
    score_text
    level_text
    return if @player.dead?
    @player.draw
    @projectiles.each{|projectile| projectile.draw}
    draw_lives
  end 

  def score_text
    write @player.score, 10, 10
  end

  def level_text
    write @level, 610, 10
  end

  def title_text
    write "ASTEROIDS", 175, 120, 2.8, 2.8
    write "press 's' to start", 210, 320
    write "press 'q' to quit", 216, 345
  end

  def game_over_text
    write "GAME OVER", 200, 150, 2, 2
    write "press 'r' to restart", 195, 320
    write "press 'q' to quit", 210, 345
  end

  def write text, x, y, factor_x = 1, factor_y = 1
    @font.draw(text, x, y, 50, factor_x, factor_y, Gosu::Color::WHITE)
  end

  def draw_lives
    return unless @player.lives > 0
    x = 10
    @player.lives.times do 
      @life_image.draw(x, 40, 0)
      x += 20
    end
  end

  def button_down(id)
    close if id == Gosu::KbQ
    shoot if id == Gosu::KbSpace
  end
  
  def shoot
    if can_shoot?
      @projectiles << @player.shoot
    end
  end
  
  def can_shoot?
     @game_in_progress && @projectiles.size < 5
  end

  def control_player
    if button_down? Gosu::KbLeft
      @player.turn_left
    end
    if button_down? Gosu::KbRight
      @player.turn_right
    end
    if button_down? Gosu::KbUp
      @player.accelerate
    end
  end

  def detect_collisions
    @asteroids.each do |asteroid| 
      if collision?(asteroid, @player)
        @player.kill
      end
    end
    @projectiles.each do |projectile| 
      @asteroids.each do |asteroid|
        if collision?(projectile, asteroid)
          projectile.kill
          @player.score += asteroid.points
          @asteroids += asteroid.kill
        end
      end
    end
  end

  def collision?(object_1, object_2)
    hitbox_1, hitbox_2 = object_1.hitbox, object_2.hitbox
    common_x = hitbox_1[:x] & hitbox_2[:x]
    common_y = hitbox_1[:y] & hitbox_2[:y]
    common_x.size > 0 && common_y.size > 0 
  end

  def spawn_asteroids(count=3)
    Array.new(count) { Asteroid.new(self) }
  end
end
