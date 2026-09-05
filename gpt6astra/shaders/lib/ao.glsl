#ifndef TIDELUME_AO
#define TIDELUME_AO
float contactOcclusion(vec2 uv, vec3 view, vec3 normal) {
#ifdef AMBIENT_OCCLUSION
    float distanceToEye = -view.z;
    if (distanceToEye>96.0) return 1.0;
    float radius = 0.72;
    float radiusPixels = clamp(radius*gbufferProjection[1][1]*viewHeight/(max(distanceToEye,0.1)*2.0),2.0,48.0);
    float obstruction = 0.0;
    for (int i=0;i<8;++i) {
        float a = float(i)*2.39996323;
        vec2 tapUV = uv+vec2(cos(a),sin(a))*sqrt((float(i)+0.5)/8.0)*radiusPixels*pixelSize();
        if (any(lessThan(tapUV,vec2(0.0))) || any(greaterThan(tapUV,vec2(1.0)))) continue;
        float d = texture(depthtex0,tapUV).r;
        if (d>=0.999999) continue;
        vec3 sampleView = screenToView(tapUV,d);
        vec3 delta = sampleView-view;
        float len = length(delta);
        float angle = max(dot(normal,delta/max(len,0.001))-0.14,0.0);
        obstruction += angle*(1.0-smoothstep(radius*0.3,radius*2.0,len));
    }
    float fade = 1.0-smoothstep(64.0,96.0,distanceToEye);
    return 1.0-sat(obstruction*AO_STRENGTH*0.22)*fade;
#else
    return 1.0;
#endif
}
#endif
