require "aruba"

RSpec.configure do |config|
  config.disable_monkey_patching!
  config.include Aruba::Api, type: :aruba

  config.before :each, type: :aruba do
    restore_env
    setup_aruba
  end

end
