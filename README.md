# Norilsk: Last Shift (Roblox)

A first-person horror game set in Norilsk in December 1984, in the polar night. You are
a nickel miner at Mine No. 6. Clock in, go down the mine, eat at the state canteen, and
walk home. Something walks behind the last man.

Everything is built from code: the town, the mine, the people, the lighting, the UI and
the creature. You don't need to upload any assets, models or plugins.

## Open it in Roblox Studio

### Option A: open the place file (easiest)

1. Download `NorilskLastShift.rbxlx` from this repository.
2. In Roblox Studio, choose **File → Open from File…** and pick `NorilskLastShift.rbxlx`.
3. Press **Play** (F5). The town builds itself when the game starts, so the editor
   viewport stays empty until you press Play.
4. To publish, use **File → Publish to Roblox As…**.

### Option B: Rojo (live sync while you edit the code)

1. Install [Rojo](https://rojo.space/) and its Studio plugin.
2. Run `rojo serve` in this folder.
3. Open a new **Baseplate** place in Studio and click **Connect** in the Rojo plugin.
   The game deletes the default baseplate when it starts.

After you change files in `src/`, rebuild the place file with `python3 tools/build_place.py`.

## Controls

| Input | Action |
| --- | --- |
| WASD / mouse | Walk and look (first person) |
| Shift (hold) | Run (limited stamina) |
| F | Flashlight. After the lamp room, it's your helmet lamp, which turns on by itself underground |
| E | Interact (hold for some actions) |
| E / Esc | Put a note away |

## The shift

| # | Time | Objective |
| --- | --- | --- |
| 1 | 05:50 | Wake up in your flat (Building 14, flat 23). Read Mother's letter, then leave. |
| 2 | 06:10 | Walk north along Leninsky Prospekt with the other miners, and punch your card at the checkpoint. |
| 3 | 06:25 | Collect lamp No. 116 from the lamp room. |
| 4 | 06:35 | Ring for the cage and go down to horizon −300. |
| 5 | 07:00 | Break ore from the five marked seams (✕ 1 to ✕ 5). Coworkers are at work around you. |
| 6 | 15:40 | The shift ends, the lamps die one by one, and the miners are gone. Get back to the cage. |
| 7 | 18:20 | Hand in your meal coupon at Stolovaya No. 3. |
| 8 | 18:45 | Sit at your table and eat. The room is full of people eating and drinking. |
| 9 | 23:10 | Walk home. The streets are empty. Go through the courtyard to entrance 2 and unlock the door. |
| 10 | 23:40 | You are home. Something knocks. |

After the ending, the next day begins.

## The Foreman (Бригадир)

A tall, faceless figure in a greatcoat and ushanka. It wears miner's lamp **No. 117**, which
was never returned to the lamp room. You can often see its dim amber light in the fog
before you see the figure.

- **Morning and evening:** it appears in the distance and vanishes if you get close or stare.
- **In the canteen:** the lights fail, everyone turns to look at you, and it stands at the window.
- **In the mine, after the shift:** it hunts you through the tunnels on its way back to the cage.
- **At night:** it follows *your exact footsteps* home.

The rules (the notes and the night-time posters hint at them):

- While you look at it, it does not move.
- If you stare too long, it is suddenly closer.
- If you stand still, it closes the distance fast. Keep walking.
- Streetlights die as it passes, and your lamp flickers when it is near.
- If it reaches you, you go missing. You come back at the start of that part of the shift.

## Set dressing

**Period clothing.** Everyone dresses for the Arctic in 1984:

- quilted *fufaika* jackets with quilted trousers and felt *valenki* boots
- wool overcoats with fur collars and knitted scarves
- long fur coats with Orenburg shawls or fur hats
- miners' canvas suits with lamp batteries and self-rescuers on the belt
- Soviet Army greatcoats (*shinel*) with red shoulder boards and star-badged ushankas
- grey-blue militia coats with armbands
- white kitchen coats in the canteen

In the evening, people carry string shopping bags (*avoska*) with milk and bread; in the
morning, briefcases.

**Period items.** You'll also find:

- soda-water machines (1 kopeck plain, 3 with syrup) and a kvass barrel shut for the winter
- milk crates
- a cinema pillar showing «Москва слезам не верит» and «Пираты XX века»
- a Soviet New Year tree with a red star and a "С НОВЫМ 1985 ГОДОМ" banner
- a Zaporozhets and a Moskvich
- an army GAZ-66 with its engine running and the door open
- a yellow militia UAZ
- concrete litter urns

**Graffiti.** Football (СПАРТАК, ЦСКА), rock bands of the time (КИНО, АКВАРИУМ,
Машина Времени, AC/DC), "здесь был Вася", lovers' initials, and chalk left by miners
underground. Some writing only appears after dark.

- Five-storey Khrushchyovka panel blocks on permafrost piles, with lit windows, curtains,
  balconies, TV aerials, entrance lamps, benches and notice boards.
- Silver-wrapped heating mains running above ground, with the arch over the avenue and
  steam leaking from them.
- Thirteen propaganda posters of the period (СЛАВА ТРУДУ, ПЬЯНСТВУ — БОЙ, МИРУ — МИР,
  РЕШЕНИЯ XXVI СЪЕЗДА КПСС — В ЖИЗНЬ…) on the streets, the mine fence, in the canteen,
  the lamp room and the cage house, plus giant slogans on the gable ends. At night the
  slogans change.
- A Lenin monument, a Soyuzpechat kiosk, a payphone (2 kopecks), a bus stop with a mosaic,
  a PAZ bus, Zhiguli cars buried in snow, a board of honour with two faces crossed out,
  a playground with the classic climbing rocket, and garages.
- Mine No. 6: the fence with the concrete diamond panels, the checkpoint and time clock,
  the lamp room and its charging racks (slot 117 is empty), the cage house, the headframe
  with its red star, the hoist house, the concentrator, smokestacks with blinking warning
  lights, a BelAZ dump truck and a UAZ.
- Horizon −300: drifts with timber supports, rails, a vent duct, cables, lamps, puddles, a
  cart train, signs, a dispatcher phone, and the sealed 1952 Norillag gallery.
- Your flat: the wall carpet, a sideboard full of crystal, a Rubin TV, a VEF radio, a tea
  glass in its holder, a copy of Pravda, the calendar and the padded door.
- The ruins of the Norillag camp west of town: a watchtower, barbed wire, a collapsed barrack
  and numbered grave stakes.

There are **ten notes** to find:

- **Six personal and civil notes:** a letter, a missing-person poster, the lamp ledger, a carving in the mine, a KGB memo and the camp plaque.
- **Four military and official ones:**
  - an army telegram about a vanished guard post
  - a 1951 MVD escort report on a column that came back one prisoner short
  - a militia patrol report about a sergeant who went to check the Foreman's documents
  - a conscript's letter to his mother

Together they tell you what the Foreman is.

## Sound

The game only uses Roblox's built-in sounds, so it works out of the box. To make it
properly scary, upload your own audio (wind, a low drone, footsteps in snow, a scream,
knocking) and put the `rbxassetid://` ids into `Config.Audio` in `src/shared/Config.luau`.

## Tuning

`src/shared/Config.luau` holds:

- **Stages:** objectives, times and checkpoints.
- **Entity:** how fast the Foreman is, how long you can stare at it, and how much distance you get at your door.
- **Walkers:** routes and how many people are on the street.
- **Posters, notes, radio lines and audio.**

## Testing in Studio

In a Studio play test, type `/stage N` in chat to jump to stage N. For example, `/stage 9`
starts the walk home.

## Layout

```
src/shared/   Config, Build (part helpers), Figure (people built from parts)
src/server/   Game.server (stages, checkpoints), Town, Mine, Canteen (world builders)
src/client/   Client.client (input, lamp, camera), Ui, Ambience (light, fog, snow, sounds),
              People (animated NPCs, walkers), Entity (the Foreman), Rig, Audio
tools/        build_place.py: builds NorilskLastShift.rbxlx from src/ without Rojo
```
