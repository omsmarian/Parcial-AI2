% test_detector.m
% Script de prueba para el detector de dados d20

clear all;
close all;
clc;

fprintf('=== Sistema de Detección de Dado d20 ===\n\n');

% Probar con las imágenes de ejemplo
fprintf('Procesando Foto 1.jpg...\n');
resultado1 = detectar_dado('Foto 1.jpg');
fprintf('Resultado final: %d\n\n', resultado1);

fprintf('Procesando Foto 2.jpg...\n');
resultado2 = detectar_dado('Foto 2.jpg');
fprintf('Resultado final: %d\n\n', resultado2);

fprintf('=== Pruebas completadas ===\n');
