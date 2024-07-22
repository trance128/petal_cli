# Component Importer

This project started as a way to import petal components into a project, but will be expanded to cover other components libraries also.  Currently adding support for salad ui

This tool can currently be used to import all salad ui components with the --salad flag:
```
mix petal.install --salad
```
however, this doesn't yet support individual components and tailwind colours are not correctly being added, so that step's omitted currently
Currently, these 3 tailwind plugins are still added:
- tailwindcss-animate
    - the tailwindcss-animate js file is added in your project at [assets/js/tailwindcss-animate.js]
- tailwindcss-typography
- tailwindcss/forms

tailwind-css animate hasn't been tested yet

# Petal CLI

Components are installed into your project's *lib/[app_name_web]/components/* , directory giving you full control over the code

You can now modify and customize components to meet your unique needs

## Project Motivation

shadcn-ui set the gold standard for component libraries.  They provide beautiful components, and still allow you full, easy control and customization.

It's time to bring those same capabilities to Phoenix and LiveView, starting with the beautiful components from Petal Framework

## Installation

You can install Petal CLI either globally or as a project dependency.

### Global Installation

To install Petal CLI globally, use the following command:

```
mix archive.install hex petal_cli
```

### Local Installation

To install Petal CLI as a project dependency, add it to your mix.exs file:

```
def deps do
  [
    {:petal_cli, "~> 0.1", only: :dev}
  ]
end
```

Then run:
```
mix deps.get
```

## Usage
```
mix petal.install [options] [component names]
```

### Options
- --salad               : installs salad ui, all components
- --install-all, -a     : Runs setup, and installs all petal components
- --setup, -s           : Perform petal setup without installing components
- --list, -l            : List available petal components
- --help, -h            : Print the help message
- --no-alpine           : Skip adding Alpine.js
- --no-rename           : Skip renaming components (keep original namespaces)
- --no-tailwind-config  : Skip updating Tailwind configuration

### Examples
```
mix petal.install --salad
mix petal.install --install-all
mix petal.install -a --no-alpine --no-rename
mix petal.install --setup
mix petal.install avatar menu
mix petal.install --setup --no-alpine avatar menu
```
## Features
1. Component Installation: Install individual Petal Components or all components at once.
2. Setup: Perform necessary setup for using Petal Components in your Phoenix project.
3. Customization: Options to skip certain setup steps (Alpine.js, Tailwind config updates, component 
renaming).

## Important Notes

- *File Locations*: This tool assumes all files are in the standard Phoenix project structure.
- *Heroicons Dependency*: Petal Components depends on an older version of Heroicons. You may need to add override: true to your mix.exs if you're also importing Heroicons directly:
```
{:heroicons, "~> 2.x", override: true}
```
- *Component Overwriting*:
    - Using --install-all will overwrite previously installed components without prompting.
    - When installing individual components, you'll be asked if you want to overwrite existing files.
- *Component Dependencies*:
    - Installing individual components will also install their dependencies.
    - If a dependency file already exists, it will be skipped to prevent overwriting customizations.
    - To overwrite an existing dependency, you need to install it manually.

## What It Does
1. *Copy Petal CSS*: Copies the Petal default CSS file to your project.
2. *Update CSS Imports*: Adds the necessary import statement to your app.css file.
3. *Add Alpine.js*: Adds Alpine.js script tags to your root layout file (unless --no-alpine is used).
4. *Update Tailwind Config*: Modifies your Tailwind configuration to include Petal color palette (unless --no-tailwind-config is used).
5. *Copy Components*: Copies selected (or all) Petal Components to your project, renaming them to fit your project's namespace (unless --no-rename is used).

## Contributing
Contributions are welcome! Please feel free to submit a Pull Request.

## License
This project is licensed under the MIT License.

