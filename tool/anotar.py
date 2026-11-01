#!/usr/bin/env python3
"""Convierte la salida de «flutter analyze» en anotaciones de GitHub Actions.

Uso: python3 tool/anotar.py analyze.log

GitHub limita el número de anotaciones por paso, así que se agrupan: una con
todos los errores y otra con los avisos.
"""
import re
import sys

PATRON = re.compile(r"^\s*(error|warning|info)\s+•\s+(.*?)\s+•\s+(\S+?):(\d+):(\d+)\s+•\s+(\S+)")


def escapar(texto):
    return texto.replace("%", "%25").replace("\r", "").replace("\n", "%0A")


def main():
    errores, avisos = [], []
    with open(sys.argv[1], encoding="utf-8", errors="replace") as f:
        for linea in f:
            m = PATRON.match(linea)
            if not m:
                continue
            nivel, mensaje, archivo, fila, col, codigo = m.groups()
            texto = f"{archivo}:{fila}:{col} [{codigo}] {mensaje}"
            (errores if nivel == "error" else avisos).append(texto)
    if errores:
        print(f"::error title=Análisis ({len(errores)} errores)::" + escapar("\n".join(errores[:80])))
    if avisos:
        print(f"::warning title=Análisis ({len(avisos)} avisos)::" + escapar("\n".join(avisos[:80])))
    if not errores and not avisos:
        print("Sin incidencias en el análisis.")


if __name__ == "__main__":
    main()
