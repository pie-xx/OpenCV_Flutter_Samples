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
#include <opencv2/dnn/dnn.hpp>
using namespace cv;
using namespace cv::dnn;

#include "text_detection.h"

Mat wimread(char* inpath);
void wimwrite(char* outpath, Mat img);

void text_detection(char* inpath, char* outpath, char* modelpath, int* rtn_result)
{
	Mat img = wimread(inpath);
	if (img.size == 0) {
		return;
	}

	int maxsize = rtn_result[0];
	std::cout << "maxsize " << maxsize << std::endl;

	// Load model weights
	//TextDetectionModel_DB model("D:/Text/OpenCV_Flutter_Samples/text_detection/assets/DB_TD500_resnet50.onnx");
	TextDetectionModel_DB model(modelpath);

	// Post-processing parameters
	float binThresh = 0.3;
	float polyThresh = 0.5;
	uint maxCandidates = 1024
		;
	double unclipRatio = 2.0;
	model.setBinaryThreshold(binThresh)
		.setPolygonThreshold(polyThresh)
		.setMaxCandidates(maxCandidates)
		.setUnclipRatio(unclipRatio)
		;
	// Normalization parameters
	double scale = 1.0 / 255.0;
	Scalar mean = Scalar(122.67891434, 116.66876762, 104.00698793);
	// The input shape
	Size inputSize = Size(736, 736);
	model.setInputParams(scale, inputSize, mean);

	std::vector<std::vector<cv::Point>> results;
	std::vector<float> confidences;
	try {
		model.detect(img, results, confidences);
	}
	catch (...) {
		rtn_result[0] = 0;
		return;
	}

	// Loop over the results
	for (int i = 0; i < results.size(); ++i) {
		//cv::polylines(img, results[i], true, cv::Scalar(0, 255, 0), 2);
		//cv::putText(img, std::to_string(i), results[i][0], cv::FONT_HERSHEY_SIMPLEX, 1.0, Scalar(0, 255, 0));
		if (i < maxsize) {
			std::cout << "i " << i << std::endl;
			for (int n = 0; n < 4; ++n) {
				rtn_result[i * 8 + n * 2 + 1] = results[i][n].x;
				rtn_result[i * 8 + n * 2 + 2] = results[i][n].y;
			}
			rtn_result[0] = i+1;
		}
	}

	wimwrite(outpath, img);
}

void drawarea(char* inpath, char* outpath, int* rtn_result, int* color) {
	Mat img = wimread(inpath);
	if (img.size == 0) {
		return;
	}
	int maxsize = rtn_result[0];

	cv::Scalar drawColor = cv::Scalar(color[0],color[1],color[2]);

	for (int i = 0; i < maxsize; ++i) {
		std::vector<cv::Point> results(4);
		for (int n = 0; n < 4; ++n) {
			results[n].x = rtn_result[i * 8 + n * 2 + 1];
			results[n].y = rtn_result[i * 8 + n * 2 + 2];
		}
		cv::polylines(img, results, true, drawColor, 2);
		cv::putText(img, std::to_string(i), results[0], cv::FONT_HERSHEY_SIMPLEX, 1.0, drawColor);
	}

	wimwrite(outpath, img);
}

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
