# fortress-copy
Copy Minecraft nether fortress data from one savegame to another to  fix migration issues from 1.12 to 1.13.

# BIG HUGE FUCKING DISCLAIMER!

There are (known) cases where your savegame will get corrupted (details below)!

Backup your world before atempting ANY meddling with the data! Once the world is broken, your world is lost!

# Requirements

You need some Node.js (this is only tested with v10.8.0, but should work with any Node >= 6).

You need to install CoffeeScript:

```
npm install -g coffeescript
```

# Usage

1. Upgrade your world to 1.13 (if you haven't already done this)
2. Get the seed of your world (enter /seed in the in-game console)
3. Create a world with this seed
4. Run the script

```
Usage: coffee index.coffee <frompath> <topath>

frompath: Path to savegame to read fortress data from.
topath: Path to savegame to write fortress data to.
```

# Known limitations

If the changed NBT data is longer then the already reserved sector size, it does NOT allocate a new sector for the data, so subsequent sectors will be overwritten. This usually should not happen, but I do not give any guarantees.

