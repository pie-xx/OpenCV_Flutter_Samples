#pragma once
extern "C"
void text_detection(char* inpath, char* outpath, char* modelpath);
extern "C"
void drawarea(char* inpath, char* outpath, int* rtn_result);