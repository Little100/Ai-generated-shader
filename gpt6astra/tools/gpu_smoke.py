"""Windows hidden-window WGL smoke test for ORIGINAL Tidelume sources.
No Minecraft files or third-party shaderpacks are opened. This is NOT an Iris
integration test. Optional NumPy/Pillow are needed for synthetic-scene previews.
A hidden window supplies a compatibility OpenGL context; it is never shown.
"""
from __future__ import annotations
import argparse
import ctypes as C
from ctypes import wintypes as W
import json
import sys
from pathlib import Path
from validate import SHADERS, ROOT, configure, expand, profiles, source_fingerprint
U=C.c_uint; I=C.c_int; F=C.c_float; P=C.c_void_p
class PFD(C.Structure):
    _fields_=[('nSize',W.WORD),('nVersion',W.WORD),('dwFlags',W.DWORD),
        *[(n,W.BYTE) for n in ['iPixelType','cColorBits','cRedBits','cRedShift','cGreenBits','cGreenShift','cBlueBits','cBlueShift','cAlphaBits','cAlphaShift','cAccumBits','cAccumRedBits','cAccumGreenBits','cAccumBlueBits','cAccumAlphaBits','cDepthBits','cStencilBits','cAuxBuffers','iLayerType','bReserved']],
        ('dwLayerMask',W.DWORD),('dwVisibleMask',W.DWORD),('dwDamageMask',W.DWORD)]
class Context:
    def __init__(self):
        if sys.platform!='win32':raise RuntimeError('WGL test requires Windows')
        self.user=C.WinDLL('user32',use_last_error=True)
        self.gdi=C.WinDLL('gdi32',use_last_error=True)
        self.dll=C.WinDLL('opengl32',use_last_error=True)
        def win(dll,name,ret,*args):
            fn=getattr(dll,name);fn.restype=ret;fn.argtypes=list(args);return fn
        self.destroy=win(self.user,'DestroyWindow',W.BOOL,W.HWND)
        self.release=win(self.user,'ReleaseDC',I,W.HWND,W.HDC)
        create=win(self.user,'CreateWindowExW',W.HWND,W.DWORD,W.LPCWSTR,W.LPCWSTR,W.DWORD,I,I,I,I,W.HWND,W.HMENU,W.HINSTANCE,P)
        # No WS_VISIBLE, no ShowWindow, no interactive desktop UI.
        self.window=create(0,'STATIC','Tidelume offline GPU test',0x04000000|0x02000000,0,0,64,64,None,None,None,None)
        if not self.window:raise C.WinError(C.get_last_error())
        self.dc=win(self.user,'GetDC',W.HDC,W.HWND)(self.window)
        descriptor=PFD();descriptor.nSize=C.sizeof(PFD);descriptor.nVersion=1
        descriptor.dwFlags=4|32|1;descriptor.cColorBits=32;descriptor.cDepthBits=24;descriptor.cStencilBits=8
        choose=win(self.gdi,'ChoosePixelFormat',I,W.HDC,C.POINTER(PFD))
        setformat=win(self.gdi,'SetPixelFormat',W.BOOL,W.HDC,I,C.POINTER(PFD))
        if not setformat(self.dc,choose(self.dc,C.byref(descriptor)),C.byref(descriptor)):raise C.WinError(C.get_last_error())
        self.rc=win(self.dll,'wglCreateContext',P,W.HDC)(self.dc)
        self.current=win(self.dll,'wglMakeCurrent',W.BOOL,W.HDC,P)
        self.deletecontext=win(self.dll,'wglDeleteContext',W.BOOL,P)
        if not self.rc or not self.current(self.dc,self.rc):raise C.WinError(C.get_last_error())
        self.getproc=win(self.dll,'wglGetProcAddress',P,C.c_char_p)
        self.cache={}
        self.getstring=self.fn('glGetString',C.c_char_p,U)
        self.info={key:self.getstring(enum).decode(errors='replace') for key,enum in [('vendor',0x1F00),('renderer',0x1F01),('version',0x1F02),('glsl',0x8B8C)]}
    def fn(self,name,ret,*args):
        if name in self.cache:return self.cache[name]
        address=self.getproc(name.encode())
        if address and address not in {1,2,3,C.c_void_p(-1).value}:
            fn=C.WINFUNCTYPE(ret,*args)(address)
        else:
            fn=getattr(self.dll,name);fn.restype=ret;fn.argtypes=list(args)
        self.cache[name]=fn;return fn
    def close(self):
        self.current(None,None);self.deletecontext(self.rc);self.release(self.window,self.dc);self.destroy(self.window)
    def program(self,vertex,options):
        stages=[]
        for kind,path in [(0x8B31,vertex),(0x8B30,vertex.with_suffix('.fsh'))]:
            source=configure(expand(path),options,True).encode()
            shader=self.fn('glCreateShader',U,U)(kind)
            ptr=C.c_char_p(source);length=I(len(source))
            self.fn('glShaderSource',None,U,I,C.POINTER(C.c_char_p),C.POINTER(I))(shader,1,C.byref(ptr),C.byref(length))
            self.fn('glCompileShader',None,U)(shader)
            ok=I();self.fn('glGetShaderiv',None,U,U,C.POINTER(I))(shader,0x8B81,C.byref(ok))
            if not ok.value:
                log=C.create_string_buffer(32768)
                self.fn('glGetShaderInfoLog',None,U,I,C.POINTER(I),P)(shader,len(log),None,log)
                raise RuntimeError(f'{path}: {log.value.decode(errors="replace")}')
            stages.append(shader)
        program=self.fn('glCreateProgram',U)()
        for shader in stages:self.fn('glAttachShader',None,U,U)(program,shader)
        self.fn('glLinkProgram',None,U)(program)
        ok=I();self.fn('glGetProgramiv',None,U,U,C.POINTER(I))(program,0x8B82,C.byref(ok))
        if not ok.value:
            log=C.create_string_buffer(32768);self.fn('glGetProgramInfoLog',None,U,I,C.POINTER(I),P)(program,len(log),None,log)
            raise RuntimeError(f'{vertex}: {log.value.decode(errors="replace")}')
        for shader in stages:self.fn('glDeleteShader',None,U)(shader)
        return program
    def check(self,label):
        error=self.fn('glGetError',U)()
        if error:raise RuntimeError(f'OpenGL error 0x{error:04x} after {label}')

