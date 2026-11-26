# SCALE/ART standalone QA

This directory is reserved for verified Godot QA materials. **It is not a claim that the original SK playable game is backed up.**

S31 adds `tests/s31_transition_repeat_test.gd`, a repeated input transition test for the S30 standalone scene. When the full project is imported under this directory, run with Godot 4.7.2:

`godot --headless --path qa/scale-art --editor --quit`

`godot --headless --path qa/scale-art --script res://tests/s31_transition_repeat_test.gd`

A fresh clone **does not yet contain the complete QA Godot project**; compare the exact source ZIP checksum in `provenance/S31_SOURCE_MANIFEST.md` before calling it restored or runnable.
