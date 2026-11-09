from django.shortcuts import render
from .catalogos import LUGARES_ITC

def aplicar_geocerca_por_lugar(datos_limpios):
    """
    Si el lugar seleccionado coincide con el combobox de LUGARES_ITC,
    autocompleta latitud, longitud y radio_geocerca_m automáticamente.
    """
    nombre_lugar = (datos_limpios.get('lugar') or '').strip()
    if nombre_lugar in LUGARES_ITC:
        info_sede = LUGARES_ITC[nombre_lugar]
        return {
            "lugar": info_sede["nombre"],
            "latitud_actividad": info_sede["latitud"],
            "longitud_actividad": info_sede["longitud"],
            "radio_geocerca_m": info_sede["radio_geocerca_m"],
        }
    return {
        "lugar": nombre_lugar or None,
        "latitud_actividad": datos_limpios.get("latitud_actividad"),
        "longitud_actividad": datos_limpios.get("longitud_actividad"),
        "radio_geocerca_m": datos_limpios.get("radio_geocerca_m", 50),
    }