def render_previews(ctx, programs, width, height):
    import numpy as np
    from PIL import Image, ImageDraw
    gl=ctx.fn
    out=ROOT/'build'/'previews';out.mkdir(parents=True,exist_ok=True)
    identity=np.eye(4,dtype=np.float32)
    def normalize(a):return np.array(a,dtype=np.float32)/np.linalg.norm(a)
    def lookat(eye,target):
        f=normalize(np.array(target)-eye);s=normalize(np.cross(f,[0,1,0]));u=np.cross(s,f)
        m=np.eye(4,dtype=np.float32);m[0,:3]=s;m[1,:3]=u;m[2,:3]=-f
        m[:3,3]=-m[:3,:3]@eye;return m
    def translate(v):
        m=identity.copy();m[:3,3]=v;return m
    def perspective():
        n,f=0.05,256.;a=1/np.tan(np.radians(68)/2);m=np.zeros((4,4),np.float32)
        m[0,0]=a/(width/height);m[1,1]=a;m[2,2]=-(f+n)/(f-n);m[2,3]=-2*f*n/(f-n);m[3,2]=-1;return m
    def ortho():
        m=identity.copy();m[0,0]=m[1,1]=1/64.;m[2,2]=-2/179.9;m[2,3]=-180.1/179.9;return m
    def matrix(mode,m):
        gl('glMatrixMode',None,U)(mode);a=np.ascontiguousarray(m.T,dtype=np.float32)
        gl('glLoadMatrixf',None,P)(a.ctypes.data)
    def texture(w,h,depth=False,pixels=None):
        name=U();gl('glGenTextures',None,I,C.POINTER(U))(1,C.byref(name));gl('glBindTexture',None,U,U)(0x0DE1,name.value)
        for key,val in [(0x2801,0x2600 if depth else 0x2601),(0x2800,0x2600 if depth else 0x2601),(0x2802,0x812F),(0x2803,0x812F)]:gl('glTexParameteri',None,U,U,I)(0x0DE1,key,val)
        gl('glTexImage2D',None,U,I,I,I,I,I,U,U,P)(0x0DE1,0,0x8CAC if depth else 0x881A,w,h,0,0x1902 if depth else 0x1908,0x1406,None if pixels is None else pixels.ctypes.data)
        return name.value
    fbo=U();gl('glGenFramebuffers',None,I,C.POINTER(U))(1,C.byref(fbo))
    def attach(colors,depth=0,w=width,h=height):
        gl('glBindFramebuffer',None,U,U)(0x8D40,fbo.value)
        for i in range(3):gl('glFramebufferTexture2D',None,U,U,U,U,I)(0x8D40,0x8CE0+i,0x0DE1,colors[i] if i<len(colors) else 0,0)
        gl('glFramebufferTexture2D',None,U,U,U,U,I)(0x8D40,0x8D00,0x0DE1,depth,0)
        buffers=(U*len(colors))(*[0x8CE0+i for i in range(len(colors))]);gl('glDrawBuffers',None,I,C.POINTER(U))(len(colors),buffers)
        status=gl('glCheckFramebufferStatus',U,U)(0x8D40)
        if status!=0x8CD5:raise RuntimeError(f'Incomplete framebuffer: {status:x}')
        gl('glViewport',None,I,I,I,I)(0,0,w,h)
    def clear():
        gl('glClearColor',None,F,F,F,F)(0,0,0,0);gl('glClearDepth',None,C.c_double)(1.0)
        gl('glClear',None,U)(0x4000|0x100)
    textures={name:texture(width,height) for name in ['scene','normal','snapshot','a','b','resolved','result']}
    textures.update({name:texture(width//2,height//2) for name in ['bloom5','bloom6','rays']})
    depth0=texture(width,height,True);depth1=texture(width,height,True)
    shadow0=texture(1024,1024,True);shadow1=texture(1024,1024,True);shadowcolor=texture(1024,1024)
    # A wholly original, tiny checker texture, not any Minecraft/resourcepack asset.
    pixels=np.ones((16,16,4),np.float32)
    for y in range(16):
        for x in range(16):pixels[y,x,:3]=0.76+((x*13+y*7+x*y*3)%19)/80
    atlas=texture(16,16,pixels=pixels)
    unitmap={'gtexture':0,'colortex0':1,'colortex1':2,'colortex4':3,'colortex5':4,'colortex6':5,'colortex7':6,'depthtex0':7,'depthtex1':8,'shadowtex0':9,'shadowtex1':10,'shadowcolor0':11}
    def bind(program,bindings,uniforms):
        gl('glUseProgram',None,U)(program)
        for name,tex in bindings.items():
            unit=unitmap[name];gl('glActiveTexture',None,U)(0x84C0+unit);gl('glBindTexture',None,U,U)(0x0DE1,tex)
            location=gl('glGetUniformLocation',I,U,C.c_char_p)(program,name.encode());gl('glUniform1i',None,I,I)(location,unit)
        gl('glActiveTexture',None,U)(0x84C0)
        for name,value in uniforms.items():
            loc=gl('glGetUniformLocation',I,U,C.c_char_p)(program,name.encode())
            if loc<0:continue
            if isinstance(value,np.ndarray) and value.shape==(4,4):
                data=np.ascontiguousarray(value.T,dtype=np.float32);gl('glUniformMatrix4fv',None,I,I,C.c_ubyte,P)(loc,1,0,data.ctypes.data)
            elif isinstance(value,int):gl('glUniform1i',None,I,I)(loc,value)
            elif isinstance(value,(tuple,list,np.ndarray)):
                if name=='eyeBrightnessSmooth':gl('glUniform2i',None,I,I,I)(loc,*value)
                else:gl('glUniform3f',None,I,F,F,F)(loc,*value)
            else:gl('glUniform1f',None,I,F)(loc,float(value))
    def fullscreen():
        matrix(0x1701,identity);matrix(0x1700,identity)
        gl('glBegin',None,U)(7)
        for x,y,u,v in [(-1,-1,0,0),(1,-1,1,0),(1,1,1,1),(-1,1,0,1)]:
            gl('glTexCoord2f',None,F,F)(u,v);gl('glVertex3f',None,F,F,F)(x,y,0)
        gl('glEnd',None)()
    faces=[((0,1,0),[(0,1,0),(0,1,1),(1,1,1),(1,1,0)]),((0,-1,0),[(0,0,1),(0,0,0),(1,0,0),(1,0,1)]),
        ((0,0,1),[(0,0,1),(1,0,1),(1,1,1),(0,1,1)]),((0,0,-1),[(1,0,0),(0,0,0),(0,1,0),(1,1,0)]),
        ((1,0,0),[(1,0,1),(1,0,0),(1,1,0),(1,1,1)]),((-1,0,0),[(0,0,0),(0,0,1),(0,1,1),(0,1,0)])]
    boxes=[]
    # A small estuary with stepped banks, an arch and a grove: synthetic test fixture.
    boxes.append(((-55,-4,-80),(110,3,110),(0.42,0.47,0.41),0,0))
    boxes.append(((-55,-1,-70),(40,3,90),(0.39,0.55,0.30),0,0))
    boxes.append(((5,-1,-70),(50,2,90),(0.44,0.55,0.32),0,0))
    boxes.append(((-18,-1,-15),(7,1,22),(0.66,0.62,0.42),0,0))
    for z in [-15,-18,-21]:boxes.append(((5,1,z),(3,2,3),(0.53,0.52,0.43),0,0))
    for x,z,h in [(10,-12,7),(-20,-18,8),(15,-27,9),(-23,-34,10),(24,-38,8),(-18,-48,10),(9,-51,11)]:
        boxes.append(((x,1,z),(1.2,h,1.2),(0.35,0.26,0.16),0,0))
        boxes.append(((x-2,h-1,z-2),(5.5,3.5,5.5),(0.31,0.50,0.29),10020,0))
        boxes.append(((x-1,h+2,z-1),(3.5,2,3.5),(0.38,0.56,0.31),10020,0))
    for x in [-7,1]:boxes.append(((x,-1,-32),(2,9,3),(0.66,0.64,0.53),0,0))
    boxes.append(((-7,7,-32),(10,2,3),(0.68,0.65,0.53),0,0))
    for x in [-6,1]:boxes.append(((x,4,-28.8),(0.5,0.8,0.5),(1.0,0.68,0.20),10040,1))
    for x,z in [(-4,-2),(-2,-7),(0,-12)]:boxes.append(((x,-0.3,z),(1.5,0.5,1.5),(0.62,0.59,0.49),0,0))
    water=[((-14,0,-72),(19,0.02,88),(0.24,0.55,0.63),10000,0)]
    def geometry(program,items):
        ctx.check('before geometry attributes')
        material=gl('glGetAttribLocation',I,U,C.c_char_p)(program,b'mc_Entity')
        mid=gl('glGetAttribLocation',I,U,C.c_char_p)(program,b'mc_midTexCoord')
        gl('glNormal3f',None,F,F,F);gl('glTexCoord2f',None,F,F);gl('glVertex3f',None,F,F,F);gl('glEnd',None)
        if mid>=0:gl('glVertexAttrib4f',None,U,F,F,F,F)(mid,0.5,0.5,0,0)
        ctx.check('geometry attribute lookup')
        for pos,size,color,mat,block in items:
            if material>=0:gl('glVertexAttrib4f',None,U,F,F,F,F)(material,mat,0,0,0)
            gl('glColor4f',None,F,F,F,F)(*color,1.0)
            gl('glMultiTexCoord2f',None,U,F,F)(0x84C1,0.96875 if block else 0.03125,0.96875)
            ctx.check('geometry pre begin')
            gl('glBegin',None,U)(7)
            for normal,vertices in faces:
                gl('glNormal3f',None,F,F,F)(*normal)
                for vertex,uv in zip(vertices,[(0,0),(1,0),(1,1),(0,1)]):
                    gl('glTexCoord2f',None,F,F)(*uv)
                    gl('glVertex3f',None,F,F,F)(*[pos[k]+vertex[k]*size[k] for k in range(3)])
            gl('glEnd',None)();ctx.check('geometry end')
    camera=np.array([0,5.5,17],np.float32);mv=lookat(camera,np.array([-2,3,-21],np.float32));rotation=mv.copy();rotation[:3,3]=0
    projection=perspective()
    ctx.check('texture and fixture setup')
    all_images=[];stats=[]
    scenarios=[('day','world0',(0.45,0.68,-0.55),0.0),('dusk','world0',(-0.2,0.085,-0.95),0.0),('night','world0',(0.35,-0.60,-0.65),0.0),('rain','world0',(0.45,0.68,-0.55),0.9),('end','world1',(0.45,0.68,-0.55),0.0),('nether','world-1',(0.45,0.68,-0.55),0.0),('underwater','world0',(0.45,0.68,-0.55),0.0),('darkness','world0',(0.45,0.68,-0.55),0.0)]
    for name,dimension,sun,rain in scenarios:
        camera=np.array([0,-0.65,7] if name=='underwater' else [0,5.5,17],np.float32)
        target=np.array([-2,0.5,-21] if name=='underwater' else [-2,3,-21],np.float32)
        mv=lookat(camera,target);rotation=mv.copy();rotation[:3,3]=0
        sunlight=normalize(sun);light=sunlight if sunlight[1]>=0 else -sunlight
        smv=lookat(light*80,np.zeros(3,np.float32));sp=ortho()
        uniforms={'gbufferModelView':rotation,'gbufferModelViewInverse':np.linalg.inv(rotation),'gbufferProjection':projection,'gbufferProjectionInverse':np.linalg.inv(projection),
            'shadowModelView':smv,'shadowModelViewInverse':np.linalg.inv(smv),'shadowProjection':sp,'cameraPosition':camera,
            'sunPosition':rotation[:3,:3]@sunlight*100,'moonPosition':rotation[:3,:3]@(-sunlight)*100,'shadowLightPosition':rotation[:3,:3]@light*100,
            'fogColor':(0.39,0.12,0.075) if dimension=='world-1' else (0.6,0.72,0.8),'frameTimeCounter':27.,'rainStrength':rain,'wetness':rain,
            'viewWidth':float(width),'viewHeight':float(height),'near':0.05,'far':256.,'eyeBrightnessSmooth':(0,240),'isEyeInWater':1 if name=='underwater' else 0,
            'heldBlockLightValue':0,'heldBlockLightValue2':0,'blindness':0.,'darknessFactor':0.85 if name=='darkness' else 0.,'darknessLightFactor':0.75 if name=='darkness' else 0.,'nightVision':0.,'moonPhase':0,'alphaTestRef':0.1,'mc_chunkFade':1.}
        bindings={'gtexture':atlas,'shadowtex0':shadow0,'shadowtex1':shadow1,'shadowcolor0':shadowcolor,
            'colortex0':textures['scene'],'colortex1':textures['normal'],'colortex4':textures['snapshot'],'colortex5':textures['bloom5'],'colortex6':textures['bloom6'],'colortex7':textures['rays'],'depthtex0':depth0,'depthtex1':depth1}
        gl('glDisable',None,U)(0x0BE2);gl('glDisable',None,U)(0x0B44);gl('glEnable',None,U)(0x0B71)
        # Render opaque-only map into both depth attachments (no tinted fixture yet).
        for depth in [shadow0,shadow1]:
            attach([shadowcolor],depth,1024,1024);clear();program=programs[dimension,'shadow'];bind(program,{'gtexture':atlas},uniforms)
            ctx.check(name+' shadow bind');matrix(0x1701,sp);matrix(0x1700,smv@translate(-camera));geometry(program,boxes);ctx.check(name+' shadow draw')
        attach([textures['scene'],textures['normal']],depth0);clear()
        gl('glDisable',None,U)(0x0B71)
        attach([textures['scene']]);bind(programs[dimension,'prepare'],bindings,uniforms);fullscreen()
        gl('glEnable',None,U)(0x0B71);attach([textures['scene'],textures['normal']],depth0)
        program=programs[dimension,'gbuffers_terrain'];bind(program,bindings,uniforms);ctx.check(name+' terrain bind');matrix(0x1701,projection);matrix(0x1700,mv);geometry(program,boxes);ctx.check(name+' terrain draw')
        gl('glBindTexture',None,U,U)(0x0DE1,depth1)
        gl('glCopyTexSubImage2D',None,U,I,I,I,I,I,I,I)(0x0DE1,0,0,0,0,0,width,height)
        ctx.check(name+' geometry')
        gl('glDisable',None,U)(0x0B71)
        attach([textures['a'],textures['snapshot']]);bind(programs[dimension,'deferred'],bindings,uniforms);fullscreen()
        bindings['colortex0']=textures['a']
        gl('glEnable',None,U)(0x0B71)
        gl('glEnable',None,U)(0x0BE2);gl('glBlendFuncSeparate',None,U,U,U,U)(0x0302,0x0303,1,0x0303)
        attach([textures['a']],depth0);program=programs[dimension,'gbuffers_water'];bind(program,bindings,uniforms);matrix(0x1701,projection);matrix(0x1700,mv);geometry(program,water)
        gl('glDisable',None,U)(0x0B71)
        gl('glDisable',None,U)(0x0BE2)
        attach([textures['rays']],0,width//2,height//2);bind(programs[dimension,'composite'],bindings,uniforms);fullscreen()
        attach([textures['resolved']]);bind(programs[dimension,'composite1'],bindings,uniforms);fullscreen()
        bindings['colortex0']=textures['resolved']
        attach([textures['bloom5']],0,width//2,height//2);bind(programs[dimension,'composite2'],bindings,uniforms);fullscreen()
        attach([textures['bloom6']],0,width//2,height//2);bind(programs[dimension,'composite3'],bindings,uniforms);fullscreen()
        attach([textures['bloom5']],0,width//2,height//2);bind(programs[dimension,'composite4'],bindings,uniforms);fullscreen()
        attach([textures['b']]);bind(programs[dimension,'composite5'],bindings,uniforms);fullscreen()
        bindings['colortex0']=textures['b'];attach([textures['result']]);bind(programs[dimension,'final'],bindings,uniforms);fullscreen()
        gl('glFinish',None)();ctx.check(name+' full pipeline')
        data=np.empty((height,width,4),np.float32);gl('glReadBuffer',None,U)(0x8CE0)
        gl('glReadPixels',None,I,I,I,I,U,U,P)(0,0,width,height,0x1908,0x1406,data.ctypes.data)
        assert np.isfinite(data).all(),f'Non-finite pixels: {name}'
        assert data[:,:,:3].max()>0.04 and data[:,:,:3].std()>0.005,f'Empty/flat render: {name}'
        image=Image.fromarray((np.clip(data[::-1,:,:3],0,1)*255).astype(np.uint8))
        draw=ImageDraw.Draw(image);draw.rectangle((0,0,width,28),fill=(15,19,22));draw.text((12,8),f'TIDELUME / {name.upper()} / SYNTHETIC GPU TEST - NOT MINECRAFT',fill=(229,227,216))
        image.save(out/f'{name}.png');all_images.append(image)
        stats.append({'scenario':name,'finite':True,'mean_rgb':data[:,:,:3].mean(axis=(0,1)).tolist(),'peak':float(data[:,:,:3].max())})
        print('GPU RENDER PASS',name,flush=True)
    contact=Image.new('RGB',(width*2,height*((len(all_images)+1)//2)),(15,19,22))
    for i,image in enumerate(all_images):contact.paste(image,((i%2)*width,(i//2)*height))
    contact.save(out/'contact-sheet.jpg',quality=92)
    return stats

def main():
    parser=argparse.ArgumentParser(description=__doc__);parser.add_argument('--render',action='store_true');parser.add_argument('--width',type=int,default=800);parser.add_argument('--height',type=int,default=450);args=parser.parse_args()
    context=Context()
    try:
        print(json.dumps(context.info,indent=2),flush=True)
        programs={};failures=[]
        for dimension in ['world0','world-1','world1']:
            for vertex in sorted((SHADERS/dimension).glob('*.vsh')):
                try:programs[dimension,vertex.stem]=context.program(vertex,profiles()['BALANCED'])
                except RuntimeError as exc:failures.append(str(exc))
        print(f'GPU DRIVER LINK: {len(programs)}/99 program pairs',flush=True)
        for fail in failures:print(fail)
        stats=render_previews(context,programs,args.width,args.height) if args.render and not failures else []
        report={'source_sha256':source_fingerprint(),'scope':'Native GPU compilation and optional authored synthetic fixture; NOT Minecraft/Iris runtime','gpu':context.info,'program_pairs':len(programs),'failures':failures,'renders':stats}
        out=ROOT/'build'/'gpu';out.mkdir(parents=True,exist_ok=True);(out/'report.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
        return 1 if failures else 0
    finally:context.close()
if __name__=='__main__':raise SystemExit(main())
