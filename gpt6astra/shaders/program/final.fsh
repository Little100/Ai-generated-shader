#include "/lib/settings.glsl"
#include "/lib/uniforms.glsl"
#include "/lib/math.glsl"
uniform sampler2D colortex0;
in vec2 vUV;
void main() {
    vec2 px = pixelSize();
    vec3 center = texture(colortex0,vUV).rgb;
#ifdef EDGE_AA
    vec3 left = texture(colortex0,clamp(vUV-vec2(px.x,0),px*0.5,1.0-px*0.5)).rgb;
    vec3 right = texture(colortex0,clamp(vUV+vec2(px.x,0),px*0.5,1.0-px*0.5)).rgb;
    vec3 down = texture(colortex0,clamp(vUV-vec2(0,px.y),px*0.5,1.0-px*0.5)).rgb;
    vec3 up = texture(colortex0,clamp(vUV+vec2(0,px.y),px*0.5,1.0-px*0.5)).rgb;
    float l = luminance(left), r = luminance(right), d = luminance(down), u = luminance(up), c = luminance(center);
    float range = max(max(l,r),max(u,max(d,c)))-min(min(l,r),min(u,min(d,c)));
    if (range>max(0.045,c*0.10)) {
        vec2 gradient = vec2(r-l,u-d);
        float magnitude = length(gradient);
        if (magnitude>0.001) {
            vec2 alongEdge = vec2(-gradient.y,gradient.x)/magnitude*px;
            vec3 a = texture(colortex0,clamp(vUV-alongEdge*0.60,px*0.5,1.0-px*0.5)).rgb;
            vec3 b = texture(colortex0,clamp(vUV+alongEdge*0.60,px*0.5,1.0-px*0.5)).rgb;
            float balance = 1.0-sat(abs((l+r+u+d)*0.25-c)/max(range,0.001));
            center = mix(center,(a+b)*0.5,0.55*balance);
        }
    }
#endif
    float dither = (hash21(gl_FragCoord.xy)-0.5)/255.0;
    gl_FragData[0] = vec4(sat(center+dither),1.0);
}
