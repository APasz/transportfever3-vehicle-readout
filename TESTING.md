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
- With `Selected line` plus detail-window inclusion, open a vehicle window and
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
- Confirm Speed set to Off hides the speed, Below keeps it beneath the cargo
  widgets, and Above places it in a separate row above them.
- Confirm `No path`, `Unassigned`, and `Awaiting assignment` remain labelled when
  Operating state is disabled; returning-to-depot and stopped states should be
  icon-only.
- Check next-stop and named-depot displays with short and deliberately long names.
- Check vehicles with multiple passenger or cargo compartments.
