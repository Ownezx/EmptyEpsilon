#ifndef RAW_SCANNER_UTIL_H
#define RAW_SCANNER_UTIL_H

#include <vector>
#include "glm/vec2.hpp"
#include <cmath>

struct RawScannerDataPoint
{
    float electrical;
    float biological;
    float gravity;
};

std::vector<RawScannerDataPoint> CalculateRawScannerData(glm::vec2 position, float start_angle, float arc_size, uint point_count, float range, float noise_floor);

std::vector<RawScannerDataPoint> Calculate360RawScannerData(glm::vec2 position, uint point_count, float range, float noise_floor);

#endif // RAW_SCANNER_UTIL_H
