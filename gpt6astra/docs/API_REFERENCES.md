# API-only reference log

Date of work: **2026-09-05**. Target: **Minecraft Java 1.21.11 / Iris**.

This list records documentation, not borrowed visual implementations. Searches
were restricted to interface questions. Existing shaderpacks and visual tutorial
implementations were not opened, downloaded or used. Search results that named
shaderpacks or returned tutorials were not used as implementation sources.

## Iris shader API reference

The Iris shader documentation at `shaders.properties` was used for these API facts:

| Topic | API reference |
| --- | --- |
| Programs, fallback and opaque/deferred/translucent separation | `https://shaders.properties/current/reference/programs/gbuffers/` |
| Prepare stage | `https://shaders.properties/current/reference/programs/prepare/` |
| Rendering settings, per-target blending, shadow culling, beacon depth | `https://shaders.properties/current/reference/shadersproperties/rendering/` |
| Target formats, sizes, profiles and property categories | `https://shaders.properties/current/reference/shadersproperties/overview/` |
| Buffer-format symbolic directives; standalone block-comment requirement | `https://shaders.properties/current/reference/constants/buffer_format/` |
| Shader option declaration | `https://shaders.properties/current/reference/shadersproperties/shader_settings/` |
| Feature requirements | `https://shaders.properties/current/reference/shadersproperties/flags/` |
| Feature-gated chunk fade; -1 outside terrain; Minecraft 1.21.11 relevance | `https://shaders.properties/current/reference/uniforms/iris/mc_chunkFade/` |
| Color attachments, gbuffers sampling restrictions and flipping | `https://shaders.properties/current/reference/buffers/colortex/` |
| Depth buffers, translucent and hand inclusion | `https://shaders.properties/current/reference/buffers/depthtex/` |
| Opaque/all-caster shadow depth buffers | `https://shaders.properties/current/reference/buffers/shadowtex/` |
| Iris `ftransform()` patching contract | `https://shaders.properties/current/reference/attributes/ftransform/` |
| Existing vertex color/AO channel | `https://shaders.properties/current/reference/attributes/gl_Color/` |

The required feature flags are `ENTITY_TRANSLUCENT` and `PER_BUFFER_BLENDING`.
`FADE_VARIABLE` is optional and guarded. No particular Iris release number is
fabricated; use a release built for the user's exact Minecraft version.

## Native offline verification API

The optional local GPU tool uses a hidden Windows window only to create an
OpenGL compatibility context. It does not open a browser, launch Minecraft or
inspect installed shaderpacks.

- Microsoft WGL context API:
  `https://learn.microsoft.com/en-us/windows/win32/api/wingdi/nf-wingdi-wglcreatecontext`
- Microsoft rendering-context creation contract (window/DC/pixel format):
  `https://learn.microsoft.com/en-us/windows/win32/opengl/creating-a-rendering-context-and-making-it-current`
- Khronos OpenGL shader compilation API:
  `https://registry.khronos.org/OpenGL-Refpages/gl4/html/glCreateShader.xhtml`
- Khronos framebuffer completeness API:
  `https://registry.khronos.org/OpenGL-Refpages/gl4/html/glCheckFramebufferStatus.xhtml`

No web-derived bitmap assets, cubemaps, LUTs, material textures, shader libraries,
noise images, screenshots, code templates or external binary dependencies ship
inside the shaderpack.
