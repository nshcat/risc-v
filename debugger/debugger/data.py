"""
Module containing helper functions to deal with data exchanged with the
on-chip debugger over the serial connection.
"""

import struct
from enum import Enum


class DataType(Enum):
    """Enum describing the supported data bus read/write types"""
    WORD = 'I',
    SIGNED_WORD = 'i',
    HALF_WORD = 'H',
    SIGNED_HALF_WORD = 'h',
    BYTE = 'B',
    SIGNED_BYTE = 'b'


def deserialize_integer(buffer, data_type=DataType.WORD):
    """
    Deserialize integer of given type from given byte array
    :param buffer: Source byte array containing raw binary data
    :param data_type: Type of integer to deserialize
    :return: Deserialized integer
    """
    return struct.unpack(f">{data_type.value[0]}", buffer)[0]


def serialize_integers(data_type=DataType.WORD, amount=1, *args):
    """
    Serialize integers of given type into byte array.
    :param data_type: Type of integer
    :param amount: Number of integers to serialize
    :return: Byte array containing raw binary representation of given integers
    """
    return struct.pack(f">{data_type.value[0] * amount}", *args)


def serialize_integer(value, data_type=DataType.WORD):
    """
    Serialize integer of given type into byte array.
    :param data_type: Type of integer
    :param value: Value to serialize
    :return: Byte array containing raw binary representation of given integer
    """
    return struct.pack(f">{data_type.value[0]}", value)

