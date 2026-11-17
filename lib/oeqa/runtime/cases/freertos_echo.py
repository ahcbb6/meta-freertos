#
# SPDX-License-Identifier: MIT
#

from subprocess import Popen, PIPE

from oeqa.runtime.case import OERuntimeTestCase
from oeqa.core.decorator.oetimeout import OETimeout

class FreeRTOSTest(OERuntimeTestCase):

    @OETimeout(15)
    def test_freertos_echo(self):
        # Submit a line containing a special character with a known behavior.
        cmd = '~\r'
        # Send it raw, so it does not look for echo $?, it just looks at the output
        status, output = self.target.runner.run_serial(cmd,raw=True)
        match = 'You entered: "~"' in output
        self.assertEqual(match, True)

    @OETimeout(15)
    def test_freertos_echo_input(self):
        if self.td["MACHINE"] not in ("qemuarm", "qemuarm64", "qemuriscv32", "qemuriscv64"):
            self.skipTest("Input handling is specific to the shared QEMU demo")

        status, output = self.target.runner.run_serial(
            "hello", raw=True, timeout=0.3)
        self.assertIn("hello", output)
        self.assertNotIn("You entered:", output)
        self.assertNotIn("Unblocked", output)

        for command, echoed in (
                ("\r", "hello"), ("\r\n", ""), ("\n", ""),
                (" \r", " "), ("~\r", "~"),
                ("abc\b\x7fd\r", "ad"), ("\b\x7f\r", ""),
                ("\x00\x1b\x1f~\r", "~"),
                ("x" * 127 + "discarded\r", "x" * 127),
                ("reset\r", "reset")):
            with self.subTest(command=repr(command)):
                status, output = self.target.runner.run_serial(
                    command, raw=True, timeout=4)
                self.assertEqual(status, 1, output)
                response = ('You entered: "%s"\r\nUnblocked\r\n'
                            'Waiting For Notification - Blocked...\r\n') % echoed
                self.assertIn(response, output)
                self.assertEqual(output.count("You entered:"), 1, output)
