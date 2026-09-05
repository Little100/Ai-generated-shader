"""Regression tests for Iris metadata checks (not a substitute for Iris runtime)."""
import unittest
from validate import validate_clear_colors, validate_buffer_formats, PREAMBLE, SHADERS, ROOT, expand
import re
import shutil
import subprocess
import tempfile
from pathlib import Path

class ClearColorTests(unittest.TestCase):
    def test_explicit_components(self):
        self.assertEqual(validate_clear_colors('const vec4 colortex0ClearColor = vec4(0.0, 0.0, 0.0, 0.0);','test'),1)

    def test_original_001_regression(self):
        for name in ['colortex0ClearColor','colortex4ClearColor','colortex7ClearColor','shadowcolor0ClearColor']:
            with self.subTest(name=name), self.assertRaisesRegex(AssertionError,'requires 4 explicit components'):
                validate_clear_colors(f'const vec4 {name} = vec4(0.0);','test')

    def test_other_invalid_arity(self):
        for value in ['', '0.0, 1.0', '0.0, 1.0, 0.0', '0.0,0.0,0.0,0.0,0.0']:
            with self.subTest(value=value),self.assertRaises(AssertionError):
                validate_clear_colors(f'const vec4 colortex0ClearColor=vec4({value});','test')

    def test_shader_math_splats_are_not_metadata(self):
        self.assertEqual(validate_clear_colors('vec4 color=vec4(0.0); const vec4 other=vec4(1.0);','test'),0)

    def test_comments_are_ignored(self):
        self.assertEqual(validate_clear_colors('// const vec4 colortex0ClearColor=vec4(0.0);\n/* const vec4 colortex4ClearColor=vec4(0.0); */','test'),0)

    def test_multiline(self):
        self.assertEqual(validate_clear_colors('const vec4 colortex0ClearColor=vec4(\n0.0,\n0.0,\n0.0,\n0.0\n);','test'),1)

class BufferFormatTests(unittest.TestCase):
    def test_metadata_block_preserves_symbolic_format(self):
        self.assertEqual(validate_buffer_formats('/*\nconst int colortex0Format = RGBA16F;\n*/','test'),1)

    def test_active_glsl_regression_rejected(self):
        for name,value in [('colortex0Format','RGBA16F'),('shadowcolor0Format','RGBA8')]:
            with self.subTest(name=name), self.assertRaisesRegex(AssertionError,'block comment'):
                validate_buffer_formats(f'const int {name} = {value};','test')

    def test_line_comments_and_inline_metadata_rejected(self):
        for source in ['// const int colortex0Format = RGBA16F;', '/* const int colortex0Format = RGBA16F; */']:
            with self.subTest(source=source),self.assertRaises(AssertionError):
                validate_buffer_formats(source,'test')

    def test_test_harness_does_not_define_formats(self):
        self.assertNotRegex(PREAMBLE,r'#define\s+(?:RGBA16F|RGBA8)\b')

    @unittest.skipUnless(shutil.which('glslangValidator'),'glslangValidator required')
    def test_raw_entrypoints_compile_without_any_injected_macros(self):
        # Expand pack includes ONLY: no configure(), no PREAMBLE, no driver shims.
        output=ROOT/'build'/'format-regression';output.mkdir(parents=True,exist_ok=True)
        with tempfile.TemporaryDirectory(dir=output) as folder:
            for dimension in ['world0','world-1','world1']:
                for program in ['prepare','deferred','composite','shadow']:
                    with self.subTest(dimension=dimension,program=program):
                        paths=[]
                        for stage,extension in [('vsh','vert'),('fsh','frag')]:
                            path=Path(folder)/f'{dimension}-{program}.{extension}'
                            path.write_text(expand(SHADERS/dimension/f'{program}.{stage}'),encoding='utf-8')
                            paths.append(str(path))
                        result=subprocess.run([shutil.which('glslangValidator'),'-l',*paths],capture_output=True,text=True,timeout=30)
                        self.assertEqual(result.returncode,0,result.stdout+result.stderr)

    @unittest.skipUnless(shutil.which('glslangValidator'),'glslangValidator required')
    def test_uncommented_original_form_reproduces_user_error(self):
        output=ROOT/'build'/'format-regression';output.mkdir(parents=True,exist_ok=True)
        with tempfile.TemporaryDirectory(dir=output) as folder:
            for program,symbol in [('prepare','RGBA16F'),('shadow','RGBA8')]:
                with self.subTest(program=program):
                    source=expand(SHADERS/'world0'/f'{program}.fsh')
                    def uncomment_format(match):
                        return match.group(0)[2:-2] if re.search(r'\bconst int (?:colortex|shadowcolor)\d+Format',match.group(0)) else match.group(0)
                    broken=re.sub(r'/\*.*?\*/',uncomment_format,source,flags=re.S)
                    path=Path(folder)/f'{program}-intentionally-broken.frag'
                    path.write_text(broken,encoding='utf-8')
                    result=subprocess.run([shutil.which('glslangValidator'),'-S','frag',str(path)],capture_output=True,text=True,timeout=30)
                    self.assertNotEqual(result.returncode,0)
                    self.assertIn(f"'{symbol}' : undeclared identifier",result.stdout+result.stderr)

if __name__ == '__main__':
    unittest.main()
