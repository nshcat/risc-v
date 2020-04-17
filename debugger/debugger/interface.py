"""
Module providing primitives for communicating with the on-chip debugger over
a serial connection, like sending and receiving memory words.
"""

import serial
from .errors import *
from .data import *


class DebuggerState(Enum):
    """Enumeration describing the different states the on-chip debugger can be in"""
    DISCONNECTED = 1
    RUNNING = 2
    HALTED = 3


class DebuggerInterface:
    """
    Main interface class used to communicate with the on-chip debugger.
    Provides communication primitives for sending commands and receiving responses.
    """

    def __init__(self):
        self._state = DebuggerState.DISCONNECTED
        self._serial = None
        self._show_responses = False
        self._port = ''

    @property
    def state(self):
        return self._state

    @property
    def port(self):
        return self._port

    @property
    def show_responses(self):
        return self._show_responses

    @show_responses.setter
    def show_responses(self, value):
        self._show_responses = value

    def send_command(self, contents, response_size):
        """
        Send a command to the on-chip debugger and expect a response of given size.

        :param contents: A byte array containing the full command
        :param response_size: The expected response size, in bytes and including the status indicator (OK/NO)
        :return: Byte array containing response without status code, if command was accepted.
        """
        if len(contents) < 3:
            raise RejectedCommandError("Command contents length has to be at least 3")

        self._serial.write(contents)
        response = self._serial.read(response_size)

        # Print response contents to stdout if requested by the user.
        if self._show_responses:
            print(f"Response contents: {response}")

        # Check if command was accepted
        if response.startswith(b'OK'):
            return response[2:]
        else:
            raise RejectedCommandError(f"On-chip debugger rejected command \"{contents[:3].decode('utf-8')}\"")

    def retrieve_state(self):
        """Retrieve the current state the on-chip debugger is in."""
        result = self.send_command(b'+ST', 3)

        if result.startswith(b'H'):
            return DebuggerState.HALTED
        elif result.startswith(b'R'):
            return DebuggerState.RUNNING
        else:
            raise DebuggerError("Received invalid on-chip debugger state response")

    def retrieve_pc(self):
        """Retrieve the current program counter value."""
        result = self.send_command(b'+PC', 6)
        return deserialize_integer(result, DataType.WORD)

    def connect(self, port):
        """Connect to on-chip debugger using given serial port."""
        if self._state != DebuggerState.DISCONNECTED:
            raise DebuggerStateError("Can't connect: Already connected")

        # Try to establish serial connection
        try:
            self._serial = serial.Serial(port, 9600, serial.EIGHTBITS, serial.PARITY_NONE, serial.STOPBITS_ONE, timeout=1)
            self._port = port
        except serial.SerialException:
            raise DebuggerConnectionError("Failed to connect to on-chip debugger")

        # We now have to retrieve the current state of the on-chip debugger.
        # For some reason, this can take up to five tries to succeed.
        success = False
        for _ in range(5):
            try:
                self._state = self.retrieve_state()
                success = True
                break
            except DebuggerError:
                # Ignore any debugger errors and just retry
                pass

        # If we didn't manage to retrieve the current state in the 5 tries,
        # something is very wrong.
        if not success:
            self._serial.close()
            self._serial = None
            raise DebuggerConnectionError("Could not retrieve current debugger state")

    def disconnect(self):
        """Disconnect from the on-chip debugger"""
        if self._state != DebuggerState.DISCONNECTED:
            self._serial.close()
        else:
            raise DebuggerStateError("Can't disconnect: Not connected")

    def halt(self):
        """Halt CPU execution"""
        if self._state == DebuggerState.DISCONNECTED:
            raise DebuggerStateError("Can't halt execution, debugger is disconnected")

        if self._state == DebuggerState.HALTED:
            raise DebuggerStateError("CPU execution is already halted")

        self.send_command(b'+HL', 2)
        self._state = DebuggerState.HALTED

    def resume(self):
        """Resume CPU execution"""
        if self._state == DebuggerState.DISCONNECTED:
            raise DebuggerStateError("Can't resume execution, debugger is disconnected")

        if self._state == DebuggerState.RUNNING:
            raise DebuggerStateError("CPU is already running")

        self.send_command(b'+RE', 2)
        self._state = DebuggerState.RUNNING

    def read_memory(self, address):
        """
        Perform memory read via the on-chip debugger. Note that this can be used to read
        from any memory-mapped peripheral, not only the main memory.
        This function always reads a full word.

        :param address: Address to read from, has to be word-aligned (4 bytes)
        :return: Memory read result
        """

        # Check for address alignment
        if (address % 4) != 0:
            raise MemoryAddressError("Memory read address needs to be aligned on 4 byte boundary")

        # Build command and send
        command = b'+MR' + serialize_integer(address, DataType.WORD)
        response = self.send_command(command, 6)

        # Deserialize result
        return deserialize_integer(response, DataType.WORD)

    def write_memory(self, address, value):
        """
        Perform memory write via the on-chip debugger. Note that this can be used to write to any
        memory-mapped peripheral that supports writing, not only the main memory.
        This function always writes a full word.

        :param address: Address to write to. Has to be word-aligned (4 bytes)
        :param value: Value to write
        """

        # Check for address alignment
        if (address % 4) != 0:
            raise MemoryAddressError("Memory write address needs to be aligned on 4 byte boundary")

        # Build command and send
        command = b'+MW' + serialize_integers(DataType.WORD, 2, address, value)
        response = self.send_command(command, 2)

    def read_memory_block(self, start_address, length):
        """
        Read a block of memory of given length and beginning at given start address.

        :param start_address: Address to start reading from. Has to be word-aligned.
        :param length: Length of memory block, in bytes. Has to be a multiple of 4 bytes.
        :return: List containing memory block words.
        """

        # A zero-length read doesn't make sense
        if length == 0:
            raise MemoryAddressError("Memory block read length can't be zero")

        # Check alignment of start address and length
        if (start_address % 4) != 0:
            raise MemoryAddressError("Memory block read start address needs to be aligned on 4 byte boundary")

        if (length % 4) != 0:
            raise MemoryAddressError("Memory block read length not multiple of 4 bytes")

        return [self.read_memory(start_address + offset*4) for offset in range(length//4)]
