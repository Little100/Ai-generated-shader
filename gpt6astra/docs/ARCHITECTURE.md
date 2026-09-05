# Tidelume 0.1.2 — rendering architecture

## Ownership and provenance

The workspace was empty at the start. No pre-existing shaderpack, shader tutorial
implementation, material map, noise asset, or third-party visual template was
read or incorporated. Public API documentation was used to establish names,
stages, uniforms, attributes, feature flags and configuration syntax. All visual
combinations and implementations were authored here. Standard graphics math is
not claimed as a newly invented technique.

## Spaces

- `view`: ordinary camera view space. `gbufferProjectionInverse` reconstructs it.
- `player`: camera-relative world axes, including any inverse-view translation.
- `world`: `player + cameraPosition`, for stable wind and water phases.
- `shadow`: the light camera's projection plus a shared radial warp.

Vertex deformation is applied to the lighting position and clip position together.
The shadow pass calls the same wind function with the same plant anchor rule.
Opaque hands are explicitly flagged and excluded from ordinary-depth SSAO/fog/SSR
interpretation, since their clip Z does not follow world geometry's projection.

## Color and buffers

Texture/vertex albedo uses an approximate power-2.2 transfer to linear light.
Lighting, scattering and blending remain linear HDR. A single display transform
is applied by the tone-map pass. This is an artistic linear workflow, not exact
colorimetric sRGB transfer or a named film emulation.

| Buffer | Format / size | Meaning |
| --- | --- | --- |
| `colortex0` | RGBA16F / full | Current scene; display-referred only after composite5 |
| `colortex1` | RGBA16F / full | World normal remapped to 0–1; A: 0 clear, .25 hand, 1 surface |
| `colortex4` | RGBA16F / full | Immutable opaque snapshot before camera-medium absorption; A = copied surface flag |
| `colortex5` | RGBA16F / half each axis | Extracted / vertically blurred highlights |
| `colortex6` | RGBA16F / half each axis | Horizontal highlight blur |
| `colortex7` | RGBA16F / half each axis | Integrated rays, A = linear view distance |
| `shadowcolor0` | RGBA8 / shadow size | Straight transmission tint and coverage |

Only necessary targets are written in each pass. Opaque data attachments explicitly
disable blending. Transparent / overlay programs write scene color only. Snapshot
4 is never written by a shader that samples it. Composite read/write pairs use
Iris' normal fullscreen buffer flipping; half-size and full-size attachments are
never mixed in one framebuffer.

## Pass sequence

1. **shadow** — camera-relative caster transform, shared wind and radial projection.
   Water does not cast opaque shadows. Stained glass writes transmission color.
   Shadow rendering is disabled in the Nether and End.
2. **prepare** — initialize the procedural sky in scene color before opaque and
   depthless forward contributions. Vanilla sky programs discard; they do not
   overwrite the initialized background. Clouds are sky-background integration,
   not geometry-intersecting participating media.
3. **gbuffers (opaque)** — forward HDR lighting, textured alpha rejection, world
   normal metadata; pre-deferred effects are not independently air-fogged.
4. **deferred** — SSAO and air fog for world geometry. Preserve existing sky and
   depthless contributions. Capture unabsorbed snapshot 4. Resolve opaque camera-
   medium transport at that layer's own depth into scene color.
5. **gbuffers (post-deferred translucent)** — explicit `GEOM_FORWARD` programs
   receive their own fog/medium. Attachment policy (`GEOM_TRANSLUCENT`) does not
   determine fog timing. Water uses own-contribution + destination-transmission
   alpha blending, not wholesale opaque-snapshot replacement. Underwater exit
   interfaces explicitly resolve the water segment before the air background.
6. **composite** — integrate low-resolution shadow-map light shafts into target 7.
7. **composite1** — depth-aware shaft upsample; apply blindness/darkness to the HDR
   scene. Incompatible shaft samples have zero weight; no epsilon resurrects them.
8. **composite2** — extract highlights from already medium/status-resolved HDR.
9. **composite3 / composite4** — normalized separable highlight diffusion.
10. **composite5** — combine bloom, exposure, original rational luminance shoulder,
    bounded highlight chroma, saturation, vignette, and display transfer.
11. **final** — single-frame directional edge smoothing and sub-LSB spatial dither.

There is no temporal history buffer, persistent accumulation, downloaded noise,
compute-shader dependency, texture-pack dependency, or framebuffer self-sampling.

## Approximations worth preserving explicitly

- Water's above-surface scalar transmission favors sorted-alpha stability over
  per-channel physical absorption of every transparent layer. Refraction modifies
  only the opaque snapshot difference. Signed corrections survive RGBA16F blending
  and are clamped only after full-scene composition. Underwater boundary resolve
  corrects the opaque background path and retains the destination translucent
  residual; it cannot reconstruct each transparent layer's separate air path.
- SSR is linear view-space marching, with analytic sky fallback and edge fade.
  Hand flags are copied to snapshot 4 alpha and fetched without interpolation
  (gbuffers cannot sample colortex0–3 as attachments). Hand-flagged coordinates
  are rejected because a matching hand-free color source
  is not available. Refraction similarly rejects a foreground/hand candidate.
- Sun/moon visibility uses the lightmap as a leak-suppression/far-shadow fallback.
- Light shafts integrate shadow visibility, not multiple scattering. Rain and
  light elevation modulate their appearance. They are intentionally low contrast.
- Hand light is a distance-only, non-shadowed max(mainhand, offhand) approximation.
- Block emission uses explicit vanilla IDs and texture luminance, not LabPBR.
- Depthless pre-deferred effects share the opaque/background medium distance.
  A submerged outer beacon halo can therefore attenuate too much. Separately
  transporting these contributions is a known first-version limitation, not a
  claimed solved edge case.
- The local WGL fixture does not reproduce Iris' bytecode/GLSL rewriting, automatic
  framebuffer clears/flips, entity callbacks or vanilla block model geometry.

## Original design constants

The radial projection uses `r / (0.28 + 0.72*r)`, shared on writer and receiver.
The tone-map luminance shoulder is:

```text
Y_out = Y * (1 + 0.10*Y) / (0.82 + 1.16*Y + 0.10*Y^2)
```

These chosen visual parameters, four water wave trains, sky colors, cloud density
combination, End ribbon geometry and material classes belong to this authored
implementation. They are not pulled from a named shaderpack.
