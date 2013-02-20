octopress-plugins
=================

Octopress plugins

# Spaceless block tag

This plugin strips all white spaces between html tags. And pre tags contents will be kept as it is.

## prerequisite

This plugin requires [uuid](https://rubygems.org/gems/uuid).

```sh
gem install uuid
```

or add the following line to you Gemfile.

```sh
# Gemfile
gem "uuid"
```

and then:

```sh
bundle install
```

## usage

```html
{% spaceless %}

<!DOCTYPE html>
<html>
    <head>
        <title>spaceless sample html</title>
    </head>
    <body>

        <h1>Hello world!</h1>

        <pre>
            <code>
Hello world!

  Here's sample code

            </code>
        </pre>
    </body>
</html>


{% endspaceless %}
```

result in:

```html
<!DOCTYPE html><html><head><title>spaceless sample html</title></head><body><h1>Hello world!</h1><pre>
    <code>

Hello world!

  Here's sample code

    </code>
</pre>
</body></html>
```