# Sistema de Detección de Dado D20

Este proyecto implementa un sistema de visión por computadora para detectar automáticamente el número mostrado en un dado d20 (20 caras) usando MATLAB y la Machine Vision Toolbox de Peter Corke.

## Archivos principales

### `detectar_dado.m`
Función principal que detecta el número del dado usando template matching.

**Uso:**
```matlab
resultado = detectar_dado('Foto 1.jpg');
```

**Parámetros:**
- `imagen_path`: Ruta a la imagen del dado a analizar

**Retorna:**
- `resultado`: Número detectado (1-20)

### `detectar_dado_mejorado.m`
Versión mejorada con segmentación y preprocesamiento avanzado.

**Uso:**
```matlab
resultado = detectar_dado_mejorado('Foto 2.jpg');
```

### `test_detector.m`
Script de prueba que ejecuta el detector en las imágenes de ejemplo.

**Uso:**
```matlab
run test_detector
```

## Metodología

### 1. Preprocesamiento
- Conversión a escala de grises
- Normalización de intensidad
- Filtrado para reducir ruido
- Detección de bordes (opcional)

### 2. Template Matching
- Se cargan los 20 templates (uno por cada número)
- Se prueban múltiples rotaciones (0° a 350° en pasos de 10°)
- Se calcula la similitud usando correlación normalizada
- Se selecciona el mejor match

### 3. Detección del resultado
- El número con mayor score de similitud es el resultado
- Se muestra la confianza y el ángulo de rotación

## Requisitos

- MATLAB R2019b o superior
- Machine Vision Toolbox de Peter Corke
  - Instalación: `https://petercorke.com/toolboxes/machine-vision-toolbox/`

## Estructura de templates

Las imágenes de template deben contener los dados en disposición de cuadrícula:

**Dado template 1.jpg:**
- Fila 1: 4, 9, 18, 7, 1
- Fila 2: 17, 6, 11, 3, 13

**Dado template 2.jpg:**
- Fila 1: 20, 19, 8, 15, 12
- Fila 2: 10, 5, 14, 2, 11

## Mejoras futuras

- Implementar características SIFT/SURF para matching más robusto
- Añadir detección automática de la región del dado
- Optimizar el rango de ángulos según la forma detectada
- Implementar validación de confianza para rechazar detecciones ambiguas
