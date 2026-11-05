import digitalio
from digitalio import DigitalInOut, Pull
from board import *
import neopixel_write

# The TENSTAR RP2350-USB uses GP22 for its WS2812, not a replay button.
button1 = None
led_rgb = DigitalInOut(GP22)
led_rgb.switch_to_output(value=False)
CORES_ESTADO = {
    "espera": bytes((0, 0, 16)),
    "envio": bytes((12, 16, 0)),
    "enviado": bytes((16, 0, 0)),
    "erro": bytes((0, 16, 0)),
}


def mostrar_estado(estado):
    neopixel_write.neopixel_write(led_rgb, CORES_ESTADO[estado])


# payload1 = GPIO4 to GND
# payload2 = GPIO5 to GND
# payload3 = GPIO10 to GND
# payload4 = GPIO11 to GND

#init payload selection switch
payload1Pin = digitalio.DigitalInOut(GP4)
payload1Pin.switch_to_input(pull=digitalio.Pull.UP)
payload2Pin = digitalio.DigitalInOut(GP5)
payload2Pin.switch_to_input(pull=digitalio.Pull.UP)
payload3Pin = digitalio.DigitalInOut(GP10)
payload3Pin.switch_to_input(pull=digitalio.Pull.UP)
payload4Pin = digitalio.DigitalInOut(GP11)
payload4Pin.switch_to_input(pull=digitalio.Pull.UP)

# check GP0 for setup mode
progStatusPin = digitalio.DigitalInOut(GP0)
progStatusPin.switch_to_input(pull=digitalio.Pull.UP)
