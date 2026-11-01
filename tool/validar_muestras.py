#!/usr/bin/env python3
"""Valida los archivos generados por las pruebas (build/muestras).

Abre cada archivo con herramientas estándar (Pillow, openpyxl, pypdf y, si
está disponible, ffprobe) para comprobar que es válido. Escribe anotaciones de
GitHub Actions con el resultado.

Uso: python3 tool/validar_muestras.py build/muestras
"""
import datetime
import json
import os
import shutil
import subprocess
import sys

errores = []
notas = []


def mb(path):
    return os.path.getsize(path) / 1048576


def comprobar_png(d, nombre, obligatorio):
    from PIL import Image
    p = os.path.join(d, nombre)
    if not os.path.exists(p):
        if obligatorio:
            errores.append(f"falta {nombre}")
        return
    im = Image.open(p)
    im.load()
    colores = len(set(im.convert("RGB").resize((200, 200)).getdata()))
    notas.append(f"{nombre}: {im.size[0]}x{im.size[1]}, {mb(p):.2f} MB, {colores} colores")
    if colores < 10:
        errores.append(f"{nombre} parece vacía ({colores} colores)")


def comprobar_gif(d, nombre, fotogramas, segundos, max_mb, obligatorio):
    from PIL import Image
    p = os.path.join(d, nombre)
    if not os.path.exists(p):
        if obligatorio:
            errores.append(f"falta {nombre}")
        return
    im = Image.open(p)
    n = getattr(im, "n_frames", 1)
    total = 0
    for k in range(n):
        im.seek(k)
        total += im.info.get("duration", 0)
    bucle = im.info.get("loop")
    notas.append(f"{nombre}: {im.size[0]}x{im.size[1]}, {n} fotogramas, {total} ms, "
                 f"bucle={bucle}, {mb(p):.2f} MB")
    if n != fotogramas:
        errores.append(f"{nombre}: {n} fotogramas (se esperaban {fotogramas})")
    if abs(total - segundos * 1000) > 120:
        errores.append(f"{nombre}: dura {total} ms (se esperaban {segundos * 1000})")
    if bucle != 0:
        errores.append(f"{nombre}: no se repite en bucle")
    if mb(p) >= max_mb:
        errores.append(f"{nombre}: pesa {mb(p):.2f} MB (máximo {max_mb})")


def comprobar_xlsx(d, nombre):
    import openpyxl
    p = os.path.join(d, nombre)
    if not os.path.exists(p):
        errores.append(f"falta {nombre}")
        return
    wb = openpyxl.load_workbook(p)
    esperadas = ["Resumen", "Registros", "Tratamientos", "Información"]
    if wb.sheetnames != esperadas:
        errores.append(f"{nombre}: hojas {wb.sheetnames}")
        return
    reg = wb["Registros"]
    if not isinstance(reg["A2"].value, datetime.datetime):
        errores.append(f"{nombre}: la fecha de Registros!A2 no es una fecha ({reg['A2'].value!r})")
    res = wb["Resumen"]
    if not isinstance(res["A2"].value, datetime.datetime):
        errores.append(f"{nombre}: el inicio del periodo no es una fecha")
    if not res["A1"].font.b:
        errores.append(f"{nombre}: la cabecera no está en negrita")
    if reg.freeze_panes != "A2":
        errores.append(f"{nombre}: la cabecera no está fija")
    tr = wb["Tratamientos"]
    notas.append(f"{nombre}: {res.max_row - 1} periodos, {reg.max_row - 1} registros, "
                 f"{tr.max_row - 1} tratamientos; primera fila: "
                 f"{[c.value for c in reg[2]][:4]}")


def comprobar_pdf(d, nombre):
    p = os.path.join(d, nombre)
    if not os.path.exists(p):
        errores.append(f"falta {nombre}")
        return
    with open(p, "rb") as f:
        if f.read(5) != b"%PDF-":
            errores.append(f"{nombre}: no es un PDF")
            return
    from pypdf import PdfReader
    r = PdfReader(p)
    texto = "".join(page.extract_text() or "" for page in r.pages)
    notas.append(f"{nombre}: {len(r.pages)} páginas, {mb(p):.2f} MB")
    if "HOPE" not in texto:
        errores.append(f"{nombre}: no contiene el título")


def comprobar_mp4(d, nombre, obligatorio):
    p = os.path.join(d, nombre)
    if not os.path.exists(p):
        if obligatorio:
            errores.append(f"falta {nombre}")
        return
    if not shutil.which("ffprobe"):
        notas.append(f"{nombre}: {mb(p):.2f} MB (sin ffprobe para analizarlo)")
        return
    out = subprocess.run(
        ["ffprobe", "-v", "error", "-select_streams", "v:0", "-count_frames",
         "-show_entries", "stream=codec_name,width,height,nb_read_frames,avg_frame_rate",
         "-show_entries", "format=duration", "-of", "json", p],
        capture_output=True, text=True)
    if out.returncode != 0:
        errores.append(f"{nombre}: ffprobe no puede leerlo: {out.stderr.strip()[:300]}")
        return
    info = json.loads(out.stdout)
    st = info["streams"][0]
    dur = float(info["format"]["duration"])
    notas.append(f"{nombre}: {st['codec_name']} {st['width']}x{st['height']}, "
                 f"{st.get('nb_read_frames')} fotogramas, {dur:.2f} s, {mb(p):.2f} MB")
    if st["codec_name"] != "h264":
        errores.append(f"{nombre}: códec {st['codec_name']}")
    if mb(p) >= 8:
        errores.append(f"{nombre}: pesa {mb(p):.2f} MB")


def escapar(texto):
    return texto.replace("%", "%25").replace("\r", "").replace("\n", "%0A")


def main():
    d = sys.argv[1] if len(sys.argv) > 1 else "build/muestras"
    if not os.path.isdir(d):
        print(f"::error title=Muestras::No existe {d}")
        sys.exit(1)
    comprobar_png(d, "grafica.png", True)
    comprobar_png(d, "grafica_por_parametro.png", True)
    comprobar_png(d, "grafica_en.png", False)
    comprobar_png(d, "registro_1min.png", False)
    comprobar_gif(d, "grafica.gif", 150, 10, 8, True)
    comprobar_gif(d, "registro.gif", 150, 10, 8, False)
    comprobar_xlsx(d, "informe.xlsx")
    comprobar_pdf(d, "informe.pdf")
    comprobar_mp4(d, "registro.mp4", False)
    for extra in sorted(os.listdir(d)):
        if extra.endswith(".mp4") and extra != "registro.mp4":
            comprobar_mp4(d, extra, False)
    if notas:
        print("::notice title=Muestras::" + escapar("\n".join(notas)))
    if errores:
        print("::error title=Muestras (errores)::" + escapar("\n".join(errores)))
        sys.exit(1)
    print("Muestras correctas.")


if __name__ == "__main__":
    main()
