# Testing

Run the automated checks from the mod root:

```sh
./tools/validate.sh
```

Pass the Transport Fever 3 installation directory as the first argument, or set
`TF3_GAME_DIR`, when it is installed elsewhere. The validator checks the Teal
definitions and UI, runs the visibility/state/destination policy matrix, parses
all Lua and JSON resources, verifies parameter and localisation consistency, and
checks the metadata icon and referenced game GUI textures.

## Manual UI checklist

- Test UI scaling at 75%, 100%, 125%, and 150%.
- Open, shelve, pin, and close a vehicle detail window while paused and running.
- With `Selected line` or `Selected vehicle` plus detail-window inclusion, open a vehicle window and
  confirm same-line peers remain vanilla; then select the line itself and confirm
  its vehicles use the Vehicle Readout overlay.
- Follow and stop following a moving vehicle at each simulation speed.
- Check empty, partially loaded, full, loading, and unloading vehicles.
- Confirm passenger quality uses the happy face with no unhappy passengers and
  the sad face when at least one passenger is unhappy.
- Confirm the line-colour stripe updates after changing a line colour while the
  line icon remains white.
- Confirm a painted vehicle shows a vehicle-colour stripe, while an unpainted
  vehicle has no stripe; both retain normal white icons.
- Confirm every Speed choice: Off; Below; Below + Game bar; Above;
  Above + Game bar; and Game bar only. The floating and game-bar readouts should
  appear only in the locations named by each choice.
- Load public-release saves configured with Speed set to Off, Below, and Above.
  Each legacy choice should retain the equivalent floating placement until a new
  six-state Speed choice is saved.
- Enable each Game bar stat choice independently and with game-bar speed.
  Confirm the followed vehicle takes priority and the actively selected vehicle
  is used after following stops. Click empty ground, a marker, another entity, or
  a non-entity view and confirm a pinned vehicle window alone does not keep the
  readout visible.
- Confirm Game bar stat shows destination, line, operating state, aggregate load,
  condition, and vehicle name as configured. Unavailable destinations and lines
  should show an em dash; speed remains right-most.
- Hover either game-bar indicator and confirm its tooltip includes the full vehicle
  summary without blank lines. Current and top speed should share one line.
  A single cargo matching the aggregate load should not repeat that load; vehicles
  with multiple cargos should show each cargo's load and indented quality details.
  Passenger quality should use compact Happiness and Unhappy rows.
- Set Update interval to 15 seconds and confirm the game-bar speed still responds
  several times per second while accelerating and braking. Switch directly between
  vehicles and deselect one; stale data from the previous vehicle must never appear.
- Confirm `No path`, `Unassigned`, and `Awaiting assignment` remain labelled when
  Operating state is disabled; returning-to-depot and stopped states should be
  icon-only.
- Check next-stop and named-depot displays with short and deliberately long names.
- Check vehicles with multiple passenger or cargo compartments.
