"""Static utilities for running subprocesses."""
import sys
import shlex
from subprocess import PIPE, run, Popen

from flask import redirect, jsonify

from config import HEROKU_ERR_EVERY_TIME, LOGGING_ON, IS_WINDOWS


def _run_process(command_line):
    """Run external program using command line interface.

    Returns:
         stdout,stdin: Of executed program.
    """
    return _run_process_unix_env(command_line) if not IS_WINDOWS \
        else _run_process_windows_env(command_line)


def _run_process_unix_env(command_line):
    """Run external program using command line interface on unix-like system.

    Returns:
         stdout,stdin: Of executed program.
    """
    args = shlex.split(command_line, posix=False)
    process = Popen(args, stdout=PIPE, stderr=PIPE)
    process.wait()
    stdout = process.stdout.read().decode().strip()
    stderr = process.stderr.read().decode().strip()

    return stdout, stderr


def _run_process_windows_env(command_line):
    """Run external program using command line interface on Windows.

    Returns:
         stdout,stdin: Of executed program.
    """
    args = shlex.split(command_line, posix=False)
    process = run(args, stdout=PIPE, stderr=PIPE, shell=True, check=True)
    stdout = process.stdout.decode("utf-8")
    stderr = process.stderr.decode("utf-8")

    return stdout, stderr


def _return_failing_result(stderr, stdout):
    """Return failing result."""
    if LOGGING_ON:
        print(stderr, file=sys.stderr)
        print(stdout)
    if 'java.io.FileNotFoundException' in stderr:
        return redirect('/')
    else:
        new_stderr = stderr.replace(HEROKU_ERR_EVERY_TIME, '')
        new_stderr = new_stderr.replace(
            'Exception in thread "main" org.pma2020.xform_test.', '')

    return jsonify({
        'error': new_stderr,
        'stdout': stdout if LOGGING_ON else ''
    })
