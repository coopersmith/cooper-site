# jekyll-dotenv

A very simple Jekyll plugin to read environment variables and `.env`
files into themes.

## Installation

Add this line to your site's Gemfile:

```ruby
gem 'jekyll-dotenv'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install jekyll-dotenv

## Usage

[Read Dotenv's
documentation](https://github.com/bkeepers/dotenv/blob/master/README.md)

Add the plugin to your `_config.yml`:

```yaml
plugins:
- jekyll-dotenv
```

Export a variable:

```bash
export SOME_KEY=ITS_VALUE
```

Or put it on an `.env` file:

```bash
SOME_KEY=ITS_VALUE
```

Use in a theme:

```html
{{ site.env.SOME_KEY }}
```

## Advanced

You can create hashes from environment variables like this:

```bash
WEBMASTER_VERIFICATIONS.GOOGLE="something"
WEBMASTER_VERIFICATIONS.FACEBOOK="something"
```

They will be available in Liquid as
`site.env.WEBMASTER_VERIFICATIONS.GOOGLE` **and** as
`site.webmaster_verifications.google`, which makes jekyll-seo-tag get
its configuration from the environment.

## Attention

Be aware that your environment variables may contain personal
information like username, PATH, etc. so, for instance, `site.env` may
not be fit to be dumped whole as JSON.

## Contributing

Bug reports and pull requests are welcome on 0xacab.org at
<https://0xacab.org/sutty/jekyll/jekyll-dotenv>. This project is
intended to be a safe, welcoming space for collaboration, and
contributors are expected to adhere to the [Sutty code of
conduct](https://sutty.nl/en/code-of-conduct/).

If you like our plugins, [please consider
donating](https://donaciones.sutty.nl/en/)!

## License

The gem is available as free software under the terms of the GPL3
License.

## Code of Conduct

Everyone interacting in the jekyll-dotenv project’s codebases, issue
trackers, chat rooms and mailing lists is expected to follow the [code
of conduct](https://sutty.nl/en/code-of-conduct/).
