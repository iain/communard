require 'aruba/api'
require 'aruba/reporting'

RSpec.configure do |config|
  config.disable_monkey_patching!
  config.include Aruba::Api, type: :aruba

  config.before :each do
    next unless self.class.include?(Aruba::Api)
    restore_env
    clean_current_dir

    if ENV["DEBUG"] == "true"
      @announce_stdout = true
      @announce_stderr = true
      @announce_cmd = true
      @announce_dir = true
      @announce_env = true
    end
  end

end
