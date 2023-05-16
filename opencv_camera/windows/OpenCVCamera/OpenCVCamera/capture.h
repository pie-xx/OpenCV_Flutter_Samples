#pragma once
extern "C"  __declspec(dllexport)
void open();
extern "C"  __declspec(dllexport)
void capture(char* outpath, int filno);
extern "C"  __declspec(dllexport)
void close();
