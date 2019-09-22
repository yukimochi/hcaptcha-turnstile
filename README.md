# hCaptcha
[![Gem Version](https://badge.fury.io/rb/hcaptcha.svg)](https://badge.fury.io/rb/hcaptcha)

Disclaimer: This gem is forked from the [recaptcha gem](https://github.com/ambethia/recaptcha). All ideas, including the documentation and demo Rails and Sinatra integrations come from [recaptcha gem](https://github.com/ambethia/recaptcha) but are adoped for hCaptcha.

Author:    Tyler VanNurden & Jason L Perry (http://ambethia.com)<br/>
License:   [MIT](http://creativecommons.org/licenses/MIT/)<br/>
Info:      https://github.com/firstmoversadvantage/hcaptcha<br/>
Bugs:      https://github.com/firstmoversadvantage/hcaptcha/issues<br/>

This gem provides helper methods for the [hCaptcha API](https://hcaptcha.com). In your
views you can use the `hcaptcha_tags` method to embed the needed javascript, and you can validate
in your controllers with `verify_hcaptcha` or `verify_hcaptcha!`.

## Obtaining a key and setup

Go to the [hCaptcha](https://hcaptcha.com/webmaster/signup) signup page to obtain API keys. **You'll also need to set a hostname that your application will run from, even for local development. hCaptcha will not work if your application is being served from `localhost` or `127.0.0.1`. You will need to add a hosts entry for local development.** See the [hCaptcha docs](https://hcaptcha.com/docs) for how to do this.

## Rails Installation

```ruby
gem "hcaptcha"
```

You can keep keys out of the code base with environment variables or with Rails [secrets](https://api.rubyonrails.org/classes/Rails/Application.html#method-i-secrets).<br/>

In development, you can use the [dotenv](https://github.com/bkeepers/dotenv) gem. (Make sure to add it above `gem 'hcaptcha'`.)

See [Alternative API key setup](#alternative-api-key-setup) for more ways to configure or override
keys. See also the
[Configuration](https://www.rubydoc.info/github/ambethia/recaptcha/master/Recaptcha/Configuration)
documentation.

```shell
export HCAPTCHA_SITE_KEY='6Lc6BAAAAAAAAChqRbQZcn_yyyyyyyyyyyyyyyyy'
export HCAPTCHA_SECRET_KEY='6Lc6BAAAAAAAAKN3DRm6VA_xxxxxxxxxxxxxxxxx'
```

Add `hcaptcha_tags` to the forms you want to protect:

```erb
<%= form_for @foo do |f| %>
  # …
  <%= hcaptcha_tags %>
  # …
<% end %>
```

Then, add `verify_hcaptcha` logic to each form action that you've protected:

```ruby
# app/controllers/users_controller.rb
@user = User.new(params[:user].permit(:name))
if verify_hcaptcha(model: @user) && @user.save
  redirect_to @user
else
  render 'new'
end
```

## Sinatra / Rack / Ruby installation

See [sinatra demo](/demo/sinatra) for details.

 - add `gem 'hcaptcha'` to `Gemfile`
 - set env variables
 - `include Hcaptcha::Adapters::ViewMethods` where you need `recaptcha_tags`
 - `include Hcaptcha::Adapters::ControllerMethods` where you need `verify_recaptcha`


## hCaptcha API and Usage

### `recaptcha_tags`

Use in your views to render the JavaScript widget.

### `verify_recaptcha`

This method returns `true` or `false` after processing the response token from the hCaptcha widget.
This is usually called from your controller, as seen [above](#rails-installation).

Passing in the ActiveRecord object via `model: object` is optional. If you pass a `model`—and the
captcha fails to verify—an error will be added to the object for you to use (available as
`object.errors`).

Why isn't this a model validation? Because that violates MVC. You can use it like this, or how ever
you like.

Some of the options available:

| Option         | Description |
|----------------|-------------|
| `:model`       | Model to set errors.
| `:attribute`   | Model attribute to receive errors. (default: `:base`)
| `:message`     | Custom error message.
| `:secret_key`  | Override the secret API key from the configuration.
| `:timeout`     | The number of seconds to wait for hCaptcha servers before give up. (default: `3`)
| `:response`    | Custom response parameter. (default: `params['g-recaptcha-response']`)
| `:hostname`    | Expected hostname or a callable that validates the hostname, see [domain validation](https://developers.google.com/recaptcha/docs/domain_validation) and [hostname](https://developers.google.com/recaptcha/docs/verify#api-response) docs. (default: `nil`, but can be changed by setting `config.hostname`)
| `:env`         | Current environment. The request to verify will be skipped if the environment is specified in configuration under `skip_verify_env`

## I18n support

hCaptcha supports the I18n gem (it comes with English translations)
To override or add new languages, add to `config/locales/*.yml`

```yaml
# config/locales/en.yml
en:
  recaptcha:
    errors:
      verification_failed: 'hCaptcha was incorrect, please try again.'
      recaptcha_unreachable: 'hCaptcha verification server error, please try again.'
```

## Testing

By default, hCaptcha is skipped in "test" and "cucumber" env. To enable it during test:

```ruby
Recaptcha.configuration.skip_verify_env.delete("test")
```

## Alternative API key setup

### Recaptcha.configure

```ruby
# config/initializers/recaptcha.rb
Recaptcha.configure do |config|
  config.site_key  = '6Lc6BAAAAAAAAChqRbQZcn_yyyyyyyyyyyyyyyyy'
  config.secret_key = '6Lc6BAAAAAAAAKN3DRm6VA_xxxxxxxxxxxxxxxxx'
  # Uncomment the following line if you are using a proxy server:
  # config.proxy = 'http://myproxy.com.au:8080'
end
```

### Recaptcha.with_configuration

For temporary overwrites (not thread safe).

```ruby
Recaptcha.with_configuration(site_key: '12345') do
  # Do stuff with the overwritten site_key.
end
```

### Per call

Pass in keys as options at runtime, for code base with multiple hCaptcha setups:

```ruby
recaptcha_tags site_key: '6Lc6BAAAAAAAAChqRbQZcn_yyyyyyyyyyyyyyyyy'

# and

verify_recaptcha secret_key: '6Lc6BAAAAAAAAKN3DRm6VA_xxxxxxxxxxxxxxxxx'
```
