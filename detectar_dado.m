% detectar_dado.m
% Sistema de detección de números en dado d20 usando Machine Vision Toolbox de Peter Corke
% Input: Imagen del dado d20 visto desde arriba
% Output: Número visible en la cara superior del dado

function resultado = detectar_dado(imagen_path)
    % Cargar imagen de entrada
    img = iread(imagen_path);
    
    % Convertir a escala de grises si es necesario
    if size(img, 3) == 3
        img_gray = imono(img);
    else
        img_gray = img;
    end
    
    % Preprocesamiento de la imagen
    img_proc = preprocesar_imagen(img_gray);
    
    % Cargar templates (imágenes del dado en todas las posiciones)
    % Asumiendo que tienes templates del 1 al 20
    templates = cargar_templates();
    
    % Inicializar variables para tracking del mejor match
    mejor_score = -inf;
    mejor_numero = 0;
    mejor_angulo = 0;
    
    % Definir ángulos de rotación a probar (cada 10 grados)
    angulos = 0:10:350;
    
    % Iterar sobre cada número (1 al 20)
    for num = 1:20
        if isfield(templates, sprintf('num%d', num))
            template = templates.(sprintf('num%d', num));
            
            % Preprocesar template
            template_proc = preprocesar_imagen(template);
            
            % Probar diferentes rotaciones
            for angulo = angulos
                % Rotar template
                template_rot = irotate(template_proc, angulo, 'crop', 'black');
                
                % Realizar template matching usando correlación normalizada
                % Redimensionar si es necesario para que coincidan los tamaños
                [h_t, w_t] = size(template_rot);
                [h_i, w_i] = size(img_proc);
                
                if h_t <= h_i && w_t <= w_i
                    % Calcular similitud usando normalized cross-correlation
                    score = calcular_similitud(img_proc, template_rot);
                    
                    % Actualizar mejor match
                    if score > mejor_score
                        mejor_score = score;
                        mejor_numero = num;
                        mejor_angulo = angulo;
                    end
                end
            end
        end
    end
    
    % Mostrar resultado
    fprintf('Número detectado: %d\n', mejor_numero);
    fprintf('Confianza (score): %.4f\n', mejor_score);
    fprintf('Ángulo de rotación: %.1f grados\n', mejor_angulo);
    
    % Retornar resultado
    resultado = mejor_numero;
end

function img_proc = preprocesar_imagen(img)
    % Normalizar intensidad
    img_norm = idouble(img);
    
    % Ecualizar histograma para mejorar contraste
    img_eq = img_norm;
    
    % Aplicar filtro de mediana para reducir ruido (usando iwindow en lugar de ivar)
    img_filt = iwindow(img_eq, @median, 5);
    
    % Detectar bordes para resaltar características
    img_edges = icanny(img_filt);
    
    % Combinar imagen filtrada con bordes
    img_proc = img_filt + double(img_edges) * 0.3;
    
    % Normalizar entre 0 y 1
    img_proc = (img_proc - min(img_proc(:))) / (max(img_proc(:)) - min(img_proc(:)));
end

function templates = cargar_templates()
    % Cargar las imágenes template del dado en todas las posiciones
    % Esta función carga los templates de la imagen con todos los números
    
    templates = struct();
    
    % Leer imagen con todos los templates
    try
        % Intentar cargar el template con todas las posiciones
        img_template = iread('Dado template 1.jpg');
        if size(img_template, 3) == 3
            img_template = imono(img_template);
        end
        
        % Extraer regiones individuales para cada número
        % Basado en la imagen proporcionada (2 filas de 5 columnas)
        [h, w] = size(img_template);
        
        % Dimensiones aproximadas de cada celda
        cell_h = floor(h / 2);
        cell_w = floor(w / 5);
        
        % Números organizados en la imagen (2 filas x 5 columnas)
        % Fila 1: 4, 9, 18, 7, 1
        % Fila 2: 17, 6, 11, 3, 13
        numeros_layout = [4, 9, 18, 7, 1;
                         17, 6, 11, 3, 13];
        
        for fila = 1:2
            for col = 1:5
                % Extraer región
                y1 = (fila-1) * cell_h + 1;
                y2 = min(fila * cell_h, h);
                x1 = (col-1) * cell_w + 1;
                x2 = min(col * cell_w, w);
                
                region = img_template(y1:y2, x1:x2);
                
                % Guardar en estructura
                num = numeros_layout(fila, col);
                templates.(sprintf('num%d', num)) = region;
            end
        end
        
        % Cargar segundo template si existe
        try
            img_template2 = iread('Dado template 2.jpg');
            if size(img_template2, 3) == 3
                img_template2 = imono(img_template2);
            end
            
            [h2, w2] = size(img_template2);
            cell_h2 = floor(h2 / 2);
            cell_w2 = floor(w2 / 5);
            
            % Fila 1: 20, 19, 8, 15, 12
            % Fila 2: 10, 5, 14, 2, 11
            numeros_layout2 = [20, 19, 8, 15, 12;
                              10, 5, 14, 2, 11];
            
            for fila = 1:2
                for col = 1:5
                    y1 = (fila-1) * cell_h2 + 1;
                    y2 = min(fila * cell_h2, h2);
                    x1 = (col-1) * cell_w2 + 1;
                    x2 = min(col * cell_w2, w2);
                    
                    region = img_template2(y1:y2, x1:x2);
                    num = numeros_layout2(fila, col);
                    
                    % Solo sobrescribir si no existe o para completar
                    if ~isfield(templates, sprintf('num%d', num))
                        templates.(sprintf('num%d', num)) = region;
                    end
                end
            end
        catch
            warning('No se pudo cargar el segundo template');
        end
        
    catch ME
        error('Error al cargar templates: %s', ME.message);
    end
end

function score = calcular_similitud(imagen, template)
    % Calcular similitud usando normalized cross-correlation
    
    [h_i, w_i] = size(imagen);
    [h_t, w_t] = size(template);
    
    % Asegurar que el template no sea más grande que la imagen
    if h_t > h_i || w_t > w_i
        score = -inf;
        return;
    end
    
    % Calcular correlación normalizada
    % Método simple: correlación en el centro de la imagen
    center_y = floor((h_i - h_t) / 2) + 1;
    center_x = floor((w_i - w_t) / 2) + 1;
    
    % Extraer región de interés
    roi = imagen(center_y:center_y+h_t-1, center_x:center_x+w_t-1);
    
    % Normalizar ambas imágenes
    roi_norm = (roi - mean(roi(:))) / std(roi(:));
    template_norm = (template - mean(template(:))) / std(template(:));
    
    % Calcular correlación
    score = sum(sum(roi_norm .* template_norm)) / numel(template);
end
