require "aruba/rspec"

RSpec.configure do |config|
  config.disable_monkey_patching!
  config.include Aruba::Api, type: :aruba

  config.before :each, type: :aruba do
    restore_env
    setup_aruba
    if ENV["SHOW_OUTPUT"] == "true"
      aruba.announcer.activate :stdout
      aruba.announcer.activate :stderr
    end
  end

end
