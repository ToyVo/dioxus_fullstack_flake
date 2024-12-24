This project is just the jumpstart template with fullstack and router from using `dx new` and building it on nix(os)

Of note: the version of wasm-bindgen in Cargo.lock must match wasm-bindgen-cli from nix, so we are using an override to get the correct version
we currently also have an override for dioxus-cli because 0.6.0 which is available on nixos-unstable right now requires 0.2.97 of wasm-bindgen so we use 0.6.1 matching dioxus itself which wants 0.2.99 of wasm-bindgen
dioxus-cli then expects the wasm-bindgen executable to be at `$XDG_DATA_HOME/dioxus/wasm-bindgen/wasn-bindgen-${wasm-bindgen.version}`

# TODO
The next logical step is to make sure this flake can also build the desktop platform, maybe mobile apps

# Development

Your new jumpstart project includes basic organization with an organized `assets` folder and a `components` folder.
If you chose to develop with the router feature, you will also have a `views` folder.

### Tailwind
1. Install npm: https://docs.npmjs.com/downloading-and-installing-node-js-and-npm
2. Install the Tailwind CSS CLI: https://tailwindcss.com/docs/installation
3. Run the following command in the root of the project to start the Tailwind CSS compiler:

```bash
npx tailwindcss -i ./input.css -o ./assets/tailwind.css --watch
```

### Serving Your App

Run the following command in the root of your project to start developing with the default platform:

```bash
dx serve --platform web
```

To run for a different platform, use the `--platform platform` flag. E.g.
```bash
dx serve --platform desktop
```

