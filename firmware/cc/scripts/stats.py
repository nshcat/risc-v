#! /bin/env python3

import sys
import argparse

UNITS = ['B', 'K', 'M', 'G']

def size_suffix(size):
    for unit in UNITS:  
        if size < 1024:
            if unit == 'B':
                return '{0:.0f}{1}'.format(size, unit)
            else:
                return '{0:.1f}{1}'.format(size, unit)
        size = size / 1024

class style():
    BLACK = lambda x: '\033[30m' + str(x) + '\033[0m'
    RED = lambda x: '\033[31m' + str(x) + '\033[0m'
    GREEN = lambda x: '\033[32m' + str(x) + '\033[0m'
    YELLOW = lambda x: '\033[33m' + str(x) + '\033[0m'
    BLUE = lambda x: '\033[34m' + str(x) + '\033[0m'
    MAGENTA = lambda x: '\033[35m' + str(x) + '\033[0m'
    CYAN = lambda x: '\033[36m' + str(x) + '\033[0m'
    WHITE = lambda x: '\033[37m' + str(x) + '\033[0m'
    UNDERLINE = lambda x: '\033[4m' + str(x) + '\033[0m'
    RESET = lambda x: '\033[0m' + str(x)
    
def color_percentage(p):
    fmt = f"{p:.2f}"
    if p > 100.0:
        return style.RED(fmt)
    elif p > 85.0:
        return style.YELLOW(fmt)
    else:
        return style.GREEN(fmt)


parser = argparse.ArgumentParser()
parser.add_argument("--flash-size", help="Available flash", type=int)
parser.add_argument("--sram-size", help="Available SRAM", type=int)
parser.add_argument("--newline", help="Add new line before output", action='store_true')
group = parser.add_mutually_exclusive_group(required=True)
group.add_argument("--mem-usage", help="Show memory usage statistics", action='store_true')
group.add_argument("--sym-size", help="Show ranking of symbols and their size", action='store_true')
args = parser.parse_args()


if args.mem_usage:
    text = 0
    data = 0
    bss = 0
    
    text_components = { ".reset", ".isr_common", ".text" }
    
    for line in sys.stdin.readlines()[2:-3]:
        components = line.split()
        name = components[0]
        size = int(components[1])

        # Text components
        if(name in text_components):
            text = text + size
        elif(name.startswith(".rodata") or name.startswith(".srodata")):
            text = text + size
        elif(name.startswith(".bss")):
            bss = bss + size
        elif(name.startswith(".data") or name.startswith(".sdata")):
            data = data + size
        

    text_used = text + data # This also has to count the data initializers, but not BSS
    data_used = data + bss

    flash_percentage = (float(text_used) / float(args.flash_size)) * 100.0
    sram_percentage = (float(data_used) / float(args.sram_size)) * 100.0
    
    if(args.newline):
        print("")

    print("Memory usage statistics:")
    print(f"  Flash: {size_suffix(text_used):<5} of {size_suffix(args.flash_size):<5}  ({color_percentage(flash_percentage)}%)")
    print(f"  SRAM:  {size_suffix(data_used):<5} of {size_suffix(args.sram_size):<5}  ({color_percentage(sram_percentage)}%)")
    print("")
elif args.sym_size:
    funcs = [ ]
    data = [ ]
    ro = [ ]
    bss = [ ]
    
    for line in sys.stdin.readlines():
        contents = line.split()
        sym_type = contents[2]
        sym_name = contents[3]
        sym_size = contents[1]
        
        def make_entry():
            return {'name': sym_name, 'size': int(sym_size)}
        
        if sym_type == "T":
            funcs.append(make_entry())
        elif sym_type == "R":
            ro.append(make_entry())
        elif sym_type == "D":
            data.append(make_entry())
        elif sym_type == "B":
            bss.append(make_entry())
        else:
            sys.exit(f"Unknown symbol type encountered: '{sym_type}'")
            
    if(args.newline):
        print("")
    print("Symbol statistics:")
    def print_stats_for(header, lst):
        if len(lst) > 0:
            print(f"  {header}")
            for entry in lst:
                print(f"    {entry['name']:<18} {size_suffix(entry['size']):>4}")
            print("")
    
    print_stats_for("Functions:", funcs)
    print_stats_for("Data:", data)
    print_stats_for("Read-Only:", ro)
    print_stats_for("Zeroed:", bss)     
    
              
else:
    print("Expected operation")
