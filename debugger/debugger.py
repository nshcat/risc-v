from pyriscv_disas import Inst, rv_disas
import cmd, sys
from enum import Enum
import serial
import pathlib
import os.path
import time
import struct

try:
    import readline
except ImportError:
    readline = None

histfile = os.path.expanduser('~/.local/share/rvdbg/.history')
histfile_size = 1024

class DebuggerState(Enum):
    DISCONNECTED = 1
    RUNNING = 2
    HALTED = 3


class Shell(cmd.Cmd):
    state = DebuggerState.DISCONNECTED
    prompt = f'{state.name}> '
    port = None
    ser = None
    show_response = False
    
    def read_memory_word(self, adr):
        payload = struct.pack('>I', adr)
        cmd = b'+MR'   
        res = self.send_checked(cmd + payload, 6)
        
        if res != None:
            return self.parse_word(res)
        else:
            return None
    
    def write_memory_word(self, adr, val):
        payload = struct.pack('>II', adr, val)
        cmd = b'+MW'   
        res = self.send_checked(cmd + payload, 2)
        
        if res != None:
            return True
        else:
            return None
    
    def retrieve_state(self):
        res = self.send_checked(b'+ST', 3)
        
        if res != None:
            if(res.startswith(b'H')):
                return DebuggerState.HALTED
            elif(res.startswith(b'R')):
                return DebuggerState.RUNNING
            else:
                return None
        else:
            return None
        
    def retrieve_pc(self):
        res = self.send_checked(b'+PC', 6)
        
        if res != None:
            return self.parse_word(res)
        else:
            return None
        
    def parse_word(self, buf, signed=False):
        return struct.unpack('>i' if signed else '>I', buf)[0]
    
    def send_checked(self, msg, resp_size):
        self.ser.write(msg)
        res = self.ser.read(resp_size)
        
        if self.show_response:
            print(f"Response: {res}")
            
        if(res.startswith(b'OK')):
            return res[2:]
        else:
            return None
    
    def preloop(self):
        if readline and os.path.exists(histfile):
            readline.read_history_file(histfile)
    
    def postloop(self):
        if readline:
            path = pathlib.Path(histfile)
            path.parent.mkdir(parents=True, exist_ok=True)
            readline.set_history_length(histfile_size)
            readline.write_history_file(histfile)
    
    def update_prompt(self):
        if self.state == DebuggerState.DISCONNECTED:
            self.prompt = f'{self.state.name}> '
        else:
            self.prompt = f'{self.port}:{self.state.name}> '
            
            
    def do_exit(self, arg):
        return True
    
    def do_show(self, arg):
        'Show the current postition in the firmware'
        
        if self.state != DebuggerState.HALTED:
            print("Can't show position in firmware when CPU is running. Halt execution first.")
            return
        
        # Retrieve the PC
        pc = self.retrieve_pc()
        
        if pc == None:
            print("Failed to retrieve current program counter")
            return
        
        # Determine start. we want to show 5 lines in total with the current
        # instruction in the middle. But when the PC is close to, lets say, 0x0,
        # we cant simply subtract 8 byte from it.
        start_addr = max(pc - 8, 0)
        
        instrs = []
        for instr_offset in range(5):
            addr_offset = instr_offset * 4  # Four bytes per instruction
            absolute_addr = start_addr + addr_offset
            
            # Try to read the instruction
            instr = self.read_memory_word(absolute_addr)
            
            if instr == None:
                print(f"Failed to read instruction at address 0x{format(absolute_addr, '08x')}")
                return
            
            instrs.append(instr)
            
        # Format output
        cur_instr_idx = pc//4 if pc <= 4 else 2
        
        machine = rv_disas(PC=start_addr)
        
        for instr_idx in range(5):
            prefix = f"{'->' if instr_idx == cur_instr_idx else '  '} "
            print(f"{prefix}{machine.disassemble(instrs[instr_idx]).format()}")
        
        
    
    def do_write_memory(self, arg):
        'Write a word to given memory address'
        args = arg.split()
        
        if len(args) != 2:
            print("Expected exactly two arguments")
            print("write_memory [dest] [value]")
            return
        
        if self.state != DebuggerState.HALTED:
            print("Can't perform memory write on running CPU. Halt execution first.")
            return
        
        adr = int(args[0], 0)
        val = int(args[1], 0)
        res = self.write_memory_word(adr, val)
        
        if res == None:
            print("Failed to perform memory write")
    
    def do_read_leds(self, arg):
        'Read LED state'
        if self.state != DebuggerState.HALTED:
            print("Can't perform LED status read on running CPU. Halt execution first.")
            return
        
        res = self.read_memory_word(0x40F0)
        
        if res != None:
            print(f"LED state: {format(res, '#08b')}")
        else:
            print("Failed to read LED state")
            
    def do_read_memory(self, arg):
        'Read word from given memory address'
        if self.state != DebuggerState.HALTED:
            print("Can't perform memory read on running CPU. Halt execution first.")
            return
        
        adr = int(arg, 0)
        res = self.read_memory_word(adr)
        if res != None:
            print(f"Read result: 0x{format(res, '08x')}")
        else:
            print("Failed to perform memory read")
        
    
    def do_show_responses(self, arg):
        'Show the raw responses received over the serial connection'
        self.show_response = True
        
    def do_hide_responses(self, arg):
        'Hide the raw responses received over the serial connection'
        self.show_response = False
    
    def do_connect(self, arg):
        'Connect to SoC using the given serial port'
        self.port = arg
        self.ser = serial.Serial(self.port, 9600, serial.EIGHTBITS, serial.PARITY_NONE, serial.STOPBITS_ONE, timeout=1)
        
        res = None
        for _ in range(5):
            res = self.retrieve_state()
            
            if res != None:
                self.state = res
                self.update_prompt()
                break
            
        if res == None:
            self.ser.close()
            self.ser = None
            print("Failed to retrieve CPU state")

    def do_halt(self, arg):
        'Halts execution of the CPU, if running'    
        if self.state != DebuggerState.DISCONNECTED:
            if self.state != DebuggerState.HALTED:
                res = self.send_checked(b'+HL', 2)
                      
                if(res != None):
                    self.state = DebuggerState.HALTED
                    self.update_prompt()
                else:
                    print("Command failed!")
            else:
                print("CPU is already halted")
        else:
            print("Debugger is disconnected")
        
    def do_show_pc(self, arg):
        'Show current program counter value'
        pc = self.retrieve_pc()
        
        if pc != None:
            print(f"Current PC value: 0x{format(pc, '08x')}")
        else:
            print("Failed to retrieve current PC")
        
        
        
    def do_resume(self, arg):
        'Starts or resumes execution of the CPU'
        if self.state != DebuggerState.DISCONNECTED:
            if self.state == DebuggerState.HALTED:
                res = self.send_checked(b'+RE', 2)
                      
                if(res != None):
                    self.state = DebuggerState.RUNNING
                    self.update_prompt()
                else:
                    print("Command failed!")
            else:
                print("CPU is already running")
        else:
            print("Debugger is disconnected")
        
    def do_r(self, arg):
        'Starts or resumes execution of the CPU'
        self.do_resume(arg)

