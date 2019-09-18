# frozen_string_literal: true

module Hcaptcha
  module Adapters
    module ViewMethods
      def hcaptcha
        ::Hcaptcha::Helpers.hcaptcha(options = {})
      end
    end
  end
end
