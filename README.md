octopress-plugins
=================

Octopress plugins

# Spaceless block tag

This plugin strips all white spaces between html tags.

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

    </body>
</html>


{% endspaceless %}
```

result in:

```html
<html><head><title>spaceless sample html</title></head><body><h1>Hello world!</h1></body></html>
```