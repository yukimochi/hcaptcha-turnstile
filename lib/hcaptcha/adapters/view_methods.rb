# frozen_string_literal: true

module Hcaptcha
  module Adapters
    module ViewMethods
      def hcaptcha_tags(options = {})
        ::Hcaptcha::Helpers.hcaptcha(options)
      end
    end
  end
end
