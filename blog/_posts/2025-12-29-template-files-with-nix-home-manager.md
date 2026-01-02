---
layout: post
title: Template files with Nix Home Manager
tags: config dotfiles nix home-manager template jinja
---

# Backstory

It's been a while since my last post and I did not want to leave 2025 behind without making any.

During the past year I have been gradually migrating my development and configuration file setup to
[Nix Home Manager](https://github.com/nix-community/home-manager) (aka `home-manager`).

This has not been a quick transition, but I am satisfied with the result and I believe it was worth
it.

I note the following benefits:

1. It enables me to handle all changes (program versions and configuration files) from a single
   directory.
   A single source of truth that can be easily tracked by `git`.

2. I am a fan of Nix reproducible environments and builds and I considered using `home-manager` a
   nice opportunity to familiarize myself with the language.

3. Nix packages enable me to create a predictable development environment across different machines
   (e.g. home, work, etc.), irrespective of the underlying operating system and the packages that it
   provides by default.

I finally finished the migration last month, so I thought it is a good idea to share the interesting
bits of my current setup.
Maybe someone will find it useful.

I don't know how many posts I will make about it, but let's get started.

# Template files
When sharing a `home-manager` configuration between multiple machines, a common scenario is to have
a file that needs to be slightly different in each machine.

For example, in my `vim` configuration, I want to configure the number of async workers that
`clangd` will use when launched by the `LSP` server.
In my laptop which has only 4 cores, I want to use 3 of them.
In my work computer that has 20, I want to use more (e.g. 16).

How can we utilize `home-manager` to automate this customization?

# Baseline

This post does not provide an introduction to `home-manager`.
Nevertheless, we need to agree on some necessary baseline knowledge.

`home-manager` requires a configuration file `home.nix` that typically lies in the
`$HOME/.config/home-manager` directory.
In `home.nix` we can define the files that are generated via `home-manager` by populating the
`home.file`[^1] [attribute set](https://nix.dev/manual/nix/2.24/language/syntax#attrs-literal).

[^1]: See [home-file](https://nix-community.github.io/home-manager/options.xhtml#opt-home.file).

``` nix
{
  pkgs,
  lib,
  ...
}:
{
  # Other home-manager configuration options
  ...

  # Files
  home.file = {
    # Key-value file entries
  };
}
```

Every "key-value" entry in this attribute set corresponds to a file that we want to generate in our
`$HOME` directory.

For example, if we want to generate the `$HOME/.bashrc` file, we need to add the
corresponding entry in the `home.file` attribute set.

``` nix
  ...
  home.file = {
    ".bashrc" = {
      # File options
    };
  };
  ...
```

The file options attribute set fully configures the generation of each file.
This includes the contents, setting the executable bit, any actions to perform when the file changes
and more.

This post only deals with the contents of the generated files.
For this we have two options:

- the `source` attribute, which is a [Nix
  path](https://nix.dev/tutorials/nix-language.html#file-system-paths) to a file whose content will
  populate the `home-manager` generated file
``` nix
  home.file = {
    ".bashrc" = {
      source = /. + "<absolute-path-to-source-file>";
    };
  };
```
  or
- the `text` attribute, which  is a [Nix
  string](https://nix.dev/manual/nix/2.19/language/values#type-string) defining the content of the
  `home-manager` generated file
``` nix
  home.file = {
    ".bashrc" = {
      text = ''
        # This is the content of the $HOME/.bashrc file.
      '';
    };
  };
```

# Implementation

We can create a templating layer on top of `home-manager` and programmatically
generate files with parametrizable content.

How do we do that?
We can use a template engine like [jinja](https://github.com/pallets/jinja).

For the purposes of my configuration I am using
[jinja2-cli](https://github.com/mattrobenolt/jinja2-cli), because I want to easily invoke `jinja`
from the command line.

Let's take it step by step.

##### 1. **Decouple** templating layer from the actual `home.file` attribute set.

We create an attribute set that mirrors the structure of the `home.file`. We do not want to deviate
too much from the actual "structure" that `home-manager` expects, so that the configuration and
programming logic is simpler.
```nix
  files = {
    ".bashrc" = {};
    ".inputrc" = {};
  };
```

##### 2. **Modify** each "key-value" file entry using `builtins.mapAttrs`[^2].

[^2]: See [builtins.mapAttrs](https://nix.dev/manual/nix/2.28/language/builtins.html#builtins-mapAttrs).

Currently the values of the file entries are empty.
We need to populate these attribute sets, so that they are valid `home-manager` file entries.

As already mentioned, to set the file content, we need to define either the `source` or the `text`
attribute.

For **non-template files** the `map` function is simple:
```nix
  makeSimple = builtins.mapAttrs (
    path: options: {
      source = /. + "<absolute-path-to-config-files>/${path}";
    }
  );
```

You may wonder what this `<absolute-path-to-config-files>` is.

In my configuration, I have created a directory inside `$HOME/.config/home-manager` that mirrors the
directory structure of the `$HOME` directory.
This allows referring to the `home-manager` source file and the actual generated location with the
same relative path and permits using `lib.mapAttrs` to modify the initial `files` attribute set.

For **template files** we need to provide some more information (i.e. the `jinja` data).
We do so by adding a `data` attribute.

```nix
  files = {
    ".bashrc" = {};
    ".inputrc" = {};
    ".vimrc" = {
        "data" = "<absolute-path-to-json-data-file>";
    };
  };
```

Now, we define the `map` function.

```nix
  makeTemplates = builtins.mapAttrs (
    path: options: {
      text = template {
        src = /. + "<absolute-path-to-config-files>/${path}";
        data = /. + "${options.data}";
      };
    }
  );
```

We can see that we rely on the output of a helper function: `template`. This function in its
simplest form[^3] takes two paths as arguments:

[^3]: See [Extensions](#extensions).

1. `src` is the path to the template file.
2. `data` is the path to a file containing data in `JSON` format.

The return value of this function has to be a Nix string that is then used as the value of the
`text` attribute.

We define the `template` function as follows:

``` nix
  template =
    { src, data }:
    let
      out = pkgs.runCommand "" { buildInputs = [ pkgs.jinja2-cli ]; } ''
        # If jinja2 fails (e.g. missing keys), just use the input file unchanged.
        jinja2 --format=json ${src} <<< "$(< ${data})" -o $out 2>/dev/null || cp ${src} $out
      '';
    in
    builtins.readFile out;
```

How does the `template` function work?

The function uses `pkgs.runCommand`[^4] to create a [Nix
derivation](https://nix.dev/manual/nix/2.22/language/derivations).
In our use case we only want to create one single file that we can then read from.

[^4]: See
    [pkgs.runCommand](https://ryantm.github.io/nixpkgs/builders/trivial-builders/#trivial-builder-runCommand).


- We run `jinja2` on the `src` file using the `data` in `json` format.
- We write the output to the `$out` file (**note:** the `$out` variable is used internally by Nix and points
   to the generated derivation file).\\
   If anything fails during the `jinja2` call we copy the original template file content to the
   output file directly.
- Finally, we read the output file and return its content as a Nix string.

##### 3. **Merge** simple and template files in one attribute set.

We are almost done.
We need to map **non-template files** with the `makeSimple` function and **template files** with the
`makeTemplate` function.
The differentiating factor is the presence of the `data` attribute and we use that to create a
filter.

```nix
  simpleFile = (lib.filterAttrs (path: options: !options ? data) files);
  templateFiles = (lib.filterAttrs (path: options: options ? data) files);

  result = makeSimple simpleFiles // makeTemplates templateFiles;
```

##### 4. **Assign** the resulting attribute set to `home.file`.

``` nix
{
  pkgs,
  lib,
  ...
}:
let
  files = ...;

  template = ...;

  makeSimple = ...;
  makeTemplate = ...;

  simpleFiles = ...;
  templateFiles = ...;

  result = ...;
in
{
  # Other home-manager configuration options.
  ...

  # Files
  home.file = result;
}
```

That's it. We have successfully configured `home-manager` to generate files from templates.

# In practice

At the [beginning](#template-files) of this post I mentioned how one my use cases for template files
is specifying a different number of async workers for `clangd` in my `LSP` configuration in `vim`.

How does this look like based on the described setup?

`$HOME/.config/home-manager/home.nix`:
```nix
  ...
  files = {
    ...
    ".vim/variables.vim" = {
      data = "/home/<username>/.local/share/home-mananger/data.json";
    };
    ...
  };
  ...
```

`$HOME/.config/home-manager/files/.vim/variables.vim`:
```vimscript
autocmd User LspSetup call LspAddServer([
    \   #{
    \       name: 'clangd',
    \       filetype: ['c', 'cpp'],
    \       path: 'clangd',
    \       args: ['--clang-tidy', '-j', {% raw %}{{ data.nproc * 80 // 100 }}{% endraw %}]
    \  },
    ...
```

`$HOME/.local/share/home-manager/data.json`:
```json
{
  "data": {
    "nproc": 4
  }
}
```

It is that simple[^5].

[^5]: The file `$HOME/.local/share/home-manager/data.json` is automatically generated, but that
    deserves a post of its own.

# Extensions

Nix enables extensive configuration, so we could certainly improve on the described setup if we
needed to. Here are some ideas:

- The `template` function in its current form requires two file paths as parameters.
  We may desire some more flexibility.\\
  For example, we may want to pass the template file as a Nix string.
  Or we may want to pass the `data` in a different format (e.g. as a Nix attribute set, a
  Nix string, etc.).\\
  We should be able to easily achieve that with a few small changes in the `template` function in
  order to correctly parse and transform parameters of different types.

- In a previous iteration of my configuration I was generating multiple files from a single template
  file by iterating over a `JSON` array.\\
  I now have no use for it, so I have not included it in this post, but it is certainly doable with
  a few changes.
