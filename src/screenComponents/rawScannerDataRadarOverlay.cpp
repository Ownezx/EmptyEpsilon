#include "rawScannerDataRadarOverlay.h"
#include "radarView.h"
#include "playerInfo.h"
#include "random.h"
#include "components/collision.h"
#include "components/radar.h"
#include "ecs/query.h"
#include "utils/rawScannerUtil.h"


RawScannerDataRadarOverlay::RawScannerDataRadarOverlay(GuiRadarView* owner, string id)
: GuiElement(owner, id), radar(owner)
{
    setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);
}

void RawScannerDataRadarOverlay::onDraw(sp::RenderTarget& renderer)
{
    if (!my_spaceship)
        return;

    auto view_position = radar->getViewPosition();
    float view_rotation = radar->getViewRotation();

    // Cap the number of signature points, which determines the raw data's
    // resolution.
    const int point_count = 512;
    float radius = std::min(rect.size.x, rect.size.y) / 2.0f;

    std::vector<float> angles(point_count);
    for (int i = 0; i < point_count; i++)
    {
        angles[i] = 360.0f * float(i) / float(point_count);
    }

    std::vector<RawScannerDataPoint> scanner_data = CalculateRawScannerData(view_position, angles, radar->getDistance() * 2);

    // Create a vertex array containing each data point.
    std::vector<glm::vec2> a_r;
    std::vector<glm::vec2> a_g;
    std::vector<glm::vec2> a_b;

    // For each data point ...
    for(int n = 0; n < point_count; n++)
    {
        // ... divide them by 5 ...
        float r = scanner_data[n].electrical;
        float g = scanner_data[n].biological;
        float b = scanner_data[n].gravity;
        
        // ... and add vectors for each point.
        a_r.push_back(
            glm::vec2(rect.position.x + rect.size.x / 2.0f, rect.position.y + rect.size.y / 2.0f) +
            vec2FromAngle(float(n) / float(point_count) * 360.0f - view_rotation) * (radius * (0.95f - r / 100)));

        a_g.push_back(
            glm::vec2(rect.position.x + rect.size.x / 2.0f, rect.position.y + rect.size.y / 2.0f) +
            vec2FromAngle(float(n) / float(point_count) * 360.0f - view_rotation) * (radius * (0.92f - g / 100)));

        a_b.push_back(
            glm::vec2(rect.position.x + rect.size.x / 2.0f, rect.position.y + rect.size.y / 2.0f) +
            vec2FromAngle(float(n) / float(point_count) * 360.0f - view_rotation) * (radius * (0.89f - b / 100)));
    }

    // Set a zero value at the "end" of the data point array.
    a_r.push_back(a_r.front());
    a_g.push_back(a_g.front());
    a_b.push_back(a_b.front());

    // Draw each band as a line.
    renderer.drawLineBlendAdd(a_r, glm::u8vec4(255, 45, 84, 255)); // red
    renderer.drawLineBlendAdd(a_g, glm::u8vec4(65, 255, 81, 255)); // green
    renderer.drawLineBlendAdd(a_b, glm::u8vec4(70, 120, 255, 255)); // blue
}
