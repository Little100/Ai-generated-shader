"""Cross check shaders.properties against the options the shaders declare.

Iris degrades an unknown option name in a screen to an empty slot and logs a
warning rather than failing, so a typo in the layout is easy to never notice.
It also means an option that exists in the shaders but appears on no screen is
simply unreachable. This checks both directions, following the same rules Iris
uses to decide what counts as an option.
"""

import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent / "Skyweave" / "shaders"

SOURCE_SUFFIXES = (".glsl", ".fsh", ".vsh", ".gsh", ".csh")

# a numeric option carries its allowed values in a bracket list in the comment
DEFINE_VALUE = re.compile(r"^#define\s+([A-Z][A-Z0-9_]*)\s+\S+\s*//\s*\[")
# a boolean defaults to off when the #define is commented out, which is the
# same convention Iris uses
DEFINE_BOOL = re.compile(r"^(?://\s*)?#define\s+([A-Z][A-Z0-9_]*)\s*(?://.*)?$")
IFDEF_REFERENCE = re.compile(r"^#(?:ifdef|ifndef)\s+([A-Z][A-Z0-9_]*)\s*$")

# the const names Iris turns into settings options
CONST_OPTION = re.compile(
    r"^const\s+(?:int|float|bool)\s+"
    r"(shadowMapResolution|shadowDistance|voxelDistance|shadowDistanceRenderMul|"
    r"entityShadowDistanceMul|shadowIntervalSize|generateShadowMipmap|"
    r"generateShadowColorMipmap|shadowHardwareFiltering|shadowtex0Mipmap|"
    r"shadowtexMipmap|shadowtex1Mipmap|shadowtex0Nearest|shadowtexNearest|"
    r"shadow0MinMagNearest|shadowtex1Nearest|shadow1MinMagNearest|wetnessHalflife|"
    r"drynessHalflife|eyeBrightnessHalflife|centerDepthHalflife|sunPathRotation|"
    r"ambientOcclusionLevel|superSamplingLevel|noiseTextureResolution)\s*="
)


def source_lines():
    files = sorted(ROOT.glob("*"))
    files += sorted((ROOT / "lib").glob("*"))
    for path in files:
        if path.suffix in SOURCE_SUFFIXES and path.is_file():
            yield path.read_text(encoding="utf-8").splitlines()


def declared_options():
    """Split into pack options and Iris const options.

    A plain boolean define only counts when the same name is referenced from an
    #ifdef or #ifndef, which is exactly the rule Iris applies. The const options
    are reported separately because Iris already exposes them in its own video
    settings, so leaving them off the pack screens is correct rather than a gap.
    """
    lines = list(source_lines())

    referenced = set()
    for file_lines in lines:
        for line in file_lines:
            match = IFDEF_REFERENCE.match(line.strip())
            if match:
                referenced.add(match.group(1))

    pack = set()
    consts = set()
    for file_lines in lines:
        for line in file_lines:
            match = DEFINE_VALUE.match(line)
            if match:
                pack.add(match.group(1))
                continue

            match = CONST_OPTION.match(line)
            if match:
                consts.add(match.group(1))
                continue

            match = DEFINE_BOOL.match(line)
            if match and "[" not in line and match.group(1) in referenced:
                pack.add(match.group(1))

    return pack, consts


def referenced_options():
    """Every bare name used as a screen element, a slider or a program switch."""
    text = (ROOT / "shaders.properties").read_text(encoding="utf-8")
    referenced = set()

    for line in text.splitlines():
        stripped = line.strip()
        if stripped.startswith("#") or not stripped or "=" not in stripped:
            continue

        key, _, value = stripped.partition("=")

        # program.<name>.enabled reads option names out of a boolean expression
        if key.startswith("program.") and key.endswith(".enabled"):
            for token in re.findall(r"[A-Za-z_][A-Za-z0-9_]*", value):
                if token not in ("true", "false"):
                    referenced.add(token)
            continue

        if key.strip().split(".")[-1] == "columns":
            continue

        if key.startswith(("screen", "sliders", "profile.")):
            for token in value.split():
                if token.startswith(("[", "<")) or token == "*":
                    continue
                token = token.lstrip("!")
                name = token.split("=")[0].split(":")[0]
                if name and not name.startswith("profile"):
                    referenced.add(name)

    return referenced


def main():
    pack_options, const_options = declared_options()
    declared = pack_options | const_options
    referenced = referenced_options()
    problems = 0

    missing = sorted(referenced - declared)
    if missing:
        problems += 1
        print("referenced in shaders.properties but not declared in any shader:")
        for name in missing:
            print(f"  {name}")

    unreachable = sorted(pack_options - referenced)
    if unreachable:
        print("\ndeclared but reachable from no screen:")
        for name in unreachable:
            print(f"  {name}")

    # these are real options, but Iris already exposes them in its own video
    # settings, so leaving them off the pack screens is deliberate
    handled_by_iris = sorted(const_options - referenced)
    if handled_by_iris:
        print("\nleft to the iris video settings rather than a pack screen:")
        for name in handled_by_iris:
            print(f"  {name}")

    if not problems and not unreachable:
        print(f"\nconfig is consistent: {len(pack_options)} pack options, all reachable")

    return 1 if problems else 0


if __name__ == "__main__":
    sys.exit(main())
