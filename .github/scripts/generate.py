from pathlib import Path
import json
import re
import sys

REPO_ROOT = Path(__file__).resolve().parents[2]
DATABASE_DIR = REPO_ROOT / "database"
DATA_DIR = REPO_ROOT / "src" / "data"

# Lua filename suffix and IS_ guard name for each flavor; database/ paths use
# the lowercase form. A flavor with no database/ files generates empty tables.
FLAVORS = ["Vanilla", "TBC", "Forever"]

VALID_DIETS = {"Bread", "Cheese", "Fish", "Fruit", "Fungus", "Meat"}
VALID_TYPES = {"Cunning", "Ferocity", "Tenacity"}

# Family keys are lowercase letters only.
FAMILY_KEY_PATTERN = re.compile(r"^[a-z]+$")

# Order fields land in the generated file. npc_id is excluded, it's the
# table key, not a field. Abilities before coords so they aren't buried
# below a long coordinate list.
NPC_FIELD_ORDER = [
    "name",
    "family",
    "level_range",
    "classification",
    "zone_id",
    "ui_map_id",
    "abilities",
    "coords",
]


# Escapes and quotes s as a Lua string literal.
def luaString(s):
    escaped = s.replace("\\", "\\\\").replace('"', '\\"').replace("\n", "\\n")
    return f'"{escaped}"'


# Returns whether value is an int or float. JSON booleans are excluded, since
# Python treats bool as an int.
def isNumber(value):
    return isinstance(value, (int, float)) and not isinstance(value, bool)


# Serializes a JSON-decoded value into Lua table/literal syntax, indented
# for the given nesting depth.
def luaSerialize(value, indent):
    pad = "  " * indent
    if isinstance(value, str):
        return luaString(value)
    if isinstance(value, bool):
        return "true" if value else "false"
    if isinstance(value, (int, float)):
        return str(value)
    if isinstance(value, list):
        if not value:
            return "{}"
        if all(isNumber(item) for item in value):
            return "{" + ", ".join(str(item) for item in value) + "}"
        inner = ",\n".join(f"{pad}  {luaSerialize(item, indent + 1)}" for item in value)
        return "{\n" + inner + f"\n{pad}}}"
    if isinstance(value, dict):
        if not value:
            return "{}"
        inner = ",\n".join(
            f"{pad}  [{luaString(str(k))}] = {luaSerialize(v, indent + 1)}"
            for k, v in value.items()
        )
        return "{\n" + inner + f"\n{pad}}}"
    raise TypeError(f"cannot serialize {value!r}")


# Exits with an error if any coord is not an [x, y] pair of numbers.
def validateCoords(coords, fileLabel):
    for coord in coords:
        if len(coord) != 2 or not all(isNumber(n) for n in coord):
            sys.exit(f"invalid coord {coord!r} in {fileLabel} (expected [x, y])")


# Exits with an error if diet has a token outside VALID_DIETS.
def validateDiet(diet, fileLabel):
    for token in diet:
        if token not in VALID_DIETS:
            sys.exit(
                f"invalid diet token {token!r} in {fileLabel} (valid: {sorted(VALID_DIETS)})"
            )


# Reorders npc's fields to NPC_FIELD_ORDER, validating coords along the way.
# Exits with an error on any unrecognized field.
def orderNpcFields(npc, fileLabel):
    ordered = {}
    for field in NPC_FIELD_ORDER:
        if field not in npc:
            continue
        value = npc[field]
        if field == "coords":
            validateCoords(value, fileLabel)
        ordered[field] = value

    unknown = set(npc) - {"npc_id"} - set(NPC_FIELD_ORDER)
    if unknown:
        sys.exit(f"unknown field(s) {unknown} on {fileLabel}")

    return ordered


# Loads every NPC file in flavorDir, keyed by npc_id as a string. A missing
# flavorDir loads as no NPCs.
# Addon.TameableNPCs is string-keyed, matching src/tooltips.lua's direct
# TameableNPCs[id] lookup against a GUID-derived string.
def loadNpcs(flavorDir):
    npcs = {}
    for path in sorted(flavorDir.glob("*.json"), key=lambda p: int(p.stem)):
        npc = json.loads(path.read_text(encoding="utf-8"))
        npcId = str(npc["npc_id"])
        fileLabel = f"{path.parent.name}/{path.name}"
        if npcId in npcs:
            sys.exit(f"duplicate npc_id {npcId} ({fileLabel})")
        npcs[npcId] = orderNpcFields(npc, fileLabel)
    return npcs


# Loads path's families, keyed by family key, sorted for deterministic output.
# A missing file loads as no families.
def loadFamilies(path):
    if not path.exists():
        return {}
    fileLabel = f"{path.parent.name}/{path.name}"
    families = json.loads(path.read_text(encoding="utf-8"))
    ordered = {}
    for key in sorted(families):
        family = families[key]
        if not FAMILY_KEY_PATTERN.match(key):
            sys.exit(f"invalid family key {key!r} in {fileLabel} (lowercase letters only)")
        unknown = set(family) - {"name", "type", "diet"}
        if unknown:
            sys.exit(f"unknown field(s) {unknown} on family '{key}' ({fileLabel})")
        if "type" in family and family["type"] not in VALID_TYPES:
            sys.exit(
                f"invalid type {family['type']!r} on family '{key}' ({fileLabel}) (valid: {sorted(VALID_TYPES)})"
            )
        if "diet" in family:
            validateDiet(family["diet"], f"{fileLabel} family '{key}'")
        ordered[key] = {
            field: family[field] for field in ("name", "type", "diet") if field in family
        }
    return ordered


