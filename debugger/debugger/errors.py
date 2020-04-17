"""Module containing debugger-specific error and exception classes"""


class DebuggerError(Exception):
    """Base class for all debugger exceptions"""
    pass


class RejectedCommandError(DebuggerError):
    """Raised when the on-chip debugger rejected a command"""
    pass


class DebuggerStateError(DebuggerError):
    """Raised when a requested operation is incompatible with current debugger state"""
    pass


class DebuggerConnectionError(DebuggerError):
    """Raised when encountering problems with the serial connection to the on-chip debugger"""
    pass


class MemoryAddressError(DebuggerError):
    """Raised when supplied with invalid memory address, for example misaligned access"""
    pass

