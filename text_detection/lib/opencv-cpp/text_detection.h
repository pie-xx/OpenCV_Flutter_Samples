#pragma once
extern "C"
void text_detection(char* inpath, char* outpath, char* modelpath, int* rtn_result);
extern "C"
void drawarea(char* inpath, char* outpath, int* rtn_result, int* color);
extern "C"
void RotImg(char* inpath, char* outpath, int angle);