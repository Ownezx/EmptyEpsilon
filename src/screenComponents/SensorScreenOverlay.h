#ifndef RAW_SCANNER_DATA_RADAR_OVERLAY_H
#define RAW_SCANNER_DATA_RADAR_OVERLAY_H

#include "gui/gui2_element.h"

class GuiRadarView;

// Class to show the scan bearings and markers
class SensorScreenOverlay : public GuiElement
{
public:
    SensorScreenOverlay(GuiRadarView* owner, string id);

    void addMarker();
    void removeLastMarker();
    void removePreviousMarker();
    void clearMarkers();

    void setBearing(float value) { bearing = value; }
    float getBearing() const { return bearing; }

    void setArc(float value) { arc = value; }
    float getArc() const { return arc; }

    virtual void onDraw(sp::RenderTarget& target) override;

protected:
    struct Marker {
        glm::vec2 position;
        float bearing;
    };
    std::vector<Marker> marker_list;
    
    float bearing;
    float arc;
    GuiRadarView* radar;
};

#endif//RAW_SCANNER_DATA_RADAR_OVERLAY_H
