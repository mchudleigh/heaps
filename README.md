# Heaps
_Heaps Data-oriented fork_

This is a fork of the Heaps game engine. While the creators have huge amount of respect for the Heaps project, there are a few fundamental differences in design that are leading to this fork.

This project will strive to be different than Heaps in the following ways:
- Only support open specifications and open source tools (GLTF will be the primary 3D format)
- Remove compatibility with some platforms (primarily Flash) and focus on Web and native desktop
- Rework the rendering engine to be more compatible with next-gen APIs like Vulkan and WebGPU
- Supoort new open formats like WebAssembly and WebGPU
- Replace the Object-Oriented scene graph with a Data-Oriented system (specific design decisions TBD).

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
