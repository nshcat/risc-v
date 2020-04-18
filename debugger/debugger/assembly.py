"""
Module containing helper functions used to display firmware assembly dumps retrieved
from the on-chip debugger
"""

from pyriscv_disas import Inst, rv_disas


def format_assembly(start_address, current_pc, instructions):
    """
    Format given instruction list as assembly listing. The current instruction will be marked
    based on the value of current_pc.

    :param start_address: The flash address of the first given instruction.
    :param current_pc: The current program counter, used to mark current instruction.
    Set this to None to not disable this feature.
    :param instructions: List of instruction words to format.
    """

    machine = rv_disas(PC=start_address)
    result = ""

    # Iterate through all given instructions and format them to string
    for index, instruction in enumerate(instructions):
        prefix = "   "

        # Check if current instruction is the one the current program counter
        # points to.
        # Each instruction is exactly four bytes wide, so we have to multiply
        # the index with 4 here and add it to the start address.
        if current_pc is not None and (start_address + 4*index) == current_pc:
            prefix = "-> "

        instruction_string = machine.disassemble(instruction).format()
        result = result + f"{prefix}{instruction_string}\n"

    return result
