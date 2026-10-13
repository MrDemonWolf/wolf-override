You are generating Look 2 ("graphic-painterly") character identity art for the game WOLF//OVERRIDE. Use your imagegen skill in its DEFAULT BUILT-IN mode only: the built-in `image_gen` tool, in edit mode with local reference images. Do NOT use the CLI fallback, scripts/image_gen.py, any API key or any billed path. If the built-in tool is unavailable, stop and say so.

Working folder (your cwd): CHARDIR = [session scratch, not kept]/hq/characters
Reference boards: CHARDIR/refs/ (read-only for you).

Procedure for EVERY image:
1. Load each listed reference file with the built-in `view_image` tool so it is in context, in the listed order, then call built-in `image_gen` once in edit mode with those references, using the IMAGE PROMPT text exactly as written below (you may not add creative requirements).
2. Ask for a genuinely transparent background (real alpha) for every image.
3. Copy the new file from $CODEX_HOME/generated_images/... into CHARDIR/raw/ with the stated file name (attempt suffix -a1, -a2, -a3). Never edit, resize, matte or recompress it: byte-for-byte copy.
4. Append to CHARDIR/raw/LOGFILE (markdown): the saved name, the full original generated_images source path, its SHA-256 (`shasum -a 256`), the reference files in order with their role, the image prompt verbatim inside a ~~~text fence, and a one-line self-check (facing direction, pose, limb/ear/paw counts, real transparency yes/no, any dark outline, text, floor or shadow, extra figure).
5. Look at the result. Regenerate (next attempt suffix) ONLY if it clearly breaks a lock: wrong facing or pose, wrong count of arms/legs/ears/paws/tails, opaque or coloured background instead of transparency, text or letters, a floor or cast shadow, a second figure (except where a lineup is requested), or a heavy black ink outline. Change only the failing point and log the reason. At most 3 attempts per pose. Choose the best attempt and mark it SELECTED in the log.

Rules: write only inside CHARDIR/raw/. Do not post-process. Do not touch any Git repository. Do not write anywhere else. Finish with a short list of the selected files.
