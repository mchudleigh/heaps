# Heaps
_Heaps Feature Playground_

This is a fork of the Heaps game engine and mostly used as a test bed for some advanced new features.

The features being explored are:
- GLTF integration
- Arbitrary collision of convex objects
- Rigid body dynamics
- Anything I need to support the above, or otherwise interests me

The project is mostly defunct at this point. Future work will be done on a new Haxe based 3D engine. However if anyone stumbles on this and is interested in trying to integrate this into
mainline Heaps let me know.

[Heaps Homepage](https://heaps.io)


Original Heaps Readme Below:
----------------------------

**Heaps** is a cross platform graphics engine designed for high performance games. It's designed to leverage modern GPUs that are commonly available on desktop, mobile and consoles.

Heaps is currently working on:
- HTML5 (requires WebGL)
- Mobile (iOS, tvOS and Android)
- Desktop with OpenGL (Win/Linux/OSX) or DirectX (Windows only)
- Consoles (Nintendo Switch, Sony PS4, XBox One - requires being a registered developer)
- Flash Stage3D


Community
---------

Ask questions or discuss on <https://community.heaps.io>

Chat on Discord <https://discord.gg/sWCGm33> or Gitter <https://gitter.im/heapsio/Lobby>

Samples
-------

In order to compile the samples, go to the `samples` directory and run `haxe gen.hxml`, this will generate a `build` directory containing project files for all samples.

To compile:
- For JS/WebGL: run `haxe [sample]_js.hxml`, then open `index.html` to run
- For [HashLink](https://hashlink.haxe.org): run `haxe [sample]_hl.hxml` then run `hl <sample>.hl` to run (will use SDL, replace `-lib hlsdl` by `-lib hldx` in hxml to use DirectX)
- For Flash: run `haxe [sample]_swf.hxml`, then open `<sample>.swf` to run
- For Consoles, contact us: nicolas@haxe.org

Project files for [Visual Studio Code](https://code.visualstudio.com/) are also generated.

Get started!
------------
* [Installation](https://heaps.io/documentation/installation.html)
* [Live samples with source code](https://heaps.io/samples/)
* [Documentation](https://heaps.io/documentation/home.html)
* [API documentation](https://heaps.io/api/)
