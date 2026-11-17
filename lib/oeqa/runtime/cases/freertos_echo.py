#
# SPDX-License-Identifier: MIT
#

from subprocess import Popen, PIPE

from oeqa.runtime.case import OERuntimeTestCase
from oeqa.core.decorator.oetimeout import OETimeout
import re

class FreeRTOSTest(OERuntimeTestCase):

    @OETimeout(15)
    def test_freertos_echo(self):
        # Use a special character with a known behavior
        cmd = '~'
        # Send it raw, so it does not look for echo $?, it just looks at the output
        status, output = self.target.runner.run_serial(cmd,raw=True)
        match = bool(re.search(cmd,output))
        self.assertEqual(match, True)

    @OETimeout(15)
    def test_freertos_echo_input(self):
        if self.td["MACHINE"] not in ("qemuarm", "qemuarm64"):
            self.skipTest("Input handling is specific to the shared QEMU demo")

        for command, echoed in (("\r", ""), ("\n", ""), (" ", " "), ("~", "~"),
                                ("\x00\x08\x1b\x1f\x7f~", "~")):
            with self.subTest(command=repr(command)):
                status, output = self.target.runner.run_serial(
                    command, raw=True, timeout=2)
                self.assertEqual(status, 1, output)
                response = ('You entered: "%s"\r\nUnblocked\r\n'
                            'Waiting For Notification - Blocked...\r\n') % echoed
                self.assertIn(response, output)
                self.assertEqual(output.count("You entered:"), 1, output)
