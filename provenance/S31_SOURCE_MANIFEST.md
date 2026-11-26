# S31 standalone SCALE/ART QA handoff

Local artifact: `SK_SCALE_0_3_S31_patch.zip`

SHA-256: `6240210e7d63e16e3983fb8361058e038026738738b21220db15f6d3dd1baf8d`

ZIP integrity: passed; 144 source/art/QA entries. Native Godot 4.7.2 `tests/s31_transition_repeat_test.gd`: **46/46 assertions passed** (10 crouch/stand reversals, sprite/collider guard, camera reversal, four parallax layers). S30 canonical baseline SHA-256 is in `S30_SOURCE_MANIFEST.md`.

**Important:** This commit publishes the S31 test source and its provenance, **not** the entire S31 ZIP or all image/script bytes. The test will not run on a fresh clone until the full QA project is imported. Cross-chat backup of the source/asset tree is pending exact-byte upload.
