# Contributing

Tamed's pet abilities and tameable NPCs live in `database/` as hand-editable JSON. The Lua files in `src/data/` are generated from it; do not edit them by hand.

To report wrong or missing data without editing it yourself, open an issue with the NPC or ability, what is wrong, and where the correct information came from.

## Setup

1. [Fork the repository](https://github.com/moody/Tamed/fork) on GitHub.
2. Clone your fork into your client's AddOns folder as `Tamed`, replacing any installed copy.
3. Create a branch for your change from `develop`:

```sh
git clone https://github.com/<your-username>/Tamed.git
cd Tamed
git checkout -b <your-branch> origin/develop
```

## Layout

```text
database/
├── abilities/
│   ├── vanilla.json   # every ability
│   ├── tbc.json       # TBC differences only
│   └── forever.json   # Forever differences only
└── npcs/
    ├── vanilla/       # every NPC, one file per NPC
    │   └── 10200.json
    ├── tbc/           # TBC differences only
    │   └── 15649.json
    └── forever/       # Forever differences only
```

Each folder or file is a flavor: `vanilla`, `tbc`, or `forever`. `vanilla` holds the full data set. `tbc` and `forever` hold only what differs on those clients:

- **A record new to the flavor** is written in full.
- **A record that exists in `vanilla`** is written as a patch: its key (`npc_id`, or the ability's key) plus only the fields that change. Each field in a patch replaces the Vanilla field as a whole, so a patched `coords` or `ranks` list must be complete.

`forever.json` and `forever/` do not exist yet; create them to add the first Forever entry.

## NPCs

Each NPC is one file, `database/npcs/<flavor>/<npc_id>.json`. A patch can leave out any required field except `npc_id`.

```json
{
  "npc_id": 10200,
  "name": "Rak'shiri",
  "family": "Cat",
  "type": "Ferocity",
  "diet": ["Meat", "Fish"],
  "level_range": "57",
  "classification": "Rare",
  "zone_id": 618,
  "ui_map_id": 1452,
  "abilities": [{ "key": "dash", "rank": 3 }],
  "coords": [
    [48.8, 6.8],
    [48.8, 8.6]
  ]
}
```

| Field            | Required | Description                                                                                                                                                                                     |
| ---------------- | -------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `npc_id`         | Yes      | The NPC's creature ID, also used as the file name. Shown in the NPC's Wowhead URL (`npc=10200`), or in game by targeting it and running `/dump (select(6, strsplit("-", UnitGUID("target"))))`. |
| `name`           | Yes      | As shown in game.                                                                                                                                                                               |
| `family`         | Yes      | As shown in game.                                                                                                                                                                               |
| `type`           | Yes      | `Ferocity`, `Cunning`, or `Tenacity`.                                                                                                                                                           |
| `diet`           | Yes      | Any of `Bread`, `Cheese`, `Fish`, `Fruit`, `Fungus`, `Meat`.                                                                                                                                    |
| `level_range`    | Yes      | A single level (`"57"`) or a range (`"24-25"`). NPCs are sorted by the first number.                                                                                                            |
| `classification` | No       | `Elite`, `Rare`, or `Rare Elite`.                                                                                                                                                               |
| `zone_id`        | Yes      | The zone's area ID, shown in its Wowhead URL (`zone=618`). An NPC whose `zone_id` the client does not recognize is not shown. Check it in game with `/dump C_Map.GetAreaInfo(618)`.             |
| `ui_map_id`      | No       | The map that opens when the NPC is clicked, and the map `coords` are measured on. Without it, the NPC cannot be shown on the map.                                                               |
| `abilities`      | Yes      | The abilities the NPC teaches, each an ability `key` from `database/abilities/` and that ability's `rank` number.                                                                               |
| `coords`         | Yes      | Spawn points as `[x, y]` percentages (0 to 100) on the `ui_map_id` map.                                                                                                                         |

To record the map and a spawn point while standing at it, run:

```txt
/run local m = C_Map.GetBestMapForUnit("player"); local p = C_Map.GetPlayerMapPosition(m, "player"); print(m, format("[%.1f, %.1f]", p.x * 100, p.y * 100))
```

It prints the map ID (`ui_map_id`) followed by the position, ready to paste into `coords`. The printed map ID must match the NPC's `ui_map_id`; inside a subzone it can differ.

## Abilities

Abilities are keyed by a short lowercase ID in `database/abilities/<flavor>.json`. A patch can leave out any required field.

```json
{
  "charge": {
    "name": "Charge",
    "learned_by": ["Boar"],
    "ranks": [
      { "rank": 1, "spell_id": 7371, "pet_level": 1, "training_cost": 5 },
      { "rank": 2, "spell_id": 26177, "pet_level": 12, "training_cost": 9 }
    ]
  }
}
```

| Field        | Required | Description                                                   |
| ------------ | -------- | ------------------------------------------------------------- |
| `name`       | Yes      | For readability. The name shown in game comes from the spell. |
| `learned_by` | Yes      | The pet families that can learn it. `[]` means every family.  |
| `ranks`      | Yes      | The ability's ranks, each with the fields below.              |

| Rank field      | Required | Description                                                   |
| --------------- | -------- | ------------------------------------------------------------- |
| `rank`          | Yes      | The rank's own number.                                        |
| `spell_id`      | Yes      | The rank's spell ID, shown in its Wowhead URL (`spell=7371`). |
| `pet_level`     | No       | The pet level required to learn the rank.                     |
| `training_cost` | No       | The training point cost.                                      |

A rank whose `spell_id` the client does not recognize is not shown, and an ability with no recognized ranks is not shown at all.

## Generating

After editing, regenerate `src/data/` from the repository root. It needs Python 3 and nothing else:

```sh
python3 .github/scripts/generate.py
```

The script exits with an error on an unknown field, a duplicate `npc_id`, or an unknown `diet` value.

Commit the changes in both `database/` and `src/data/`. CI regenerates `src/data/` and fails if it differs from what was committed.

## Testing

`/reload` in game on a client of the flavor you changed, then open `/tamed` and select a rank the change affects. Check that:

- the rank's pet level, training cost, and learnable-by families are right;
- each NPC appears under that rank with the right name, level, and location;
- its tooltip lists the right details;
- clicking it opens the right map, with pins where the NPC spawns;
- hovering the NPC in the world shows its abilities in the tooltip, if NPC tooltips are enabled.

## Submitting

Push your branch to your fork:

```sh
git push -u origin <your-branch>
```

Then open a pull request on GitHub from your branch into `develop`, not `master`, describing what changed and where the data came from.
