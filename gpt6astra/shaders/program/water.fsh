#include "/lib/settings.glsl"
#include "/lib/uniforms.glsl"
#include "/lib/math.glsl"
#include "/lib/sky.glsl"
#include "/lib/lighting.glsl"
#include "/lib/fog.glsl"
#include "/lib/water.glsl"
uniform sampler2D gtexture;
uniform float alphaTestRef;
#ifdef GEOM_ENTITY
uniform vec4 entityColor;
#endif
in vec2 vUV;
in vec2 vLightmap;
in vec4 vColor;
in vec3 vNormal;
in vec3 vPlayer;
flat in float vMaterial;
in float vChunkFade;
/* RENDERTARGETS: 0 */
void main() {
    vec4 texel = texture(gtexture,vUV)*vColor;
    if (texel.a<max(alphaTestRef,0.001)) discard;
    if (hash21(gl_FragCoord.xy)>vChunkFade) discard;
    vec3 baseNormal = safeNormalize(vNormal);
    if (!gl_FrontFacing) baseNormal = -baseNormal;
    if (vMaterial == 10000.0) {
        vec2 uv = gl_FragCoord.xy*pixelSize();
        vec3 view = (gbufferModelView*vec4(vPlayer,1.0)).xyz;
        vec3 incoming = safeNormalize(vPlayer-cameraOrigin());
        vec3 normal = waterNormal(vPlayer+cameraPosition,baseNormal);
        float backgroundDepth = texture(depthtex1,uv).r;
        vec3 behind = screenToView(uv,backgroundDepth);
        float thickness = backgroundDepth>0.999999 ? 40.0 : clamp(length(behind)-length(view),0.0,64.0);
        vec2 bend = (mat3(gbufferModelView)*(normal-baseNormal)).xy;
        vec2 refractedUV = clamp(uv+bend*0.020*WATER_REFRACTION*sat(thickness/3.0),pixelSize(),1.0-pixelSize());
        float bentDepth = texture(depthtex1,refractedUV).r;
        vec3 bentView = screenToView(refractedUV,bentDepth);
        // Do not refract foreground objects into the water behind them.
        float candidateFlag = texelFetch(colortex4,ivec2(refractedUV*vec2(textureSize(colortex4,0))),0).a;
        if (-bentView.z <= -view.z+0.02 || (candidateFlag>0.1 && candidateFlag<0.4)) refractedUV = uv;
        else if (bentDepth<0.999999) thickness = clamp(length(bentView)-length(view),0.0,64.0);
        vec3 background = texture(colortex4,refractedUV).rgb;
        vec3 transmission = exp(-thickness*vec3(0.23,0.075,0.040)/WATER_CLARITY);
        vec3 tint = mix(vec3(0.018,0.16,0.19),toLinear(vColor.rgb)*0.27,0.20);
        tint *= mix(0.12,1.0,daylight())*mix(0.10,1.0,vLightmap.y);
        // The underwater camera's absorption is handled once by the post pass.
        if (isEyeInWater == 1) transmission = vec3(1.0);
        vec3 unbent = texture(colortex4,uv).rgb;
        vec3 reflection = reflectionColor(vPlayer,normal,incoming);
        float facing = sat(dot(normal,-incoming));
        float fresnel = 0.025+0.975*pow(1.0-facing,5.0);
        if (isEyeInWater == 1) fresnel = mix(fresnel,1.0,1.0-smoothstep(0.64,0.69,facing));
        vec3 h = safeNormalize(lightDirection()-incoming);
        float glint = pow(sat(dot(normal,h)),380.0);
        vec3 specular = sunlightColor()*glint*7.0*surfaceShadow(vPlayer,baseNormal,sat(vLightmap.y));
        specular *= 1.0-rainStrength*0.8;
        if (isEyeInWater != 1) {
            reflection = foggedSurface(reflection,vPlayer);
            specular *= exp(-length(view)*0.002*FOG_DENSITY);
        }
        if (isEyeInWater == 1) {
            // A visible exit surface is a medium boundary, not an ordinary pane.
            vec3 corrected = mediumTransport(mix(background,reflection,fresnel)+specular,length(view));
            vec3 oldOpaque = mediumTransport(unbent,length(behind));
            float alpha = clamp(fresnel,0.025,1.0);
            // Correct the opaque path, but retain the destination's translucent
            // residual. Its prior transport is approximate, never silently erased.
            vec3 boundaryDelta = corrected-oldOpaque*(1.0-alpha);
            gl_FragData[0] = vec4(boundaryDelta/alpha,alpha);
        } else {
            // Destination carries all previously drawn translucent layers.
            // Use scalar transmission for stable sorted-alpha composition;
            // colored scattering conveys depth without replacing those layers.
            float scalarTransmission = dot(transmission,vec3(0.333333));
            float alpha = clamp(1.0-scalarTransmission*(1.0-fresnel),0.025,1.0);
            vec3 surface = tint*(1.0-transmission)*(1.0-fresnel)+reflection*fresnel+specular;
            // Only a refraction DELTA is added: do not composite the snapshot twice.
            vec3 bendDelta = (background-unbent)*scalarTransmission*(1.0-fresnel);
            // Keep signed HDR correction through floating-point blending. Clamp
            // only the combined scene in resolve, otherwise bright ghosts remain.
            surface += bendDelta;
            gl_FragData[0] = vec4(surface/alpha,alpha);
        }
    } else {
        // Stained glass, ice, slime, honey, modded translucent blocks, and lava.
#ifdef GEOM_ENTITY
        texel.rgb = mix(texel.rgb,entityColor.rgb,entityColor.a);
#endif
        vec3 color = shadeSurface(toLinear(texel.rgb),baseNormal,vPlayer,vLightmap,vMaterial);
        if (vMaterial == 10030.0) {
            float edge = pow(1.0-sat(dot(baseNormal,safeNormalize(cameraOrigin()-vPlayer))),5.0);
            color += atmosphere(reflect(safeNormalize(vPlayer-cameraOrigin()),baseNormal))*edge*0.20;
        }
        if (isEyeInWater != 1) color = foggedSurface(color,vPlayer);
        color = mediumTransport(color,length(vPlayer-cameraOrigin()));
        gl_FragData[0] = vec4(color,texel.a);
    }
}
