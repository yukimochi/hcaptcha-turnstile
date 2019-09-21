# frozen_string_literal: true

module Hcaptcha
  class Railtie < Rails::Railtie
    ActiveSupport.on_load(:action_view) do
      include Hcaptcha::Adapters::ViewMethods
    end

    ActiveSupport.on_load(:action_controller) do
      include Hcaptcha::Adapters::ControllerMethods
    end

    initializer 'hcaptcha' do |app|
      Hcaptcha::Railtie.instance_eval do
        pattern = pattern_from app.config.i18n.available_locales

        add("rails/locales/#{pattern}.yml")
      end
    end

    class << self
      protected

      def add(pattern)
        files = Dir[File.join(File.dirname(__FILE__), '../..', pattern)]
        I18n.load_path.concat(files)
      end

      def pattern_from(args)
        array = Array(args || [])
        array.blank? ? '*' : "{#{array.join ','}}"
      end
    end
  end
end
