class Game::CreateTokenService
  DEFAULT_BYTES = 32

  def self.call(bytes: DEFAULT_BYTES)
    new(bytes: bytes).call
  end

  def initialize(bytes: DEFAULT_BYTES)
    @bytes = bytes
  end

  def call
    SecureRandom.urlsafe_base64(@bytes)
  end
end
