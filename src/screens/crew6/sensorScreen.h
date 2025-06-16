#ifndef SENSOR_SCREEN_H
#define SENSOR_SCREEN_H

#include "screenComponents/targetsContainer.h"
#include "gui/gui2_overlay.h"
#include "playerInfo.h"


class GuiRotationDial;
class GuiRadarView;
class GuiGraph;


class SensorScreen : public GuiOverlay
{
protected:
    float current_bearing;
    float current_arc_size;
    float min_arc_size;
    bool locked_to_position;
    void setSensorBearing(float bearing);

    int point_count;

public:
    SensorScreen(GuiContainer* owner, CrewPosition crew_position=CrewPosition::scienceOfficer);

    GuiRotationDial* sensor_bearing;
    GuiRadarView* radar;
    GuiGraph* electrical_graph;
    GuiGraph* biological_graph;
    GuiGraph* gravity_graph;
    TargetsContainer targets;


    virtual void onDraw(sp::RenderTarget& target) override;
    virtual void onUpdate() override;
};

#endif//SENSOR_SCREEN_H
