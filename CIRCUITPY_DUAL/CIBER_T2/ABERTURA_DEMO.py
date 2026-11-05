"""Abertura animada do programa completo instalado no Windows ou Linux."""

import importlib
from multiprocessing import Event, Process
import os
from pathlib import Path
import sys
import time


def preparar_ambiente(pasta):
    """Isola os dados da demonstra\xe7\xe3o de configura\xe7\xf5es herdadas do computador."""
    fontes = pasta / "aplicacao"
    if not (fontes / "main.py").is_file():
        raise FileNotFoundError(
            f"Programa ausente em {fontes}. Execute novamente o iniciador de preparacao.")
    inventario = pasta / "dados_demo" / "inventario.json"
    if not inventario.is_file():
        raise FileNotFoundError(
            f"Invent\xe1rio de demonstra\xe7\xe3o ausente: {inventario}. "
            "Execute novamente o iniciador de preparacao.")
    sys.path.insert(0, str(fontes))
    os.environ["INVENTARIO_DADOS"] = str(inventario)
    os.environ["INVENTARIO_BASE_CVE"] = str(pasta / "dados_demo" / "base_cve.json")
    os.environ.pop("INVENTARIO_EM_CONTAINER", None)
    for fluxo in (sys.stdin, sys.stdout, sys.stderr):
        if fluxo is not None and hasattr(fluxo, "reconfigure"):
            fluxo.reconfigure(encoding="utf-8", errors="replace")


def mostrar_abertura(pronto, cancelado, iniciada):
    """Anima em processo separado enquanto o programa prepara o primeiro menu."""
    try:
        import tkinter as tk
        from tkinter import ttk
    except ImportError:
        print("Abertura gr\xe1fica indispon\xedvel: instale o suporte Tcl/Tk do Python. "
              "Continuando no terminal.")
        return

    try:
        janela = tk.Tk()
    except tk.TclError as erro:
        print(f"Abertura gr\xe1fica indispon\xedvel ({erro}). Continuando no terminal.")
        return
    janela.title("Ciberseguran\xe7a T2")
    janela.configure(bg="#111827")
    janela.resizable(False, False)
    largura, altura = 580, 252
    x = (janela.winfo_screenwidth() - largura) // 2
    y = (janela.winfo_screenheight() - altura) // 2
    janela.geometry(f"{largura}x{altura}+{x}+{y}")
    tk.Label(janela, text="CIBERSEGURAN\xc7A T2", bg="#111827", fg="#f8fafc",
             font=("Segoe UI", 23, "bold")).pack(pady=(34, 10))
    tk.Label(janela, text="Invent\xe1rio \xb7 Vulnerabilidades \xb7 An\xe1lise de risco",
             bg="#111827", fg="#cbd5e1", font=("Segoe UI", 11)).pack()
    tk.Label(janela, text="Carregando o programa\u2026", bg="#111827", fg="#6ee7b7",
             font=("Segoe UI", 11)).pack(pady=(26, 12))
    estilo = ttk.Style(janela)
    estilo.theme_use("clam")
    estilo.configure("Carga.Horizontal.TProgressbar", troughcolor="#273449",
                     background="#34d399", bordercolor="#273449",
                     lightcolor="#34d399", darkcolor="#34d399")
    barra = ttk.Progressbar(janela, length=470, mode="indeterminate",
                            style="Carga.Horizontal.TProgressbar")
    barra.pack()
    barra.start(35)
    inicio = time.monotonic()
    agendamento = None
    fechada = False

    def fechar():
        nonlocal fechada
        if fechada:
            return
        fechada = True
        barra.stop()
        if agendamento is not None:
            janela.after_cancel(agendamento)
        janela.destroy()

    def cancelar():
        cancelado.set()
        fechar()

    def conferir():
        nonlocal agendamento
        agendamento = None
        if not pronto.is_set() or time.monotonic() - inicio < 3:
            agendamento = janela.after(30, conferir)
            return
        fechar()

    def ao_mostrar(evento):
        nonlocal inicio
        if evento.widget is janela and not iniciada.is_set():
            janela.update_idletasks()
            inicio = time.monotonic()
            iniciada.set()

    janela.bind("<Map>", ao_mostrar)
    janela.protocol("WM_DELETE_WINDOW", cancelar)
    agendamento = janela.after(30, conferir)
    try:
        janela.mainloop()
    finally:
        fechar()


def carregar_com_abertura():
    """Executa o programa na thread principal e fecha a abertura no primeiro menu."""
    pronto, cancelado, iniciada = Event(), Event(), Event()
    abertura = Process(target=mostrar_abertura, args=(pronto, cancelado, iniciada), daemon=True)
    abertura.start()
    exibir_menu_original = None
    try:
        while not iniciada.wait(0.05) and abertura.is_alive():
            pass
        if cancelado.is_set():
            return
        aplicacao = importlib.import_module("main")
        if cancelado.is_set():
            return
        exibir_menu_original = aplicacao.Aplicacao.exibir_menu

        def menu_pronto(self):
            if cancelado.is_set():
                raise SystemExit(0)
            pronto.set()
            abertura.join()
            aplicacao.Aplicacao.exibir_menu = exibir_menu_original
            if cancelado.is_set():
                raise SystemExit(0)
            exibir_menu_original(self)
            sys.stdout.flush()

        aplicacao.Aplicacao.exibir_menu = menu_pronto
        aplicacao.main()
    finally:
        if exibir_menu_original is not None:
            aplicacao.Aplicacao.exibir_menu = exibir_menu_original
        pronto.set()
        abertura.join()


def main():
    pasta = Path(__file__).resolve().parent
    try:
        preparar_ambiente(pasta)
        carregar_com_abertura()
        return 0
    except SystemExit as erro:
        codigo = erro.code if isinstance(erro.code, int) else 1
        if erro.code and not isinstance(erro.code, int):
            print(erro.code, file=sys.stderr)
    except Exception as erro:
        print(f"\nN\xe3o foi poss\xedvel iniciar Ciberseguran\xe7a T2: "
              f"{type(erro).__name__}: {erro}", file=sys.stderr)
        codigo = 1
    if codigo and sys.stdin is not None and sys.stdin.isatty():
        try:
            input("\nPressione Enter para fechar\u2026 ")
        except (EOFError, KeyboardInterrupt):
            pass
    return codigo


if __name__ == "__main__":
    raise SystemExit(main())