# Loads path's abilities, keyed by ability key, sorted for deterministic output.
# A missing file loads as no abilities.
def loadAbilities(path):
    if not path.exists():
        return {}
    fileLabel = f"{path.parent.name}/{path.name}"
    abilities = json.loads(path.read_text(encoding="utf-8"))
    ordered = {}
    for key in sorted(abilities):
        ability = abilities[key]
        unknown = set(ability) - {"name", "learned_by", "ranks"}
        if unknown:
            sys.exit(f"unknown field(s) {unknown} on ability '{key}' ({fileLabel})")
        ordered[key] = {
            field: ability[field]
            for field in ("name", "learned_by", "ranks")
            if field in ability
        }
    return ordered


# Writes lines to path, one per line, LF-terminated.
def writeLua(path, lines):
    path.write_text("\n".join(lines) + "\n", encoding="utf-8", newline="\n")


# Returns base with each record in patches merged in: a field in a patch replaces
# the base's field as a whole, and a record not in base is added as it is. This
# is how a flavor's files are applied over Vanilla's when the addon runs.
def mergePatches(base, patches):
    merged = {key: dict(record) for key, record in base.items()}
    for key, patch in patches.items():
        merged[key] = {**merged.get(key, {}), **patch}
    return merged


# Exits with an error if an NPC has an unknown family, or a family with no type
# or diet. families is every family known on the flavor.
def validateNpcFamilies(npcs, families, flavor):
    for npcId, npc in npcs.items():
        key = npc.get("family")
        if key is None:
            continue
        family = families.get(key)
        if family is None:
            sys.exit(f"unknown family {key!r} on NPC {npcId} ({flavor})")
        for field in ("type", "diet"):
            if field not in family:
                sys.exit(f"family {key!r} used by NPC {npcId} has no {field} ({flavor})")


# Exits with an error if an ability's learned_by has an unknown family.
def validateLearnedBy(abilities, families, flavor):
    for key, ability in abilities.items():
        for familyKey in ability.get("learned_by", []):
            if familyKey not in families:
                sys.exit(f"unknown family {familyKey!r} in learned_by of ability '{key}' ({flavor})")


# Builds one generated Lua file's lines: a header noting it's generated,
# then the merge call, guarded unless flavor is Vanilla.
def flavorLines(flavor, mergeCall, tableText):
    lines = [
        "-- Generated by `.github/scripts/generate.py` from `database/`. Do not edit by hand.",
        "local _, Addon = ...",
    ]
    if flavor != "Vanilla":
        lines.append(f"if not Addon.IS_{flavor.upper()} then return end")
    lines.append(f"Addon:{mergeCall}({tableText})")
    return lines


# Load every flavor first, since checking one needs Vanilla's data.
data = {}
for flavor in FLAVORS:
    data[flavor] = {
        "npcs": loadNpcs(DATABASE_DIR / "npcs" / flavor.lower()),
        "abilities": loadAbilities(DATABASE_DIR / "abilities" / f"{flavor.lower()}.json"),
        "families": loadFamilies(DATABASE_DIR / "families" / f"{flavor.lower()}.json"),
    }

# Generate families, NPCs, and abilities for each flavor.
for flavor in FLAVORS:
    print(f"Generating {flavor}...", end=" ")

    flavorData = data[flavor]

    # What the addon sees on this flavor: Vanilla's data with the flavor's own applied over it.
    seen = {
        kind: flavorData[kind] if flavor == "Vanilla" else mergePatches(data["Vanilla"][kind], flavorData[kind])
        for kind in ("npcs", "abilities", "families")
    }
    validateNpcFamilies(seen["npcs"], seen["families"], flavor)
    validateLearnedBy(seen["abilities"], seen["families"], flavor)

    writeLua(
        DATA_DIR / f"TameableFamilies-{flavor}.lua",
        flavorLines(flavor, "MergeTameableFamilies", luaSerialize(flavorData["families"], 0)),
    )
    writeLua(
        DATA_DIR / f"TameableNPCs-{flavor}.lua",
        flavorLines(flavor, "MergeTameableNPCs", luaSerialize(flavorData["npcs"], 0)),
    )
    writeLua(
        DATA_DIR / f"TameableAbilities-{flavor}.lua",
        flavorLines(flavor, "MergeTameableAbilities", luaSerialize(flavorData["abilities"], 0)),
    )

    print(
        f"{len(flavorData['families'])} families, {len(flavorData['npcs'])} NPCs, "
        f"{len(flavorData['abilities'])} abilities."
    )