if __name__ == "__main__": 
    Shell().cmdloop()
    
    #machine = rv_disas(PC=0x10c)
    #print( "\n\n/dev/ttyUSB0:HALTED> show")
    #print(f"   {machine.disassemble(0x0507a703).format()}")
#    print(f"   {machine.disassemble(0x000047b7).format()}")
#    print(f"-> {machine.disassemble(0x0cc78793).format()}")
#    print(f"   {machine.disassemble(0x32400693).format()}")
#    print(f"   {machine.disassemble(0x00271713).format()}")      
#    print( "/dev/ttyUSB0:HALTED> reg load r1")
#    print( "   r1: 0x00000018")
#    print( "/dev/ttyUSB0:HALTED> reg store r1 0xAABBCCDD")
#    print( "/dev/ttyUSB0:HALTED> reg load r1")
#    print( "   r1: 0xAABBCCDD")
#    print( "/dev/ttyUSB0:HALTED> step")
#    print( "/dev/ttyUSB0:HALTED> show")
#    
#    machine = rv_disas(PC=0x110)
#    
#    print(f"   {machine.disassemble(0x000047b7).format()}")
#    print(f"   {machine.disassemble(0x0cc78793).format()}")
#    print(f"-> {machine.disassemble(0x32400693).format()}")
#    print(f"   {machine.disassemble(0x00271713).format()}")
#    print(f"   {machine.disassemble(0x00e68733).format()}")
#    input( "/dev/ttyUSB0:HALTED> ")