if Rails.env.development? && defined?(Bullet)
  Rails.application.configure do
    config.after_initialize do
      Bullet.enable        = true
      Bullet.alert         = true
      Bullet.bullet_logger = true
      Bullet.console       = true
      Bullet.rails_logger  = true
      Bullet.add_footer    = true
    end
  end
end
