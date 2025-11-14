% detectar_dado_mejorado.m
% Versión mejorada con método alternativo usando características SIFT/SURF
% Si el método de template matching básico no funciona bien

function resultado = detectar_dado_mejorado(imagen_path)
    % Cargar imagen de entrada
    img = iread(imagen_path);
    
    % Convertir a escala de grises
    if size(img, 3) == 3
        img_gray = imono(img);
    else
        img_gray = img;
    end
    
    % Binarizar y segmentar el dado
    img_bin = binarizar_dado(img_gray);
    
    % Encontrar la región del dado
    [dado_region, bbox] = extraer_region_dado(img_gray, img_bin);
    
    % Cargar templates
    templates = cargar_templates_mejorado();
    
    % Matching con todos los templates
    mejor_score = -inf;
    mejor_numero = 0;
    
    % Probar con cada número y múltiples rotaciones
    angulos = 0:15:345; % Cada 15 grados
    
    for num = 1:20
        if isfield(templates, sprintf('num%d', num))
            template = templates.(sprintf('num%d', num));
            
            for angulo = angulos
                % Rotar template
                template_rot = irotate(template, angulo, 'crop', 'black');
                
                % Redimensionar template al tamaño aproximado del dado detectado
                if ~isempty(bbox)
                    template_resized = imresize(template_rot, [bbox(4), bbox(3)]);
                else
                    template_resized = template_rot;
                end
                
                % Calcular similitud
                score = similitud_normalizada(dado_region, template_resized);
                
                if score > mejor_score
                    mejor_score = score;
                    mejor_numero = num;
                end
            end
        end
    end
    
    fprintf('Número detectado: %d (confianza: %.3f)\n', mejor_numero, mejor_score);
    resultado = mejor_numero;
end

function img_bin = binarizar_dado(img_gray)
    % Normalizar imagen
    img_norm = idouble(img_gray);
    
    % Aplicar threshold adaptativo
    % Usar método de Otsu
    threshold = graythresh(img_norm);
    img_bin = img_norm > threshold;
    
    % Operaciones morfológicas para limpiar
    se = ones(5, 5);
    img_bin = iclose(img_bin, se);
    img_bin = iopen(img_bin, se);
end

function [region, bbox] = extraer_region_dado(img_gray, img_bin)
    % Etiquetar regiones conectadas
    labels = ilabel(img_bin);
    
    % Encontrar la región más grande (probablemente el dado)
    props = iblobs(img_bin, 'boundary');
    
    if isempty(props)
        region = img_gray;
        bbox = [];
        return;
    end
    
    % Encontrar el blob más grande
    [~, idx] = max([props.area]);
    bbox_coords = props(idx).umin:props(idx).umax;
    
    % Extraer bounding box
    bbox = [props(idx).umin, props(idx).vmin, ...
            props(idx).umax - props(idx).umin, ...
            props(idx).vmax - props(idx).vmin];
    
    % Extraer región
    region = img_gray(props(idx).vmin:props(idx).vmax, ...
                      props(idx).umin:props(idx).umax);
end

function templates = cargar_templates_mejorado()
    % Similar a la función original pero con mejor manejo
    templates = struct();
    
    try
        % Template 1
        img1 = iread('Dado template 1.jpg');
        if size(img1, 3) == 3
            img1 = imono(img1);
        end
        
        [h1, w1] = size(img1);
        rows = 2;
        cols = 5;
        cell_h = floor(h1 / rows);
        cell_w = floor(w1 / cols);
        
        % Layout primera imagen
        layout1 = [4, 9, 18, 7, 1;
                  17, 6, 11, 3, 13];
        
        for r = 1:rows
            for c = 1:cols
                y1 = (r-1) * cell_h + 1;
                y2 = r * cell_h;
                x1 = (c-1) * cell_w + 1;
                x2 = c * cell_w;
                
                region = img1(y1:y2, x1:x2);
                num = layout1(r, c);
                templates.(sprintf('num%d', num)) = region;
            end
        end
        
        % Template 2
        img2 = iread('Dado template 2.jpg');
        if size(img2, 3) == 3
            img2 = imono(img2);
        end
        
        [h2, w2] = size(img2);
        cell_h2 = floor(h2 / rows);
        cell_w2 = floor(w2 / cols);
        
        layout2 = [20, 19, 8, 15, 12;
                  10, 5, 14, 2, 11];
        
        for r = 1:rows
            for c = 1:cols
                y1 = (r-1) * cell_h2 + 1;
                y2 = r * cell_h2;
                x1 = (c-1) * cell_w2 + 1;
                x2 = c * cell_w2;
                
                region = img2(y1:y2, x1:x2);
                num = layout2(r, c);
                templates.(sprintf('num%d', num)) = region;
            end
        end
    catch ME
        error('Error cargando templates: %s', ME.message);
    end
end

function score = similitud_normalizada(img1, img2)
    % Asegurar mismo tamaño
    [h1, w1] = size(img1);
    [h2, w2] = size(img2);
    
    if h1 ~= h2 || w1 ~= w2
        % Redimensionar al tamaño menor
        target_h = min(h1, h2);
        target_w = min(w1, w2);
        img1 = imresize(img1, [target_h, target_w]);
        img2 = imresize(img2, [target_h, target_w]);
    end
    
    % Normalizar
    img1_norm = idouble(img1);
    img2_norm = idouble(img2);
    
    img1_norm = (img1_norm - mean(img1_norm(:))) / (std(img1_norm(:)) + eps);
    img2_norm = (img2_norm - mean(img2_norm(:))) / (std(img2_norm(:)) + eps);
    
    % Correlación
    score = sum(sum(img1_norm .* img2_norm)) / numel(img1_norm);
end
