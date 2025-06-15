#ifndef RAW_SCANNER_UTIL_H
#define RAW_SCANNER_UTIL_H

#include <vector>
#include "glm/vec2.hpp"

struct RawScannerDataPoint
{
    float electrical;
    float biological;
    float gravity;
};

std::vector<RawScannerDataPoint> CalculateRawScannerData(glm::vec2 position, std::vector<float> angles, float range);

#endif // RAW_SCANNER_UTIL_H
