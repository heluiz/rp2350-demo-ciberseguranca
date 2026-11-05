# License : GPLv2.0
# copyright (c) 2023  Dave Bailey
# Author: Dave Bailey (dbisu, @daveisu)
# Adapted for the TENSTAR RP2350-USB with WS2812 on GP22.

import supervisor
import os
import time
import asyncio
from pins import mostrar_estado

supervisor.runtime.autoreload = False
mostrar_estado("espera")

try:
    from duckyinpython import getProgrammingStatus, selectPayload, runScript
except Exception:
    mostrar_estado("erro")
    raise

time.sleep(.5)


async def run_payload_on_startup():
    try:
        if getProgrammingStatus():
            print("Setup mode; payload not sent.")
            return
        if "loot.bin" in os.listdir("/"):
            print("loot.bin exists, skipping payload execution.")
            return
        with open("modo.txt", "r", encoding="utf-8") as arquivo:
            modo = arquivo.read().strip().lower()
        if modo not in ("windows", "linux", "manual"):
            raise ValueError("modo.txt must contain windows, linux or manual.")
        if modo == "linux":
            print("Linux mode; open INICIAR_NO_LINUX.desktop on CIRCUITPY.")
            return
        if modo == "manual":
            print("Manual mode; choose the Windows or Linux starter on CIRCUITPY.")
            return
        payload = selectPayload()
        await asyncio.sleep(0.1)
        print("Running", payload)
        await runScript(payload)
    except Exception:
        mostrar_estado("erro")
        raise
    mostrar_estado("enviado")


asyncio.run(run_payload_on_startup())
