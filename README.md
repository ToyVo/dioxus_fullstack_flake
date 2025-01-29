This project is just the jumpstart template with fullstack and router from using `dx new` and building it on nix(os)

Of note: the version of wasm-bindgen in Cargo.lock must match wasm-bindgen-cli from nix. Right now the latest 0.2.100 is on nixos-unstable, but an override might be needed in case they differ for whatever reason.
we currently have an override for dioxus-cli because nixos-unstable is on 0.6.0 which requires 0.2.97 of wasm-bindgen
0.6.2 has changes to make building within nix easier

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
```bash
nix run nixpkgs#tailwindcss -- -i ./input.css -o ./assets/tailwind.css --watch
```

### Serving Your App

Run the following command in the root of your project to start developing with the default platform:

```bash
dx serve --platform web
```
```bash
nix run github:CathalMullan/nixpkgs/dioxus-cli-v0.6.2#dioxus-cli -- serve --platform web
```

To run for a different platform, use the `--platform platform` flag. E.g.
```bash
dx serve --platform desktop
```
```bash
nix run github:CathalMullan/nixpkgs/dioxus-cli-v0.6.2#dioxus-cli -- serve --platform desktop
```

