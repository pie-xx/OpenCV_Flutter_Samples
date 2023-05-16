#include "pch.h"

#include <iostream>
#include <string>
#include <fstream>
#include <filesystem>
#include <io.h>
#include <stdio.h>

#include <codecvt>
#include <cstdlib>
#include <iomanip>
#include <iostream>
#include <locale>

#include <system_error>
#include <vector>
#include <Windows.h>


#ifdef _DEBUG
#pragma comment(lib, "opencv_world460d.lib")
#else
#pragma comment(lib, "opencv_world460.lib")
#endif
#include <opencv2/opencv.hpp>
#include <opencv2/core/core.hpp>
using namespace cv;
#include "rot.h"

Mat wimread(char* inpath);
void wimwrite(char* outpath, Mat img);

void RotImg(char* inpath, char* outpath, int angle)
{
	Mat img = wimread(inpath);
	if (img.size == 0) {
		return;
	}
	rotate(img, img, angle);
	wimwrite(outpath, img);
}

Mat wimread(char* inpath) {
	setlocale(LC_ALL, "japanese");
	int size = ::MultiByteToWideChar(CP_UTF8, 0, inpath, -1, (wchar_t*)NULL, 0);
	wchar_t* winpath = (wchar_t*)new wchar_t[size];
	::MultiByteToWideChar(CP_UTF8, 0, inpath, -1, winpath, size);
	FILE* fp;
	_wfopen_s(&fp, winpath, L"rb");
	delete[] winpath;
	if (fp == NULL) {
		std::cout << "cant open " << inpath << std::endl;
		return Mat();
	}
	long long int fsize = _filelengthi64(_fileno(fp));
	unsigned char* buff = new unsigned char[fsize];
	fread(buff, fsize, 1, fp);
	fclose(fp);
	// Mat‚Ö•ÏŠ·
	std::vector<uchar> jpeg(buff, buff + fsize);
	cv::Mat img = cv::imdecode(jpeg, 1);

	delete[] buff;
	return img;
}

void wimwrite(char* outpath, Mat img) {
	setlocale(LC_ALL, "japanese");
	std::vector<uchar> buff2; //buffer for coding
	std::vector<int> param = std::vector<int>(2);
	param[0] = 1;
	param[1] = 95; //default(95) 0-100
	imencode(".jpg", img, buff2, param);
	int size = ::MultiByteToWideChar(CP_UTF8, 0, outpath, -1, (wchar_t*)NULL, 0);
	wchar_t* woutpath = (wchar_t*)new wchar_t[size];
	::MultiByteToWideChar(CP_UTF8, 0, outpath, -1, woutpath, size);
	FILE* fp2;
	_wfopen_s(&fp2, woutpath, L"wb");
	delete[] woutpath;
	if (fp2 == NULL) {
		std::cout << "output cant open" << std::endl;
		return;
	}
	fwrite(buff2.data(), buff2.size(), 1, fp2);
	fclose(fp2);
}
