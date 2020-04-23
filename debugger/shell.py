import cmd2
import sys
import pathlib
import os.path
import readline
from debugger import *
from decorators import *

# History file management
history_file = os.path.expanduser('~/.local/share/rvdbg/.history')
history_file_size = 1024


class Shell(cmd2.Cmd):
    """Main debugger shell implementation"""

    _interface = DebuggerInterface()
    _no_shortcut = {'help', 'hide_responses', 'history', 'run_script', 'run_pyscript',
                    'shell', 'set', 'shortcuts', 'show_responses', 'read_memory', 'step_location',
                    'write_memory', 'edit', 'sl', 'eof', 'clear_breakpoint', 'quit'}
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
            shortcuts={'mr': 'read_memory', 'mw': 'write_memory', 'sl': 'step_location',
                       'bc': 'clear_breakpoint'},
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

    @debugger_command("step_location", argument_count=0)
    @exclude_state(DebuggerState.DISCONNECTED, "Debugger is disconnected")
    @require_state(DebuggerState.HALTED, "Can only single step when CPU execution is halted")
    def do_step_location(self, arg):
        """Perform single step and show new location"""
        self.do_step(arg)
        self.do_location(arg)

    @debugger_command("step", argument_count=0)
    @exclude_state(DebuggerState.DISCONNECTED, "Debugger is disconnected")
    @require_state(DebuggerState.HALTED, "Can only single step when CPU execution is halted")
    def do_step(self, arg):
        """Perform a single execution step"""
        self._interface.step()

    @debugger_command("location", argument_count=0)
    @exclude_state(DebuggerState.DISCONNECTED, "Debugger is disconnected")
    @require_state(DebuggerState.HALTED, "Can't show position in firmware when CPU is running. Halt execution first.")
    def do_location(self, arg):
        """Show the current location in the firmware"""""
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

    @debugger_command("query_state", argument_count=0)
    @exclude_state(DebuggerState.DISCONNECTED, "Debugger is disconnected")
    def do_query_state(self, arg):
        self._interface.refresh_state()
        self.update_prompt()

    @debugger_command("write_memory [destination] [value]", argument_count=2)
    @exclude_state(DebuggerState.DISCONNECTED, "Debugger is disconnected")
    @require_state(DebuggerState.HALTED, "Can't perform memory write on running CPU. Halt execution first.")
    def do_write_memory(self, args):
        """Write a word to given memory address"""
        address = int(args[0], 0)
        value = int(args[1], 0)
        self._interface.write_memory(address, value)

    @debugger_command("read_memory [address]", argument_count=1)
    @exclude_state(DebuggerState.DISCONNECTED, "Debugger is disconnected")
    @require_state(DebuggerState.HALTED, "Can't perform memory read on running CPU. Halt execution first.")
    def do_read_memory(self, args):
        address = int(args[0], 0)
        result = self._interface.read_memory(address)
        print(f"Memory read result: 0x{format(result, '08x')}")

    @debugger_command("show_responses", argument_count=0)
    def do_show_responses(self, arg):
        """Show the raw responses received over the serial connection"""
        self._interface.show_responses = True

    @debugger_command("hide_responses", argument_count=0)
    def do_hide_responses(self, arg):
        """Hide the raw responses received over the serial connection"""
        self._interface.show_responses = False

    @debugger_command("breakpoint [address]", argument_count=1)
    @exclude_state(DebuggerState.DISCONNECTED, "Debugger is disconnected")
    def do_breakpoint(self, args):
        """Set hardware break to given flash address"""
        address = int(args[0], 0)
        self._interface.set_breakpoint(address)

    @debugger_command("clear_breakpoint", argument_count=0)
    @exclude_state(DebuggerState.DISCONNECTED, "Debugger is disconnected")
    def do_clear_breakpoint(self, arg):
        """Clear hardware breakpoint"""
        self._interface.clear_breakpoint()

    @debugger_command("connect [port]", argument_count=1)
    @require_state(DebuggerState.DISCONNECTED, "Can't connect: Already connected")
    def do_connect(self, args):
        """Connect to SoC using the given serial port"""
        self._interface.connect(args[0])
        self.update_prompt()

    @debugger_command("pc", argument_count=0)
    @exclude_state(DebuggerState.DISCONNECTED, "Debugger is disconnected")
    def do_pc(self, arg):
        """Show current program counter value"""
        pc = self._interface.retrieve_pc()
        print(f"Current PC value: 0x{format(pc, '08x')}")

    @debugger_command("halt", argument_count=0)
    @exclude_state(DebuggerState.DISCONNECTED, "Debugger is disconnected")
    @exclude_state(DebuggerState.HALTED, "CPU is already halted")
    def do_halt(self, arg):
        """Halts execution of the CPU, if running"""
        self._interface.halt()
        self.update_prompt()

    @debugger_command("disassemble [start address] [length]", argument_count=2)
    @exclude_state(DebuggerState.DISCONNECTED, "Debugger is disconnected")
    def do_disassemble(self, args):
        """Disassemble a section of the loaded firmware"""
        start_address = int(args[0], 0)
        length = int(args[1], 0)

        # Read instructions
        instructions = self._interface.read_memory_block(start_address, length)

        # Format it
        print(format_assembly(start_address, None, instructions))

    @debugger_command("resume", argument_count=0)
    @exclude_state(DebuggerState.DISCONNECTED, "Debugger is disconnected")
    @require_state(DebuggerState.HALTED, "CPU is already running")
    def do_resume(self, arg):
        """Starts or resumes execution of the CPU"""
        self._interface.resume()
        # The CPU might hit a break point again, so for better UX we
        # refresh the state
        self._interface.refresh_state()
        self.update_prompt()
