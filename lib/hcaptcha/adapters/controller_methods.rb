# frozen_string_literal: true

module Hcaptcha
  module Adapters
    module ControllerMethods
      private

      # Your private API can be specified in the +options+ hash or preferably
      # using the Configuration.
      def verify_hcaptcha(options = {})
        options = { model: options } unless options.is_a? Hash
        return true if Hcaptcha.skip_env?(options[:env])

        model = options[:model]
        attribute = options.fetch(:attribute, :base)
        hcaptcha_response = options[:response] || hcaptcha_response_token(options[:action])

        begin
          verified = if Hcaptcha.invalid_response?(hcaptcha_response)
            false
          else
            unless options[:skip_remote_ip]
              remoteip = (request.respond_to?(:remote_ip) && request.remote_ip) || (env && env['REMOTE_ADDR'])
              options = options.merge(remote_ip: remoteip.to_s) if remoteip
            end

            Hcaptcha.verify_via_api_call(hcaptcha_response, options)
          end

          if verified
            flash.delete(:hcaptcha_error) if hcaptcha_flash_supported? && !model
            true
          else
            hcaptcha_error(
              model,
              attribute,
              options.fetch(:message) { Hcaptcha::Helpers.to_error_message(:verification_failed) }
            )
            false
          end
        rescue Timeout::Error
          if Hcaptcha.configuration.handle_timeouts_gracefully
            hcaptcha_error(
              model,
              attribute,
              options.fetch(:message) { Hcaptcha::Helpers.to_error_message(:hcaptcha_unreachable) }
            )
            false
          else
            raise HcaptchaError, 'Hcaptcha unreachable.'
          end
        rescue StandardError => e
          raise HcaptchaError, e.message, e.backtrace
        end
      end

      def verify_hcaptcha!(options = {})
        verify_hcaptcha(options) || raise(VerifyError)
      end

      def hcaptcha_error(model, attribute, message)
        if model
          model.errors.add(attribute, message)
        elsif hcaptcha_flash_supported?
          flash[:hcaptcha_error] = message
        end
      end

      def hcaptcha_flash_supported?
        request.respond_to?(:format) && request.format == :html && respond_to?(:flash)
      end

      # Extracts response token from params. params['g-hcaptcha-response'] should either be a
      # string or a hash with the action name(s) as keys. If it is a hash, then `action` is used as
      # the key.
      # @return [String] A response token if one was passed in the params; otherwise, `''`
      def hcaptcha_response_token(action = nil)
        response_param = params['g-hcaptcha-response']
        if response_param&.respond_to?(:to_h) # Includes ActionController::Parameters
          response_param[action].to_s
        else
          response_param.to_s
        end
      end
    end
  end
end
