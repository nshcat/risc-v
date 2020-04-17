import cmd
import sys
import pathlib
import os.path
import readline
from debugger import *

# History file management
history_file = os.path.expanduser('~/.local/share/rvdbg/.history')
history_file_size = 1024


class Shell(cmd.Cmd):
    """Main debugger shell implementation"""

    _interface = DebuggerInterface()
    prompt = 'DISCONNECTED> '

    def preloop(self):
        # Recover readline command history
        if os.path.exists(history_file):
            readline.read_history_file(history_file)
    
    def postloop(self):
        # Save command history to history file for later retrieval
        path = pathlib.Path(history_file)
        path.parent.mkdir(parents=True, exist_ok=True)
        readline.set_history_length(history_file_size)
        readline.write_history_file(history_file)
    
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

    def state(self):
        """Retrieve current debugger interface state"""
        return self._interface.state

    def do_show(self, arg):
        """Show the current position in the firmware"""""
        
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

    def do_show_pc(self, arg):
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

    def do_r(self, arg):
        """Starts or resumes execution of the CPU"""
        self.do_resume(arg)


if __name__ == "__main__": 
    Shell().cmdloop()
