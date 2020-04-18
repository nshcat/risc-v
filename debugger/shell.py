import cmd2
import sys
import pathlib
import os.path
import readline
from debugger import *

# History file management
history_file = os.path.expanduser('~/.local/share/rvdbg/.history')
history_file_size = 1024


class Shell(cmd2.Cmd):
    """Main debugger shell implementation"""

    _interface = DebuggerInterface()
    _no_shortcut = {'help', 'hide_responses', 'history', 'run_script', 'run_pyscript',
                    'shell', 'set', 'shortcuts', 'show_responses', 'read_memory', 'step_location',
                    'write_memory', 'edit', 'sl', 'eof'}
    prompt = 'DISCONNECTED> '

    def __init__(self, port=None):
        """
        Initialize new debugger shell object.
        :param port: Optional serial port, which causes the debugger to immediately try to connect to the on-chip
        debugger using that port.
        """

        super(Shell, self).__init__(
            persistent_history_file=history_file,
            persistent_history_length=history_file_size,
            shortcuts={'mr': 'read_memory', 'mw': 'write_memory', 'sl': 'step_location'},
            allow_cli_args=False
        )

        # Perform connect command if a port was given via the command line
        if port is not None:
            self.runcmds_plus_hooks([f"c {port}"])

    def update_prompt(self):
        """Update the current prompt according to the debugger state"""
        if self.state() == DebuggerState.DISCONNECTED:
            self.prompt = f'{self.state().name}> '
        else:
            self.prompt = f'{self._interface.port}:{self.state().name}> '

    def do_exit(self, arg):
        """Exit debugger"""
        if self.state() != DebuggerState.DISCONNECTED:
            self._interface.disconnect()

        return True

    def precmd(self, statement: cmd2.Statement) -> cmd2.Statement:
        """Try to complete entered, incomplete commands based on best-fit"""
        identifier = statement.command

        # Check if entered command is a direct fit. If so, we do not do anything here.
        is_direct_match = (identifier in self.get_all_commands())\
                          or (identifier in self.macros)\
                          or (identifier in self.aliases)

        # Continue of the given command is direct match
        if is_direct_match:
            return statement

        # Otherwise, it clearly is not a registered command, macro or alias
        # We now try to find all commands that have the given input as a prefix.
        # We disregard macros and aliases, and we only auto-complete if there is no ambiguity.
        matching_commands = [cmd for cmd in self.get_all_commands() if cmd.startswith(identifier) and cmd not in self._no_shortcut]
        if len(matching_commands) == 1:
            return cmd2.Statement(statement.args,
                              raw=statement.raw,
                              command=matching_commands[0],
                              arg_list=statement.arg_list,
                              multiline_command=statement.multiline_command,
                              terminator=statement.terminator,
                              suffix=statement.suffix,
                              pipe_to=statement.pipe_to,
                              output=statement.output,
                              output_to=statement.output_to)
        else:
            return statement

    def state(self):
        """Retrieve current debugger interface state"""
        return self._interface.state

    def do_step_location(self, arg):
        """Perform single step and show new location"""
        self.do_step(arg)
        self.do_location(arg)

    def do_step(self, arg):
        """Perform a single execution step"""
        if self.state() == DebuggerState.DISCONNECTED:
            print("Debugger is disconnected")
            return

        if self.state() != DebuggerState.HALTED:
            print("Can only single step when CPU execution is halted")
            return

        self._interface.step()

    def do_location(self, arg):
        """Show the current location in the firmware"""""
        
        if self.state() != DebuggerState.HALTED:
            print("Can't show position in firmware when CPU is running. Halt execution first.")
            return

        try:
            # Retrieve the PC
            pc = self._interface.retrieve_pc()

            # Determine start. we want to show 5 lines in total with the current
            # instruction in the middle. But when the PC is close to, lets say, 0x0,
            # we cant simply subtract 8 byte from it.
            start_address = max(pc - 8, 0)

            # Read memory block from flash memory. We read five instructions, each four bytes long.
            instructions = self._interface.read_memory_block(start_address, 5*4)

            # Format assembly view
            print(format_assembly(start_address, pc, instructions))

        except DebuggerError as error:
            print(f"Failed to execute operation: {str(error)}")

    def do_write_memory(self, arg):
        """Write a word to given memory address"""
        args = arg.split()
        
        if len(args) != 2:
            print("Expected exactly two arguments")
            print("write_memory [destination] [value]")
            return
        
        if self.state() != DebuggerState.HALTED:
            print("Can't perform memory write on running CPU. Halt execution first.")
            return

        try:
            # We use radix 0 here to allow the user to use any base they desire.
            address = int(args[0], 0)
            value = int(args[1], 0)
            self._interface.write_memory(address, value)
        except DebuggerError as error:
            print(f"Failed to execute operation: {str(error)}")
            
    def do_read_memory(self, arg):
        """Read word from given memory address"""
        if self.state() != DebuggerState.HALTED:
            print("Can't perform memory read on running CPU. Halt execution first.")
            return

        args = arg.split()
        if len(args) != 1:
            print("Expected exactly one argument")
            print("read_memory [source]")
            return

        try:
            address = int(args[0], 0)
            result = self._interface.read_memory(address)
            print(f"Memory read result: 0x{format(result, '08x')}")
        except DebuggerError as error:
            print(f"Failed to execute operation: {str(error)}")

    def do_show_responses(self, arg):
        """Show the raw responses received over the serial connection"""
        self._interface.show_responses = True
        
    def do_hide_responses(self, arg):
        """Hide the raw responses received over the serial connection"""
        self._interface.show_responses = False
    
    def do_connect(self, arg):
        """Connect to SoC using the given serial port"""
        args = arg.split()
        if len(args) != 1:
            print("Expected exactly one argument")
            print("connect [port]")
            return

        if self.state() != DebuggerState.DISCONNECTED:
            print("Can't connect: Already connected")
            return

        try:
            self._interface.connect(args[0])
            # Connecting can change the debugger state
            self.update_prompt()
        except DebuggerError as error:
            print(f"Failed to connect to debugger: {str(error)}")

    def do_pc(self, arg):
        """Show current program counter value"""
        try:
            pc = self._interface.retrieve_pc()
            print(f"Current PC value: 0x{format(pc, '08x')}")
        except DebuggerError as error:
            print(f"Failed to execute operation: {str(error)}")

    def do_halt(self, arg):
        """Halts execution of the CPU, if running"""
        try:
            if self.state() != DebuggerState.DISCONNECTED:
                if self.state() != DebuggerState.HALTED:
                    self._interface.halt()
                    self.update_prompt()
                else:
                    print("CPU is already halted")
            else:
                print("Debugger is disconnected")
        except DebuggerError as error:
            print(f"Failed to execute operation: {str(error)}")

    def do_disassemble(self, arg):
        """Disassemble a section of the loaded firmware"""
        args = arg.split()

        if len(args) != 2:
            print("Expected exactly 2 arguments")
            print("disassemble [start address] [length]")
            return

        try:
            start_address = int(args[0], 0)
            length = int(args[1], 0)

            # Read instructions
            instructions = self._interface.read_memory_block(start_address, length)

            # Format it
            print(format_assembly(start_address, None, instructions))
        except DebuggerError as error:
            print(f"Failed to execute operation: {str(error)}")

    def do_resume(self, arg):
        """Starts or resumes execution of the CPU"""
        try:
            if self.state() != DebuggerState.DISCONNECTED:
                if self.state() == DebuggerState.HALTED:
                    self._interface.resume()
                    self.update_prompt()
                else:
                    print("CPU is already running")
            else:
                print("Debugger is disconnected")
        except DebuggerError as error:
            print(f"Failed to execute operation: {str(error)}")
