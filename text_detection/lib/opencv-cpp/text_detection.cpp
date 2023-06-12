#include <opencv2/opencv.hpp>
#include <opencv2/core/core.hpp>
#include <opencv2/dnn/dnn.hpp>
using namespace cv;
using namespace cv::dnn;

#include "text_detection.h"

void text_detection(char* inpath, char* outpath, char* modelpath)
{
	Mat img = imread(inpath);
	if (img.size == 0) {
		return;
	}

	// Load model weights
	TextDetectionModel_DB model(modelpath);

	// Post-processing parameters
	float binThresh = 0.3;
	float polyThresh = 0.5;
	uint maxCandidates = 200;
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
	model.detect(img, results, confidences);

	// Loop over the results
	for (size_t i = 0; i < results.size(); ++i) {
		cv::polylines(img, results[i], true, cv::Scalar(0, 255, 0), 2);
		cv::putText(img, std::to_string(i), results[i][0], cv::FONT_HERSHEY_SIMPLEX, 1.0, Scalar(0, 0, 255));
	}

	imwrite(outpath, img);
}


void drawarea(char* inpath, char* outpath, int* rtn_result) {
	Mat img = imread(inpath);
	if (img.size == 0) {
		return;
	}
	int maxsize = rtn_result[0];

	for (int i = 0; i < maxsize; ++i) {
		std::vector<cv::Point> results(4);
		for (int n = 0; n < 4; ++n) {
			results[n].x = rtn_result[i * 8 + n * 2 + 1];
			results[n].y = rtn_result[i * 8 + n * 2 + 2];
		}
		cv::polylines(img, results, true, cv::Scalar(255, 0, 0), 2);
		cv::putText(img, std::to_string(i), results[0], cv::FONT_HERSHEY_SIMPLEX, 1.0, Scalar(255, 0, 0));
	}

	imwrite(outpath, img);
}
