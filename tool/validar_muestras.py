#!/usr/bin/env python3
"""Valida los archivos generados por las pruebas (build/muestras).

Abre cada archivo con herramientas estándar (Pillow, openpyxl, pypdf y, si
está disponible, ffprobe) para comprobar que es válido. Escribe anotaciones de
GitHub Actions con el resultado.

Uso: python3 tool/validar_muestras.py build/muestras
     python3 tool/validar_muestras.py build/muestras_video --videos
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


def leer_mp4(p):
    """Datos de un MP4: con PyAV (FFmpeg) si está instalado, si no con ffprobe."""
    try:
        import av
    except ImportError:
        av = None
    if av is not None:
        with av.open(p) as c:
            st = c.streams.video[0]
            primero = None
            n = 0
            for frame in c.decode(st):
                if primero is None:
                    primero = frame.to_image()
                n += 1
            dur = float(c.duration / av.time_base) if c.duration else n / float(st.average_rate)
            return {"codec": st.codec_context.name, "ancho": st.codec_context.width,
                    "alto": st.codec_context.height, "fotogramas": n, "segundos": dur,
                    "primero": primero}
    if shutil.which("ffprobe"):
        out = subprocess.run(
            ["ffprobe", "-v", "error", "-select_streams", "v:0", "-count_frames",
             "-show_entries", "stream=codec_name,width,height,nb_read_frames",
             "-show_entries", "format=duration", "-of", "json", p],
            capture_output=True, text=True)
        if out.returncode != 0:
            raise RuntimeError(out.stderr.strip()[:300])
        info = json.loads(out.stdout)
        st = info["streams"][0]
        primero = None
        if shutil.which("ffmpeg"):
            from PIL import Image
            png = os.path.splitext(p)[0] + "_tmp.png"
            r = subprocess.run(["ffmpeg", "-v", "error", "-y", "-i", p, "-frames:v", "1", png],
                               capture_output=True, text=True)
            if r.returncode == 0 and os.path.exists(png):
                primero = Image.open(png)
                primero.load()
                os.remove(png)
        return {"codec": st["codec_name"], "ancho": st["width"], "alto": st["height"],
                "fotogramas": int(st.get("nb_read_frames", 0)),
                "segundos": float(info["format"]["duration"]), "primero": primero}
    return None


def comprobar_mp4(d, nombre, obligatorio, fotogramas=None, segundos=None, patron=False):
    p = os.path.join(d, nombre)
    if not os.path.exists(p):
        if obligatorio:
            errores.append(f"falta {nombre}")
        return
    try:
        info = leer_mp4(p)
    except Exception as e:  # noqa: BLE001 - se informa de cualquier fallo al leerlo
        errores.append(f"{nombre}: no se puede leer: {e}")
        return
    if info is None:
        notas.append(f"{nombre}: {mb(p):.2f} MB (sin PyAV ni ffprobe para analizarlo)")
        return
    texto = (f"{nombre}: {info['codec']} {info['ancho']}x{info['alto']}, "
             f"{info['fotogramas']} fotogramas, {info['segundos']:.2f} s, {mb(p):.2f} MB")
    img = info["primero"]
    if img is not None:
        w, h = img.size
        arriba = img.convert("RGB").getpixel((w // 2, h // 6))
        abajo = img.convert("RGB").getpixel((w // 2, h * 5 // 6))
        texto += f"; colores {arriba} / {abajo}"
        if patron:
            if not (arriba[0] > 170 and arriba[2] < 90):
                errores.append(f"{nombre}: arriba debería ser rojo y es {arriba}")
            if not (abajo[2] > 170 and abajo[0] < 90):
                errores.append(f"{nombre}: abajo debería ser azul y es {abajo}")
        base = os.path.splitext(p)[0]
        img.save(base + "_fotograma1.png")
    notas.append(texto)
    if info["codec"] != "h264":
        errores.append(f"{nombre}: códec {info['codec']}")
    if fotogramas is not None and not (fotogramas - 5 <= info["fotogramas"] <= fotogramas):
        errores.append(f"{nombre}: {info['fotogramas']} fotogramas (se esperaban {fotogramas})")
    if segundos is not None and abs(info["segundos"] - segundos) > 0.3:
        errores.append(f"{nombre}: dura {info['segundos']:.2f} s (se esperaban {segundos})")
    if mb(p) >= 8:
        errores.append(f"{nombre}: pesa {mb(p):.2f} MB")


def comprobar_videos(d):
    """Vídeos creados en un dispositivo (tool/prueba_video.sh)."""
    videos = sorted(f for f in os.listdir(d) if f.endswith(".mp4"))
    if not videos:
        notas.append("No hay vídeos: este equipo no tiene codificador H.264 (se usaría el GIF).")
    for v in videos:
        if v.startswith("patron_"):
            comprobar_mp4(d, v, True, fotogramas=30, segundos=1, patron=True)
        elif v.startswith("registro_"):
            comprobar_mp4(d, v, True, fotogramas=600, segundos=20)
        else:
            comprobar_mp4(d, v, True)


def escapar(texto):
    return texto.replace("%", "%25").replace("\r", "").replace("\n", "%0A")


def main():
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    d = args[0] if args else "build/muestras"
    if not os.path.isdir(d):
        print(f"::error title=Muestras::No existe {d}")
        sys.exit(1)
    if "--videos" in sys.argv:
        comprobar_videos(d)
    else:
        comprobar_png(d, "grafica.png", True)
        comprobar_png(d, "grafica_por_parametro.png", True)
        comprobar_png(d, "grafica_en.png", False)
        comprobar_png(d, "registro_1min.png", True)
        comprobar_png(d, "registro_1min_sin_fecha.png", True)
        comprobar_png(d, "registro_1min_en.png", False)
        comprobar_png(d, "registro_sin_eventos.png", False)
        comprobar_gif(d, "grafica.gif", 150, 10, 8, True)
        comprobar_gif(d, "registro.gif", 150, 10, 8, True)
        comprobar_xlsx(d, "informe.xlsx")
        comprobar_pdf(d, "informe.pdf")
    if notas:
        print("::notice title=Muestras::" + escapar("\n".join(notas)))
    if errores:
        print("::error title=Muestras (errores)::" + escapar("\n".join(errores)))
        sys.exit(1)
    print("Muestras correctas.")


if __name__ == "__main__":
    main()
