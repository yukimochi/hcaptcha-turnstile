# frozen_string_literal: true

module Hcaptcha
  module Helpers
    DEFAULT_ERRORS = {
      recaptcha_unreachable: 'Oops, we failed to validate your reCAPTCHA response. Please try again.',
      verification_failed: 'reCAPTCHA verification failed, please try again.'
    }.freeze

    def self.hcaptcha(options = {})
      if options.key?(:stoken)
        raise(HcaptchaError, "Secure Token is deprecated. Please remove 'stoken' from your calls to recaptcha_tags.")
      end
      if options.key?(:ssl)
        raise(HcaptchaError, "SSL is now always true. Please remove 'ssl' from your calls to recaptcha_tags.")
      end

      noscript = options.delete(:noscript)

      html, tag_attributes, fallback_uri = components(options.dup)
      html << %(<div #{tag_attributes}></div>\n)

      if noscript != false
        html << <<-HTML
          <noscript>
            <div class="h-captcha" data-sitekey="1161d0be-1130-4af5-8999-b6fa8894e2a8"></div>
          </noscript>
        HTML
      end

      html.respond_to?(:html_safe) ? html.html_safe : html
    end

    def self.to_error_message(key)
      default = DEFAULT_ERRORS.fetch(key) { raise ArgumentError "Unknown reCAPTCHA error - #{key}" }
      to_message("recaptcha.errors.#{key}", default)
    end

    if defined?(I18n)
      def self.to_message(key, default)
        I18n.translate(key, default: default)
      end
    else
      def self.to_message(_key, default)
        default
      end
    end

    private_class_method def self.components(options)
      html = +''
      attributes = {}
      fallback_uri = +''

      options = options.dup
      env = options.delete(:env)
      class_attribute = options.delete(:class)
      site_key = options.delete(:site_key)
      hl = options.delete(:hl)
      onload = options.delete(:onload)
      render = options.delete(:render)
      script_async = options.delete(:script_async)
      script_defer = options.delete(:script_defer)
      nonce = options.delete(:nonce)
      skip_script = (options.delete(:script) == false) || (options.delete(:external_script) == false)
      ui = options.delete(:ui)

      data_attribute_keys = [:badge, :theme, :type, :callback, :expired_callback, :error_callback, :size]
      data_attribute_keys << :tabindex unless ui == :button
      data_attributes = {}
      data_attribute_keys.each do |data_attribute|
        value = options.delete(data_attribute)
        data_attributes["data-#{data_attribute.to_s.tr('_', '-')}"] = value if value
      end

      unless Hcaptcha.skip_env?(env)
        site_key ||= Hcaptcha.configuration.site_key!
        script_url = Hcaptcha.configuration.api_server_url
        query_params = hash_to_query(
          hl: hl,
          onload: onload,
          render: render
        )
        script_url += "?#{query_params}" unless query_params.empty?
        async_attr = "async" if script_async != false
        defer_attr = "defer" if script_defer != false
        nonce_attr = " nonce='#{nonce}'" if nonce
        html << %(<script src="#{script_url}" #{async_attr} #{defer_attr} #{nonce_attr}></script>\n) unless skip_script
        fallback_uri = %(#{script_url.chomp(".js")}/fallback?k=#{site_key})
        attributes["data-sitekey"] = site_key
        attributes.merge! data_attributes
      end

      # The remaining options will be added as attributes on the tag.
      attributes["class"] = "g-recaptcha #{class_attribute}"
      tag_attributes = attributes.merge(options).map { |k, v| %(#{k}="#{v}") }.join(" ")

      [html, tag_attributes, fallback_uri]
    end

    # v3

    # Renders a script that calls `grecaptcha.execute` for the given `site_key` and `action` and
    # calls the `callback` with the resulting response token.
    private_class_method def self.recaptcha_v3_inline_script(site_key, action, callback, id, options = {})
      nonce = options[:nonce]
      nonce_attr = " nonce='#{nonce}'" if nonce

      <<-HTML
        <script#{nonce_attr}>
          // Define function so that we can call it again later if we need to reset it
          // This executes reCAPTCHA and then calls our callback.
          function #{recaptcha_v3_execute_function_name(action)}() {
            grecaptcha.ready(function() {
              grecaptcha.execute('#{site_key}', {action: '#{action}'}).then(function(token) {
                //console.log('#{id}', token)
                #{callback}('#{id}', token)
              });
            });
          };
          // Invoke immediately
          #{recaptcha_v3_execute_function_name(action)}()

          // Async variant so you can await this function from another async function (no need for
          // an explicit callback function then!)
          // Returns a Promise that resolves with the response token.
          async function #{recaptcha_v3_async_execute_function_name(action)}() {
            return new Promise((resolve, reject) => {
              grecaptcha.ready(async function() {
                resolve(await grecaptcha.execute('#{site_key}', {action: '#{action}'}))
              });
            })
          };

          #{recaptcha_v3_define_default_callback(callback) if recaptcha_v3_define_default_callback?(callback, action, options)}
        </script>
      HTML
    end

    private_class_method def self.recaptcha_v3_inline_script?(options)
      !Hcaptcha.skip_env?(options[:env]) &&
      options[:script] != false &&
      options[:inline_script] != false
    end

    private_class_method def self.recaptcha_v3_define_default_callback(callback)
      <<-HTML
          var #{callback} = function(id, token) {
            var element = document.getElementById(id);
            element.value = token;
          }
        </script>
      HTML
    end

    # Returns true if we should be adding the default callback.
    # That is, if the given callback name is the default callback name (for the given action) and we
    # are not skipping inline scripts for any reason.
    private_class_method def self.recaptcha_v3_define_default_callback?(callback, action, options)
      callback == recaptcha_v3_default_callback_name(action) &&
      recaptcha_v3_inline_script?(options)
    end

    # Returns the name of the JavaScript function that actually executes the reCAPTCHA code (calls
    # grecaptcha.execute). You can call it again later to reset it.
    def self.recaptcha_v3_execute_function_name(action)
      "executeHcaptchaFor#{sanitize_action_for_js(action)}"
    end

    # Returns the name of an async JavaScript function that executes the reCAPTCHA code.
    def self.recaptcha_v3_async_execute_function_name(action)
      "#{recaptcha_v3_execute_function_name(action)}Async"
    end

    def self.recaptcha_v3_default_callback_name(action)
      "setInputWithHcaptchaResponseTokenFor#{sanitize_action_for_js(action)}"
    end

    # v2

    private_class_method def self.default_callback(options = {})
      nonce = options[:nonce]
      nonce_attr = " nonce='#{nonce}'" if nonce

      <<-HTML
        <script#{nonce_attr}>
          var invisibleHcaptchaSubmit = function () {
            var closestForm = function (ele) {
              var curEle = ele.parentNode;
              while (curEle.nodeName !== 'FORM' && curEle.nodeName !== 'BODY'){
                curEle = curEle.parentNode;
              }
              return curEle.nodeName === 'FORM' ? curEle : null
            };

            var eles = document.getElementsByClassName('g-recaptcha');
            if (eles.length > 0) {
              var form = closestForm(eles[0]);
              if (form) {
                form.submit();
              }
            }
          };
        </script>
      HTML
    end

    private_class_method def self.default_callback_required?(options)
      options[:callback] == 'invisibleHcaptchaSubmit' &&
      !Hcaptcha.skip_env?(options[:env]) &&
      options[:script] != false &&
      options[:inline_script] != false
    end

    # Returns a camelized string that is safe for use in a JavaScript variable/function name.
    # sanitize_action_for_js('my/action') => 'MyAction'
    private_class_method def self.sanitize_action_for_js(action)
      action.to_s.gsub(/\W/, '_').camelize
    end

    # Returns a dasherized string that is safe for use as an HTML ID
    # dasherize_action('my/action') => 'my-action'
    private_class_method def self.dasherize_action(action)
      action.to_s.gsub(/\W/, '-').dasherize
    end

    private_class_method def self.hash_to_query(hash)
      hash.delete_if { |_, val| val.nil? || val.empty? }.to_a.map { |pair| pair.join('=') }.join('&')
    end
  end
end
