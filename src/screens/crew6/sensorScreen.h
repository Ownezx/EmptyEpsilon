#ifndef SENSOR_SCREEN_H
#define SENSOR_SCREEN_H

#include "screenComponents/targetsContainer.h"
#include "gui/gui2_overlay.h"
#include "playerInfo.h"


class GuiRotationDial;


class SensorScreen : public GuiOverlay
{
protected:
    void setSensorBearing(float bearing);

public:
    SensorScreen(GuiContainer* owner, CrewPosition crew_position=CrewPosition::scienceOfficer);

    GuiRotationDial* sensor_bearing;

    virtual void onDraw(sp::RenderTarget& target) override;
    virtual void onUpdate() override;
};

#endif//SENSOR_SCREEN_H
