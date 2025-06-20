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

void SensorScreenOverlay::removePreviousMarker()
{
    if(marker_list.size() > 0)
    {
        marker_list.pop_back();
    }
}
void SensorScreenOverlay::removeOldestMarker()
{
    if(marker_list.size() > 0)
    {
    marker_list.erase(marker_list.begin());
    }
}

void SensorScreenOverlay::clearMarkers()
{
    marker_list.clear();
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
        auto bearing_rad = glm::radians(marker.bearing + 90.0f);
        bearing_rad = bearing_rad - (2 * M_PI) * floor(bearing_rad / (2 * M_PI));
        glm::vec2 direction = - glm::vec2(cosf(bearing_rad), sinf(bearing_rad));
        
        auto screen_corner_bearing = 0.5f * atanf( (bottom_right.x - marker.position.x) / (bottom_right.y - marker.position.y));
        
        printf("%f, %f\n", bearing_rad,screen_corner_bearing);
        float distance;
        if (bearing_rad < screen_corner_bearing)
            distance = abs((marker.position.y - top_left.y) / sinf(bearing_rad));
        if (bearing_rad < M_PI - screen_corner_bearing)
            distance = abs((top_left.y - marker.position.y) / sinf(bearing_rad));
        else if (bearing_rad < M_PI + screen_corner_bearing)
            distance = abs((bottom_right.x - marker.position.x) / cosf(bearing_rad));
        else if (bearing_rad < 2 * M_PI - screen_corner_bearing)
            distance = abs((bottom_right.y - marker.position.y) / sinf(bearing_rad));
        else
            distance = abs((marker.position.y - top_left.y) / sinf(bearing_rad));

        std::vector<glm::vec2> points =
        {
            radar->worldToScreen(marker.position),
            radar->worldToScreen(marker.position + direction * distance),
        };
        renderer.drawLineBlendAdd(
            points,
            glm::u8vec4(255, 255, 255, 50)
        );
    }
}
