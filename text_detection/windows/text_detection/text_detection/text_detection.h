#pragma once
extern "C" __declspec(dllexport)
void text_detection(char* inpath, char* outpath, char* modelpath, int* rtn_result);
extern "C" __declspec(dllexport)
void drawarea(char* inpath, char* outpath, int* rtn_result);
extern "C" __declspec(dllexport)
void RotImg(char* inpath, char* outpath, int angle);