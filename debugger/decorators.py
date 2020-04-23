"""
This module contains function decorators to be used with the Cmd2 Shell class.
"""

from functools import wraps
from debugger import DebuggerError


def debugger_command(usage, argument_count):
    """
    A decorator for shell command handlers that automatically handles argument splitting
    and error handling in case of the user passing an invalid number of arguments.
    It also catches any errors originating from the debugger interface layer, to simplify
    shell code.

    :param usage: A usage example string to be shown to the user in case of wrong argument count
    :param argument_count: Amount of expected arguments to this command
    :return: Decorator with given parameters
    """

    # Actual decorator
    def decorator(func):
        @wraps(func)
        def with_args(shell, args):
            arguments = args.split()
            if len(arguments) != argument_count:
                # Special case for zero expected arguments
                if argument_count == 0:
                    print(f"Command '{usage}' expects no arguments")
                else:
                    print(f"Command expected exactly {argument_count} argument{'s' if argument_count > 1 else ''}")
                    print(usage)
            else:
                try:
                    func(shell, arguments)
                except DebuggerError as error:
                    print(f"Failed to execute operation: {str(error)}")
        return with_args
    return decorator


def exclude_state(excluded_state, message):
    """
    A decorator for shell command handlers that causes the command to fail if the debugger
    is in given state, displaying the given message to the user.

    :param excluded_state: State to exclude
    :param message: Message to display on failure
    :return: Decorator with given parameters
    """

    def decorator(func):
        @wraps(func)
        def wrapped(shell, args):
            if shell.state() == excluded_state:
                print(message)
            else:
                func(shell, args)
        return wrapped
    return decorator


def require_state(required_state, message):
    """
    Decorator for shell command handlers that adds a check for the debugger to be in given state.
    Will show given error message to the user in case of failure.

    :param required_state: State to require
    :param message: Message to display on failure
    :return: Decorator with given parameters
    """

    def decorator(func):
        @wraps(func)
        def wrapped(shell, args):
            if shell.state() != required_state:
                print(message)
            else:
                func(shell, args)
        return wrapped
    return decorator

