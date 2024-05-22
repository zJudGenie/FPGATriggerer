from enum import Enum, unique
import serial

HEADER_SIZE = 3 # bytes

@unique
class Mode(Enum):
    READ  = 0b10_000000
    WRITE = 0b11_000000


@unique
class Command(Enum):
    DELAY_MODULE_DELAY  = (8, 3)
    DELAY_MODULE_ARM    = (9, 1)

    DIGITAL_EDGE_DETECTOR_CFG   = (16, 1)
    
    PULSE_EXTENDER_CYCLES       = (24, 2)

    TARGET_RESETTER_RESET       = (32, 1)

    def __init__(self, addr, reg_size) -> None:
        self.addr = addr
        self.reg_size = reg_size
        

class FPGATriggererAPI:
    """\
    Base class to send commands to the FPGATriggerer over UART
    """

    def __init__(self, port: str) -> None:
        self.serial = serial.Serial(port, baudrate=115200)

    def _prepare_header(self, cmd_mode: Mode, cmd: Command):
        """\
        Assemble the command mode in the first two bits and the command in the last six bits
        """
        header = bytearray(HEADER_SIZE) # we have a 3 byte header
        header[0] = cmd_mode.value | cmd.addr # command mode in the first two bits and the address in the last six bits
        header[1:3] = cmd.reg_size.to_bytes(2, 'little', signed=False)  
        return header
    
    def send_command(self, cmd_mode: Mode, cmd: Command, to_write: bytearray = None):
        to_send = self._prepare_header(cmd_mode, cmd)
        if cmd_mode is Mode.WRITE:
            to_send.extend(to_write)

        self.serial.write(to_send)

    def close(self):
        self.serial.close()


class DelayModule():

    def __init__(self, triggerer_api: FPGATriggererAPI) -> None:
        self.triggerer_api = triggerer_api
        
        self._delay = 0
        self._armed = False

    @property
    def delay(self):
        return self._delay

    @delay.setter
    def delay(self, value):
        assert isinstance(value, int), "value must be an int"

        self._delay = value
        self.triggerer_api.send_command(
            Mode.WRITE, 
            Command.DELAY_MODULE_DELAY, 
            value.to_bytes(Command.DELAY_MODULE_DELAY.reg_size, byteorder='little', signed=False)
        )

    @property
    def armed(self):
        return self._armed

    @armed.setter
    def armed(self, value):
        assert isinstance(value, bool), "value must be a bool"

        self._armed = value
        self.triggerer_api.send_command(
            Mode.WRITE, 
            Command.DELAY_MODULE_ARM, 
            value.to_bytes(Command.DELAY_MODULE_ARM.reg_size, byteorder='little', signed=False)
        )


class DigitalEdgeDetector():

    ARMED               = 0b1000_0000
    EDGE_SENSITIVITY    = 0b0000_0001

    def __init__(self, triggerer_api: FPGATriggererAPI) -> None:
        self.triggerer_api = triggerer_api
        
        self._config = 0

    @property
    def edge_sensitivity(self):
        return self._config & DigitalEdgeDetector.EDGE_SENSITIVITY

    @edge_sensitivity.setter
    def edge_sensitivity(self, value):
        self._change_property(DigitalEdgeDetector.EDGE_SENSITIVITY, value)
        self._send_config()


    @property
    def armed(self):
        return self._config & DigitalEdgeDetector.ARMED

    @armed.setter
    def armed(self, value):
        self._change_property(DigitalEdgeDetector.ARMED, value)
        self._send_config()


    def _change_property(self, mask, value: bool):
        assert isinstance(value, bool), "value must be a bool"

        if value:
            self._config |= mask
        else:
            self._config &= ~(mask)

    def _send_config(self):
        self.triggerer_api.send_command(
            Mode.WRITE,
            Command.DIGITAL_EDGE_DETECTOR_CFG, 
            self._config.to_bytes(Command.DIGITAL_EDGE_DETECTOR_CFG.reg_size, byteorder='little', signed=False)
        )


class PulseExtenderModule():

    def __init__(self, triggerer_api: FPGATriggererAPI) -> None:
        self.triggerer_api = triggerer_api
        
        self._cycles = 0

    @property
    def cycles(self):
        return self._cycles

    @cycles.setter
    def cycles(self, value):
        assert isinstance(value, int), "value must be an int"

        self._cycles = value
        self.triggerer_api.send_command(
            Mode.WRITE, 
            Command.PULSE_EXTENDER_CYCLES, 
            value.to_bytes(Command.PULSE_EXTENDER_CYCLES.reg_size, byteorder='little', signed=False)
        )


class TargetResetterModule():

    def __init__(self, triggerer_api: FPGATriggererAPI) -> None:
        self.triggerer_api = triggerer_api
        
        self._reset = False

    @property
    def reset(self):
        return self._reset

    @reset.setter
    def reset(self, value):
        assert isinstance(value, bool), "value must be a bool"

        self._reset = value
        self.triggerer_api.send_command(
            Mode.WRITE, 
            Command.TARGET_RESETTER_RESET, 
            value.to_bytes(Command.TARGET_RESETTER_RESET.reg_size, byteorder='little', signed=False)
        )