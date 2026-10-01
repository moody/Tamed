from pathlib import Path
import json
import sys

REPO_ROOT = Path(__file__).resolve().parents[2]
DATABASE_DIR = REPO_ROOT / "database"
DATA_DIR = REPO_ROOT / "src" / "data"

# Lua filename suffix and IS_ guard name for each flavor; database/ paths use
# the lowercase form. A flavor with no database/ files generates empty tables.
FLAVORS = ["Vanilla", "TBC", "Forever"]

VALID_DIETS = {"Bread", "Cheese", "Fish", "Fruit", "Fungus", "Meat"}

# Order fields land in the generated file. npc_id is excluded, it's the
# table key, not a field. Abilities before coords so they aren't buried
# below a long coordinate list.
NPC_FIELD_ORDER = [
    "name",
    "family",
    "type",
    "diet",
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


# Reorders npc's fields to NPC_FIELD_ORDER, validating diet and coords along
# the way. Exits with an error on any unrecognized field.
def orderNpcFields(npc, fileLabel):
    ordered = {}
    for field in NPC_FIELD_ORDER:
        if field not in npc:
            continue
        value = npc[field]
        if field == "diet":
            validateDiet(value, fileLabel)
        elif field == "coords":
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


# Generate NPCs and abilities for each flavor.
for flavor in FLAVORS:
    print(f"Generating {flavor}...", end=" ")

    npcs = loadNpcs(DATABASE_DIR / "npcs" / flavor.lower())
    writeLua(
        DATA_DIR / f"TameableNPCs-{flavor}.lua",
        flavorLines(flavor, "MergeTameableNPCs", luaSerialize(npcs, 0)),
    )

    abilities = loadAbilities(DATABASE_DIR / "abilities" / f"{flavor.lower()}.json")
    writeLua(
        DATA_DIR / f"TameableAbilities-{flavor}.lua",
        flavorLines(flavor, "MergeTameableAbilities", luaSerialize(abilities, 0)),
    )

    print(f"{len(npcs)} NPCs, {len(abilities)} abilities.")
