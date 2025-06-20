#include "SensorScreenOverlay.h"
#include "radarView.h"
#include "components/radar.h"
#include "systems/beamweapon.h"
#include <algorithm> // For std::clamp
#include <vector>    // For std::vector

SensorScreenOverlay::SensorScreenOverlay(GuiRadarView* owner, string id)
: GuiElement(owner, id), bearing(0.0f), arc(360.0f), radar(owner)
{
    setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);
    marker_list = std::vector<Marker>();
}

void SensorScreenOverlay::addMarker()
{
    auto vector = radar->screenToWorld(radar->getCenterPoint());
    printf("Marking %f, %f, bearing %f\n", vector.x, vector.y, bearing);
    marker_list.push_back(Marker{vector, bearing});
}

void SensorScreenOverlay::onDraw(sp::RenderTarget& renderer)
{
    drawArc(renderer,
        getCenterPoint(),
        bearing - arc / 2.0f - 90.0f,
        arc,
        fmin(rect.size.x, rect.size.y) / 2 - 20,
        glm::u8vec4(255, 255, 255, 50));
    
    // This assumes the overlay is perfectly on the map.
    auto top_left = radar->screenToWorld(rect.position);
    auto bottom_right = radar->screenToWorld(rect.position + rect.size);
    for (Marker marker : marker_list)
    {
        // This is the result of solving the geometrical problem of the
        // intersection between rectangle and line
        float x_min = (bottom_right.y + marker.position.y) / tan(glm::radians(marker.bearing + 90.0f)) - marker.position.x;
        float x_max = (top_left.y + marker.position.y) / tan(glm::radians(marker.bearing + 90.0f)) - marker.position.x;
        x_min = std::clamp(x_min, top_left.x, bottom_right.x);
        x_max = std::clamp(x_max, top_left.x, bottom_right.x);

        if(x_min < x_max)
        {
            auto temp = x_min;
            x_min = x_max;
            x_max = temp;
        }
        
        if (x_min != x_max)
        {
            if( marker.bearing > 180.0f)
                x_min = marker.position.x;
            else
                x_max = marker.position.x;

            std::vector<glm::vec2> points =
            {
                radar->worldToScreen(glm::vec2(x_min, (x_min + marker.position.x) * tan(glm::radians(marker.bearing + 90.0f)) - marker.position.y)),
                radar->worldToScreen(glm::vec2(x_max, (x_max + marker.position.x) * tan(glm::radians(marker.bearing + 90.0f)) - marker.position.y)),
            };
            renderer.drawLineBlendAdd(
                points,
                glm::u8vec4(255, 255, 255, 50)
            );
        }
    }
}
