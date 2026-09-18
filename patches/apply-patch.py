#!/usr/bin/env python3
"""
Patch chrome-remote-desktop wrapper to support existing display mode.

When ~/.config/crd-session-mode exists with a display number (e.g. "0"),
the wrapper connects to that display instead of creating a new Xvfb server.

Usage: sudo python3 apply-patch.py
Revert: sudo python3 apply-patch.py --revert
"""

import sys
import os
import shutil
import py_compile

CRD_SCRIPT = "/opt/google/chrome-remote-desktop/chrome-remote-desktop"
BACKUP = CRD_SCRIPT + ".bak"

ORIGINAL = '''  def launch_session(self, *args, **kwargs):
    logging.info("Launching X server and X session.")
    super(XDesktop, self).launch_session(*args, **kwargs)'''

PATCHED = '''  def launch_session(self, *args, **kwargs):
    crd_session_mode = os.path.expanduser("~/.config/crd-session-mode")
    if os.path.exists(crd_session_mode):
      with open(crd_session_mode) as f:
        display_num = int(f.read().strip())
      logging.info("Using existing display :%d" % display_num)
      self.child_env["DISPLAY"] = ":%d" % display_num
      self.child_env["XAUTHORITY"] = os.path.expanduser("~/.Xauthority")
      self.server_inhibitor.record_started(MINIMUM_PROCESS_LIFETIME,
                                           args[1] if len(args) > 1 else 0)
      self.session_inhibitor.record_started(MINIMUM_PROCESS_LIFETIME,
                                            args[1] if len(args) > 1 else 0)
    else:
      logging.info("Launching X server and X session.")
      super(XDesktop, self).launch_session(*args, **kwargs)'''


def apply_patch():
    with open(CRD_SCRIPT) as f:
        content = f.read()
    if PATCHED in content:
        print("Already patched.")
        return
    shutil.copy2(CRD_SCRIPT, BACKUP)
    content = content.replace(ORIGINAL, PATCHED, 1)
    with open(CRD_SCRIPT, "w") as f:
        f.write(content)
    py_compile.compile(CRD_SCRIPT, doraise=True)
    print("Patch applied.")


def revert_patch():
    if os.path.exists(BACKUP):
        shutil.copy2(BACKUP, CRD_SCRIPT)
        print("Reverted from backup.")
        return
    with open(CRD_SCRIPT) as f:
        content = f.read()
    content = content.replace(PATCHED, ORIGINAL, 1)
    with open(CRD_SCRIPT, "w") as f:
        f.write(content)
    print("Reverted.")


if __name__ == "__main__":
    revert_patch() if "--revert" in sys.argv else apply_patch()
