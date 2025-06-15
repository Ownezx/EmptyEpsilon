#include "sensorScreen.h"
#include "i18n.h"

#include "components/radar.h"

#include "screenComponents/radarView.h"

#include "gui/gui2_rotationdial.h"
#include "gui/gui2_button.h"
#include "gui/gui2_togglebutton.h"


SensorScreen::SensorScreen(GuiContainer *owner, CrewPosition crew_position)
    : GuiOverlay(owner, "SCIENCE_SCREEN", colorConfig.background)
{

    auto container = new GuiElement(this, "");
    container->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax)->setAttribute("layout", "horizontal");

    auto left_container = new GuiElement(container, "");
    left_container->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax)->setAttribute("layout", "vertical");

    auto right_container = new GuiElement(container, "");
    right_container->setSize(250, GuiElement::GuiSizeMax)->setAttribute("layout", "vertical");

    auto top_left_container = new GuiElement(left_container, "");
    top_left_container->setSize(GuiElement::GuiSizeMax, 50)->setAttribute("layout", "horizontal");

    auto bottom_left_container = new GuiElement(left_container, "");
    bottom_left_container->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);

    // Fill right bar
    sensor_bearing = new GuiRotationDial(right_container, "BEARING_AIM", -90, 360 - 90, 0, [](float value){});
    sensor_bearing->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);
    

    auto lock_button = new GuiButton(right_container, "SENSOR_LOCK_POSITION", tr("SensorButton", "Lock Position"), []() {});
    lock_button->setSize(GuiElement::GuiSizeMax, 50);

    auto mark_bearing_button = new GuiButton(right_container, "SENSOR_MARK_BEARING", tr("SensorButton", "Mark Bearing"), []() {});
    mark_bearing_button->setSize(GuiElement::GuiSizeMax, 50);

    auto remove_oldest_mark_button = new GuiButton(right_container, "SENSOR_REMOVE_OLDEST_MARK", tr("SensorButton", "Remove Oldest Mark"), []() {});
    remove_oldest_mark_button->setSize(GuiElement::GuiSizeMax, 50);

    auto reset_marks_button = new GuiButton(right_container, "SENSOR_RESET_MARKS", tr("SensorButton", "Reset Marks"), []() {});
    reset_marks_button->setSize(GuiElement::GuiSizeMax, 50);

    auto link_probe_button = new GuiButton(right_container, "SENSOR_LINK_PROBE", tr("SensorButton", "Link Probe"), []() {});
    link_probe_button->setSize(GuiElement::GuiSizeMax, 50);

    // Top buttons
    auto toggle_map_button = new GuiButton(top_left_container, "SENSOR_TOGGLE_MAP", tr("SensorButton", "Toggle Map"), []() {});
    toggle_map_button->setSize(GuiElement::GuiSizeMax, 50);

    auto biological_button = new GuiButton(top_left_container, "SENSOR_BIOLOGICAL", tr("SensorButton", "Biological"), []() {});
    biological_button->setSize(GuiElement::GuiSizeMax, 50);

    auto electrical_button = new GuiButton(top_left_container, "SENSOR_ELECTRICAL", tr("SensorButton", "Electrical"), []() {});
    electrical_button->setSize(GuiElement::GuiSizeMax, 50);

    auto gravity_button = new GuiButton(top_left_container, "SENSOR_GRAVITY", tr("SensorButton", "Gravity"), []() {});
    gravity_button->setSize(GuiElement::GuiSizeMax, 50);


    targets.setAllowWaypointSelection();
    radar = new GuiRadarView(bottom_left_container, "SENSOR_RADAR", 50000.0f, &targets);
    radar->longRange()->enableWaypoints()->enableCallsigns()->setStyle(GuiRadarView::Rectangular)->setFogOfWarStyle(GuiRadarView::FriendlysShortRangeFogOfWar);
    radar->setAutoCentering(false);
    radar->setPosition(0, 0, sp::Alignment::TopLeft)->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);
    radar->setCallbacks(
        [this](sp::io::Pointer::Button button, glm::vec2 position) { //down
        },
        [this](glm::vec2 position) { //drag
        },
        [this](glm::vec2 position) { //up
        }
    );
}

void SensorScreen::onDraw(sp::RenderTarget& renderer)
{

}

void SensorScreen::onUpdate()
{
   
}

void SensorScreen::setSensorBearing(float bearing)
{

}