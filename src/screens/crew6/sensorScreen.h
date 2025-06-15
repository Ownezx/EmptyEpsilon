#ifndef SENSOR_SCREEN_H
#define SENSOR_SCREEN_H

#include "screenComponents/targetsContainer.h"
#include "gui/gui2_overlay.h"
#include "playerInfo.h"

class GuiListbox;
class GuiRadarView;
class GuiKeyValueDisplay;
class GuiFrequencyCurve;
class GuiScrollText;
class GuiButton;
class GuiScanTargetButton;
class GuiToggleButton;
class GuiSelector;
class GuiSlider;
class GuiLabel;
class GuiImage;
class DatabaseViewComponent;
class GuiCustomShipFunctions;

class SensorScreen : public GuiOverlay
{
public:
    SensorScreen(GuiContainer* owner, CrewPosition crew_position=CrewPosition::scienceOfficer);

    virtual void onDraw(sp::RenderTarget& target) override;
    virtual void onUpdate() override;
};

#endif//SENSOR_SCREEN_H
